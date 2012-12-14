/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import "WorldWind/Terrain/WWTessellator.h"
#import "WorldWind/Terrain/WWTerrainTile.h"
#import "WorldWind/Terrain/WWTerrainTileList.h"
#import "WorldWind/Geometry/WWSector.h"
#import "WorldWind/WWLog.h"
#import "WorldWind/Terrain/WWTerrainSharedGeometry.h"
#import "WorldWind/Terrain/WWTerrainGeometry.h"
#import "WorldWind/Geometry/WWVec4.h"
#import "WorldWind/Render/WWDrawContext.h"
#import "WorldWind/Terrain/WWGlobe.h"
#import "WorldWind/Render/WWGpuProgram.h"
#import "WorldWind/Geometry/WWMatrix.h"

#define NUM_LAT_SUBDIVISIONS 3
#define NUM_LON_SUBDIVISIONS 6

@implementation WWTessellator

- (WWTessellator*) initWithGlobe:(WWGlobe*)globe
{
    if (globe == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"globe is nil")
    }

    self = [super init];

    _globe = globe;

    [self createTopLevelTiles];

    return self;
}

- (void) createTopLevelTiles
{
    self->topLevelTiles = [[NSMutableArray alloc] init];

    double deltaLat = 180.0 / NUM_LAT_SUBDIVISIONS;
    double deltaLon = 360.0 / NUM_LON_SUBDIVISIONS;

    double lastLat = -90;

    for (int row = 0; row < NUM_LAT_SUBDIVISIONS; row++)
    {
        double lat = lastLat + deltaLat;
        if (lat + 1 > 90)
            lat = 90;

        double lastLon = -180;

        for (int col = 0; col < NUM_LON_SUBDIVISIONS; col++)
        {
            double lon = lastLon + deltaLon;
            if (lon + 1 > 180)
                lon = 180;

            WWSector* tileSector = [[WWSector alloc] initWithDegreesMinLatitude:lastLat maxLatitude:lat minLongitude:lastLon maxLongitude:lon];
            WWTerrainTile* tile = [[WWTerrainTile alloc] initWithSector:tileSector level:0 row:row column:col tessellator:self];
            [self->topLevelTiles addObject:tile];

            lastLon = lon;
        }

        lastLat = lat;
    }
}

- (WWTerrainTileList*) tessellate:(WWDrawContext*)dc
{
    if (dc == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Draw context is nil")
    }

    WWTerrainTileList* tiles = [[WWTerrainTileList alloc] initWithTessellator:self];

    NSUInteger count = [self->topLevelTiles count];
    for (NSUInteger i = 0; i < count; i++)
    {
        WWTerrainTile* tile = [self->topLevelTiles objectAtIndex:i];
        if ([self mustRegenerateGeometry:dc tile:tile])
        {
            [self regenerateGeometry:dc tile:tile];
        }
        [tiles addTile:tile];
    }

    tiles.sector = [[WWSector alloc] initWithFullSphere];

    return tiles;
}

- (BOOL) mustRegenerateGeometry:(WWDrawContext*)dc tile:(WWTerrainTile*)tile
{
    return tile.terrainGeometry == nil;
}

- (void) regenerateGeometry:(WWDrawContext*)dc tile:(WWTerrainTile*)tile
{
    if (tile == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Terrain tile is nil")
    }

    WWTerrainGeometry* terrainGeometry = [[WWTerrainGeometry alloc] init];
    tile.terrainGeometry = terrainGeometry;

    // Cartesian tile coordinates are relative to a local origin, called the reference center. Compute the reference
    // center here and establish a translation transform that is used later to move the tile coordinates into place
    // relative to the globe.
    WWVec4* refCenter = [self computeReferenceCenter:dc tile:tile];
    terrainGeometry.referenceCenter = refCenter;
    double rcx = refCenter.x;
    double rcy = refCenter.y;
    double rcz = refCenter.z;
    terrainGeometry.transformationMatrix = [[WWMatrix alloc] initWithTranslation:rcx y:rcy z:rcz];

    [self buildTileVertices:dc tile:tile];
    if (_sharedGeometry == nil)
        [self buildSharedGeometry:tile];
}

- (WWVec4*) computeReferenceCenter:(WWDrawContext*)dc tile:(WWTerrainTile*)tile
{
    WWSector* sector = tile.sector;

    double lat = 0.5 * (sector.minLatitude + tile.sector.maxLatitude);
    double lon = 0.5 * (sector.minLongitude + tile.sector.maxLongitude);

    double elevation = [dc.globe getElevation:lat longitude:lon];
    elevation *= dc.verticalExaggeration;

    WWVec4* refCenter = [[WWVec4 alloc] initWithZeroVector];
    [dc.globe computePointFromPosition:lat longitude:lon altitude:elevation outputPoint:refCenter];

    return refCenter;
}

- (void) buildTileVertices:(WWDrawContext*)dc tile:(WWTerrainTile*)tile
{
    // The number of vertices in each dimension is 1 more than the number of cells.
    int numLatVertices = tile.numLonCells + 1;
    int numLonVertices = tile.numLatCells + 1;

    // Retrieve the elevations for all vertices in the tile. The returned elevations will already have vertical
    // exaggeration applied.
    double elevations[numLatVertices * numLonVertices];
    [dc.globe getElevations:tile.sector
                     numLat:numLatVertices
                     numLon:numLonVertices
           targetResolution:tile.resolution
       verticalExaggeration:dc.verticalExaggeration
                outputArray:elevations];

    // The min elevation is used to determine the necessary depth of the tile skirts.
    double minElevation = dc.globe.minElevation * dc.verticalExaggeration;

    // Allocate space for the Cartesian vertices.
    tile.terrainGeometry.numPoints = (numLatVertices + 2) * (numLonVertices + 2);
    int numCoords = tile.terrainGeometry.numPoints * 3;
    tile.terrainGeometry.points = malloc((size_t) (numCoords * sizeof(float)));
    float* points = tile.terrainGeometry.points; // running pointer to the portion of the array that will hold the computed vertices

    WWSector* sector = tile.sector;
    double minLat = sector.minLatitude;
    double maxLat = sector.maxLatitude;
    double minLon = sector.minLongitude;
    double maxLon = sector.maxLongitude;

    double deltaLat = (maxLat - minLat) / tile.numLatCells;

    // We're going to build the vertices one row of longitude at a time. The rowSector variable changes to reflect
    // that in the calls below.
    WWSector* rowSector = [[WWSector alloc] initWithDegreesMinLatitude:minLat
                                                           maxLatitude:minLat
                                                          minLongitude:minLon
                                                          maxLongitude:maxLon];
    // Create the vertices row at minimum latitude. The elevation of the skirt vertices is constant -- the globe's
    // minimum elevation. The method called here computes the skirt vertices at the ends of the row.
    [self buildTileRowVertices:dc.globe
                     rowSector:rowSector
                numRowVertices:numLonVertices
                    elevations:nil constantElevation:&minElevation // specifies constant elevation for the row
                  minElevation:minElevation
                     refCenter:tile.terrainGeometry.referenceCenter
                        points:points];
    points += 3 * (numLonVertices + 2); // the interior vertex count plus the skirt vertices at either end

    // Create the interior rows -- those other than the top and bottom skirts.
    double lat = minLat;
    int elevOffset = 0; // the running index of the elevations for each row
    for (int j = 0; j < numLatVertices; j++)
    {
        // When at the min and max of the tile's sector, force use of the specified latitude for those rows rather
        // than using the accumulated latitude, which may be slightly off. This keeps the tile's edges accurate.
        if (j == 0)
            lat = minLat;
        else if (j == numLatVertices - 1)
            lat = maxLat;
        else
            lat += deltaLat;

        // Since we're doing a row at a time, the sector's min and max latitude are the same.
        rowSector.minLatitude = lat;
        rowSector.maxLatitude = lat;

        // Build the row of vertices.
        [self buildTileRowVertices:dc.globe
                         rowSector:rowSector
                    numRowVertices:numLonVertices
                        elevations:&elevations[elevOffset]
                 constantElevation:nil // we're using elevations per vertex here, unlike at the skirt rows
                      minElevation:minElevation
                         refCenter:tile.terrainGeometry.referenceCenter
                            points:points];

        // Update the pointers to the elevations array and the vertices array
        elevOffset += numLonVertices;
        points += 3 * (numLonVertices + 2);
    }

    // Build the skirt row at the tile's maximum latitude.
    rowSector.minLatitude = maxLat;
    rowSector.maxLatitude = maxLat;
    [self buildTileRowVertices:dc.globe
                     rowSector:rowSector
                numRowVertices:numLonVertices
                    elevations:nil constantElevation:&minElevation
                  minElevation:minElevation
                     refCenter:tile.terrainGeometry.referenceCenter
                        points:points];
}

- (void) buildTileRowVertices:(WWGlobe*)globe
                    rowSector:(WWSector*)rowSector
               numRowVertices:(int)numRowVertices
                   elevations:(double [])elevations
            constantElevation:(double*)constantElevation
                 minElevation:(double)minElevation
                    refCenter:(WWVec4*)refCenter
                       points:(float [])points
{

    // Add a redundant point at the row's minimum longitude. This point is used to define the tile's western skirt. It
    // has the same location as the row's first location but is assigned the minimum elevation instead of the
    // location's actual elevation.
    [globe computePointFromPosition:rowSector.minLatitude
                          longitude:rowSector.minLongitude
                           altitude:minElevation
                             offset:refCenter
                        outputArray:points];

    // Add points for each location in the row.
    [globe computePointsFromPositions:rowSector
                               numLat:1
                               numLon:numRowVertices
                      metersElevation:elevations
                    constantElevation:constantElevation
                               offset:refCenter
                          outputArray:&points[3]];

    // Add a redundant point at row's maximum longitude. This points is used to define the tile's eastern skirt. It
    // has the same location as the row's last location but is assigned the minimum elevation instead of the location's
    // actual elevation.
    [globe computePointFromPosition:rowSector.minLatitude
                          longitude:rowSector.maxLongitude
                           altitude:minElevation
                             offset:refCenter
                        outputArray:&points[(numRowVertices + 1) * 3]];
}

- (void) buildSharedGeometry:(WWTerrainTile*)tile
{
    if (_sharedGeometry != nil)
        return;

    _sharedGeometry = [[WWTerrainSharedGeometry alloc] init];

    int count; // holds the returned number of elements returned from the methods below

    _sharedGeometry.texCoords = [self buildTexCoords:tile.numLonCells
                                          tileHeight:tile.numLatCells
                                        numCoordsOut:&count];
    _sharedGeometry.numTexCoords = count;

    // Build the surface-tile indices.
    _sharedGeometry.indices = [self buildIndices:tile.numLonCells
                                      tileHeight:tile.numLatCells
                                   numIndicesOut:&count];
    _sharedGeometry.numIndices = count;

    // Build the wireframe indices.
    _sharedGeometry.wireframeIndices = [self buildWireframeIndices:tile.numLonCells
                                                        tileHeight:tile.numLatCells
                                                     numIndicesOut:&count];
    _sharedGeometry.numWireframeIndices = count;
}

- (float*) buildTexCoords:(int)tileWidth tileHeight:(int)tileHeight numCoordsOut:(int*)numCoordsOut
{
    // The number of vertices in each dimension is 3 more than the number of cells. Two of those are for the skirt.
    int numLatVertices = tileHeight + 3;
    int numLonVertices = tileWidth + 3;

    // Allocate an array to hold the texture coordinates.
    *numCoordsOut = numLatVertices * numLonVertices;
    float* texCoords = (float*) malloc((size_t) *numCoordsOut);

    double minS = 0;
    double maxS = 1;
    double minT = 0;
    double maxT = 1;
    double deltaS = (maxS - minS) / tileWidth;
    double deltaT = (maxT - minT) / tileHeight;

    double s = minS; // Horizontal texture coordinate; varies along tile width or longitude.
    double t = minT; // Vertical texture coordinate; varies along tile height or latitude.

    int k = 0;
    for (int j = 0; j < numLatVertices; j++)
    {
        if (j <= 1) // First two columns repeat the min T-coordinate to provide a column for the skirt.
            t = minT;
        else if (j >= numLatVertices - 2) // Last two columns repeat the max T-coordinate to provide a column for the skirt.
            t = maxT;
        else
            t += deltaT; // Non-boundary latitudes are separated by the cell latitude delta.

        for (int i = 0; i < numLonVertices; i++)
        {
            if (i <= 1) // First two rows repeat the min S-coordinate to provide a row for the skirt.
                s = minS;
            else if (i >= numLonVertices - 2) // Last two rows repeat the max S-coordinate to provide a row for the skirt.
                s = maxS;
            else
                s += deltaS; // Non-boundary longitudes are separated by the cell longitude delta.

            texCoords[k++] = (float) s;
            texCoords[k++] = (float) t;
        }
    }

    return texCoords;
}

- (short*) buildIndices:(int)tileWidth tileHeight:(int)tileHeight numIndicesOut:(int*)numIndicesOut
{
    // The number of vertices in each dimension is 3 more than the number of cells. Two of those are for the skirt.
    int numLatVertices = tileHeight + 3;
    int numLonVertices = tileWidth + 3;

    // Allocate a native short array to hold the indices used to draw a tile of the specified width and height as
    // a triangle strip. Shorts are the largest primitive that OpenGL ES allows for an index buffer. The largest
    // tileWidth and tileHeight that can be indexed by a short is 256x256 (excluding the extra rows and columns to
    // convert between cell count and vertex count, and the extra rows and columns for the tile skirt).
    int numIndices = 2 * (numLatVertices - 1) * numLonVertices + 2 * (numLatVertices - 2);
    short* indices = (short*) malloc((size_t) (numIndices * sizeof(short)));

    int k = 0;
    for (int j = 0; j < numLatVertices - 1; j++)
    {
        if (j != 0)
        {
            // Attach the previous and next triangle strips by repeating the last and first vertices of the previous
            // and current strips, respectively. This creates a degenerate triangle between the two strips which is
            // not rasterized because it has zero area. We don't perform this step when j==0 because there is no
            // previous triangle strip to connect with.
            indices[k++] = (short) ((numLonVertices - 1) + (j - 1) * numLonVertices); // last vertex of previous strip
            indices[k++] = (short) (j * numLonVertices + numLonVertices); // first vertex of current strip
        }

        for (int i = 0; i < numLonVertices; i++)
        {
            // Create a triangle strip joining each adjacent row of vertices, starting in the lower left corner and
            // proceeding upward. The first vertex starts with the upper row of vertices and moves down to create a
            // counter-clockwise winding order.
            int vertex = i + j * numLonVertices;
            indices[k++] = (short) (vertex + numLonVertices);
            indices[k++] = (short) vertex;
        }
    }

    *numIndicesOut = numIndices;

    return indices;
}

- (short*) buildWireframeIndices:(int)tileWidth tileHeight:(int)tileHeight numIndicesOut:(int*)numIndicesOut
{
    // The wireframe representation ignores the tile skirt and draws only the vertices that appear on the surface.

    // The number of vertices in each dimension is 1 more than the number of cells.
    int numLatVertices = tileHeight + 1;
    int numLonVertices = tileWidth + 1;

    int numIndices = 2 * numLatVertices * (numLonVertices - 1) + 2 * (numLatVertices - 1) * numLonVertices;
    // Allocate an array to hold the computed indices.
    short* indices = (short*) malloc((size_t) (numIndices * sizeof(short)));

    // Add two columns of vertices to the row stride to account for the west and east skirt vertices.
    int rowStride = numLonVertices + 2;
    // Skip the skirt row and column to start an the first interior vertex.
    int offset = rowStride + 1;

    // Add a line between each column to define the vertical cell outlines. Starts and ends at the vertices that
    // appear on the surface, thereby ignoring the tile skirt.
    int k = 0;
    for (int j = 0; j < numLatVertices; j++)
    {
        for (int i = 0; i < numLonVertices; i++)
        {
            int vertex = offset + i + j * rowStride;
            indices[k] = (short) vertex;
            indices[k + 1] = (short) (vertex + 1);
            k += 2;
        }
    }

    // Add a line between each row to define the horizontal cell outlines. Starts and ends at the vertices that appear
    // on the surface, thereby ignoring the tile skirt.
    for (int i = 0; i < numLonVertices; i++)
    {
        for (int j = 0; j < numLatVertices; j++)
        {
            int vertex = offset + i + j * rowStride;
            indices[k] = (short) vertex;
            indices[k + 1] = (short) (vertex + rowStride);
            k += 2;
        }
    }

    *numIndicesOut = numIndices; // let the caller know how many indices were computed

    return indices;
}

- (void) beginRendering:(WWDrawContext*)dc
{
    if (dc == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Draw context is nil")
    }

    WWGpuProgram* program = dc.currentProgram;
    if (program == nil)
    {
        WWLog(@"Current program is nil");
        return;
    }

    // Enable the program's vertex attribute, if one exists.
    int location = [program getAttributeLocation:@"vertexPoint"];
    if (location >= 0)
    {
        glEnableVertexAttribArray((GLuint) location);
    }

    // Enable the program's texture coordinate attribute.
    location = [program getAttributeLocation:@"vertexTexCoord"];
    if (location >= 0)
    {
        glEnableVertexAttribArray((GLuint) location);
    }
}

- (void) endRendering:(WWDrawContext*)dc
{
    if (dc == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Draw context is nil")
    }

    glBindBuffer(GL_ARRAY_BUFFER, 0);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0);

    WWGpuProgram* program = dc.currentProgram;
    if (program == nil)
    {
        return;
    }

    int location = [program getAttributeLocation:@"vertexPoint"];
    if (location >= 0)
    {
        glDisableVertexAttribArray((GLuint) location);
    }

    location = [program getAttributeLocation:@"vertexTexCoord"];
    if (location >= 0)
    {
        glDisableVertexAttribArray((GLuint) location);
    }
}

- (void) beginRendering:(WWDrawContext*)dc tile:(WWTerrainTile*)tile
{
    if (dc == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Draw context is nil")
    }

    if (tile == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Terrain tile is nil")
    }

    WWGpuProgram* program = dc.currentProgram;
    if (program == nil)
    {
        return;
    }

    WWMatrix* mvp = [[WWMatrix alloc] initWithMultiply:dc.modelviewProjection matrixB:tile.terrainGeometry.transformationMatrix];
    [dc.currentProgram loadUniformMatrix:@"mvpMatrix" matrix:mvp];
}

- (void) endRendering:(WWDrawContext*)dc tile:(WWTerrainTile*)tile
{
    if (dc == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Draw context is nil")
    }

    if (tile == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Terrain tile is nil")
    }

}

- (void) render:(WWDrawContext*)dc tile:(WWTerrainTile*)tile
{
    if (dc == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Draw context is nil")
    }

    if (tile == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Terrain tile is nil")
    }

    int location = [dc.currentProgram getAttributeLocation:@"vertexPoint"];
    WWTerrainGeometry* terrainGeometry = tile.terrainGeometry;
    glVertexAttribPointer((GLuint) location, 3, GL_FLOAT, GL_FALSE, 0, terrainGeometry.points);

    location = [dc.currentProgram getAttributeLocation:@"vertexTexCoord"];
    if (location >= 0) // attribute might not be used in shader, so check to be sure it has a location
    {
        glVertexAttribPointer((GLuint) location, 2, GL_FLOAT, GL_FALSE, 0, _sharedGeometry.texCoords);
    }

    glDrawElements(GL_TRIANGLE_STRIP, _sharedGeometry.numIndices, GL_UNSIGNED_SHORT, _sharedGeometry.indices);
}

- (void) renderWireFrame:(WWDrawContext*)dc tile:(WWTerrainTile*)tile
{
    if (dc == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Draw context is nil")
    }

    if (tile == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Terrain tile is nil")
    }

    // Must turn off texture coordinates, which were turned on in beginRendering.
    int location = [dc.currentProgram getAttributeLocation:@"vertexTexCoord"];
    if (location >= 0)
    {
        glDisableVertexAttribArray((GLuint) location);
    }

    location = [dc.currentProgram getAttributeLocation:@"vertexPoint"];
    WWTerrainGeometry* terrainGeometry = tile.terrainGeometry;
    glVertexAttribPointer((GLuint) location, 3, GL_FLOAT, GL_FALSE, 0, terrainGeometry.points);
    glDrawElements(GL_LINES, _sharedGeometry.numWireframeIndices, GL_UNSIGNED_SHORT, _sharedGeometry.wireframeIndices);
}
@end
