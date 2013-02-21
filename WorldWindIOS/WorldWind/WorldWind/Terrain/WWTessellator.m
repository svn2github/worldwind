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
#import "WorldWind/Util/WWLevelSet.h"
#import "WorldWind/Util/WWLevel.h"
#import "WorldWind/Terrain/WWGlobe.h"
#import "WorldWind/Render/WWGpuProgram.h"
#import "WorldWind/Geometry/WWMatrix.h"
#import "WorldWind/Navigate/WWNavigatorState.h"
#import "WorldWind/Util/WWMemoryCache.h"
#import "WorldWind/Geometry/WWBoundingBox.h"
#import "WorldWind/Geometry/WWLocation.h"

#define LEVEL_ZERO_DELTA 45
#define NUM_LEVELS 10
#define TILE_SIZE 5

@implementation WWTessellator

- (WWTessellator*) initWithGlobe:(WWGlobe*)globe
{
    if (globe == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"globe is nil")
    }

    self = [super init];

    if (self != nil)
    {
        _globe = globe;

        self->tileCache = [[WWMemoryCache alloc] initWithCapacity:1e6 lowWater:800e3];
        self->detailHintOrigin = 0.8;

        WWLocation* levelZeroDelta = [[WWLocation alloc] initWithDegreesLatitude:LEVEL_ZERO_DELTA
                                                                       longitude:LEVEL_ZERO_DELTA];
        self->levels = [[WWLevelSet alloc] initWithSector:[[WWSector alloc] initWithFullSphere]
                                           levelZeroDelta:levelZeroDelta
                                                numLevels:NUM_LEVELS
                                                tileWidth:TILE_SIZE
                                               tileHeight:TILE_SIZE];

        self->currentTiles = [[WWTerrainTileList alloc] initWithTessellator:self];
        self->topLevelTiles = [[NSMutableArray alloc] init];
    }

    return self;
}

- (void) createTopLevelTiles
{
    [self->topLevelTiles removeAllObjects];

    [WWTile createTilesForLevel:[self->levels firstLevel]
                    tileFactory:self
                       tilesOut:self->topLevelTiles];
}

- (WWTerrainTileList*) tessellate:(WWDrawContext*)dc
{
    if (dc == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Draw context is nil")
    }

    [self->currentTiles removeAllTiles];
    self->currentCoverage = nil;

    if ([self->topLevelTiles count] == 0)
    {
        [self createTopLevelTiles];
    }

    for (WWTerrainTile* tile in self->topLevelTiles)
    {
        [tile updateReferencePoints:[dc globe] verticalExaggeration:[dc verticalExaggeration]];
        [tile updateExtent:[dc globe] verticalExaggeration:[dc verticalExaggeration]];

        if ([self isTileVisible:dc tile:tile])
        {
            [self addTileOrDescendants:dc tile:tile];
        }
    }

    [self->currentTiles setSector:self->currentCoverage];

    return self->currentTiles;
}

- (void) addTileOrDescendants:(WWDrawContext*)dc tile:(WWTerrainTile*)tile
{
    if ([self tileMeetsRenderCriteria:dc tile:tile])
    {
        [self addTile:dc tile:tile];
        return;
    }

    WWLevel* nextLevel = [self->levels level:[[tile level] levelNumber] + 1];
    NSArray* subTiles = [tile subdivide:nextLevel cache:self->tileCache tileFactory:self];

    for (WWTerrainTile* child in subTiles)
    {
        [child updateReferencePoints:[dc globe] verticalExaggeration:[dc verticalExaggeration]];
        [child updateExtent:[dc globe] verticalExaggeration:[dc verticalExaggeration]];

        if ([[self->levels sector] intersects:[child sector]] && [self isTileVisible:dc tile:child])
        {
            [self addTileOrDescendants:dc tile:child];
        }
    }
}

- (void) addTile:(WWDrawContext*)dc tile:(WWTerrainTile*)tile
{
    if (tile.terrainGeometry == nil)
    {
        [self regenerateTileGeometry:dc tile:tile];
    }

    [self->currentTiles addTile:tile];

    if (self->currentCoverage == nil)
    {
        self->currentCoverage = [[WWSector alloc] initWithSector:[tile sector]];
    }
    else
    {
        [self->currentCoverage union:[tile sector]];
    }
}

- (BOOL) tileMeetsRenderCriteria:(WWDrawContext*)dc tile:(WWTerrainTile*)tile
{
    // TODO: Consider also using the best-resolution test in the desktop and android versions.
    return [[tile level] isLastLevel] || ![tile mustSubdivide:dc detailFactor:(detailHintOrigin + _detailHint)];
}

- (BOOL) isTileVisible:(WWDrawContext*)dc tile:(WWTerrainTile*)tile
{
    return [[tile extent] intersects:[[dc navigatorState] frustumInModelCoordinates]];
}

- (WWTile*) createTile:(WWSector*)sector level:(WWLevel*)level row:(int)row column:(int)column
{
    return [[WWTerrainTile alloc] initWithSector:sector level:level row:row column:column tessellator:self];
}

- (void) regenerateTileGeometry:(WWDrawContext*)dc tile:(WWTerrainTile*)tile
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
    WWVec4* refCenter = [self referenceCenterForTile:dc tile:tile];
    terrainGeometry.referenceCenter = refCenter;
    double rcx = refCenter.x;
    double rcy = refCenter.y;
    double rcz = refCenter.z;
    terrainGeometry.transformationMatrix = [[WWMatrix alloc] initWithTranslation:rcx y:rcy z:rcz];

    [self buildTileVertices:dc tile:tile];
    if (_sharedGeometry == nil)
        [self buildSharedGeometry:tile];
}

- (WWVec4*) referenceCenterForTile:(WWDrawContext*)dc tile:(WWTerrainTile*)tile
{
    WWSector* sector = tile.sector;

    double lat = 0.5 * (sector.minLatitude + tile.sector.maxLatitude);
    double lon = 0.5 * (sector.minLongitude + tile.sector.maxLongitude);

    double elevation = [dc.globe elevationForLatitude:lat longitude:lon];
    elevation *= dc.verticalExaggeration;

    WWVec4* refCenter = [[WWVec4 alloc] initWithZeroVector];
    [dc.globe computePointFromPosition:lat longitude:lon altitude:elevation outputPoint:refCenter];

    return refCenter;
}

- (void) buildTileVertices:(WWDrawContext*)dc tile:(WWTerrainTile*)tile
{
    // The number of vertices in each dimension is 1 more than the number of cells.
    int numLatVertices = tile.tileWidth + 1;
    int numLonVertices = tile.tileHeight + 1;

    // Retrieve the elevations for all vertices in the tile. The returned elevations will already have vertical
    // exaggeration applied.
    double elevations[numLatVertices * numLonVertices];
    [dc.globe elevationsForSector:tile.sector
                           numLat:numLatVertices
                           numLon:numLonVertices
                 targetResolution:tile.texelSize
             verticalExaggeration:dc.verticalExaggeration
                           result:elevations];

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

    double deltaLat = (maxLat - minLat) / tile.tileHeight;

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

    _sharedGeometry.texCoords = [self buildTexCoords:tile.tileWidth
                                          tileHeight:tile.tileHeight
                                        numCoordsOut:&count];
    _sharedGeometry.numTexCoords = count;

    // Build the surface-tile indices.
    _sharedGeometry.indices = [self buildIndices:tile.tileWidth
                                      tileHeight:tile.tileHeight
                                   numIndicesOut:&count];
    _sharedGeometry.numIndices = count;

    // Build the wireframe indices.
    _sharedGeometry.wireframeIndices = [self buildWireframeIndices:tile.tileWidth
                                                        tileHeight:tile.tileHeight
                                                     numIndicesOut:&count];
    _sharedGeometry.numWireframeIndices = count;

    // Build the outline indices.
    _sharedGeometry.outlineIndices = [self buildOutlineIndices:tile.tileWidth
                                                    tileHeight:tile.tileHeight
                                                 numIndicesOut:&count];
    _sharedGeometry.numOutlineIndices = count;
}

- (float*) buildTexCoords:(int)tileWidth tileHeight:(int)tileHeight numCoordsOut:(int*)numCoordsOut
{
    // The number of vertices in each dimension is 3 more than the number of cells. Two of those are for the skirt.
    int numLatVertices = tileHeight + 3;
    int numLonVertices = tileWidth + 3;

    // Allocate an array to hold the texture coordinates.
    *numCoordsOut = numLatVertices * numLonVertices;
    float* texCoords = (float*) malloc((size_t) *numCoordsOut * 2 * sizeof(float));

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

    // Allocate an array to hold the indices used to draw a tile of the specified width and height as a triangle strip.
    // Shorts are the largest primitive that OpenGL ES allows for an index buffer. The largest tileWidth and tileHeight
    // that can be indexed by a short is 256x256 (excluding the extra rows and columns to convert between cell count and
    // vertex count, and the extra rows and columns for the tile skirt).
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

    // Allocate an array to hold the computed indices.
    int numIndices = 2 * tileWidth * (tileHeight + 1) + 2 * tileHeight * (tileWidth + 1);
    short* indices = (short*) malloc((size_t) (numIndices * sizeof(short)));

    // Add two columns of vertices to the row stride to account for the west and east skirt vertices.
    int rowStride = numLonVertices + 2;
    // Skip the skirt row and column to start an the first interior vertex.
    int offset = rowStride + 1;

    // Add a line between each row to define the horizontal cell outlines. Starts and ends at the vertices that
    // appear on the surface, thereby ignoring the tile skirt.
    int k = 0;
    for (int j = 0; j < numLatVertices; j++)
    {
        for (int i = 0; i < tileWidth; i++)
        {
            int vertex = offset + i + j * rowStride;
            indices[k++] = (short) vertex;
            indices[k++] = (short) (vertex + 1);
        }
    }

    // Add a line between each column to define the vertical cell outlines. Starts and ends at the vertices that
    // appear on the surface, thereby ignoring the tile skirt.
    for (int i = 0; i < numLonVertices; i++)
    {
        for (int j = 0; j < tileHeight; j++)
        {
            int vertex = offset + i + j * rowStride;
            indices[k++] = (short) vertex;
            indices[k++] = (short) (vertex + rowStride);
        }
    }

    *numIndicesOut = numIndices; // let the caller know how many indices were computed

    return indices;
}

- (short*) buildOutlineIndices:(int)tileWidth tileHeight:(int)tileHeight numIndicesOut:(int*)numIndicesOut
{
    // The outline representation traces the tile's outer edge on the surface.

    // The number of vertices in each dimension is 1 more than the number of cells.
    int numLatVertices = tileHeight + 1;
    int numLonVertices = tileWidth + 1;

    // Allocate an array to hold the computed indices. The outline indices ignore the extra rows and columns for the
    // tile skirt.
    int numIndices = 2 * (numLatVertices - 1) + 2 * numLonVertices - 1;
    short* indices = (short*) malloc((size_t) (numIndices * sizeof(short)));

    // Add two columns of vertices to the row stride to account for the two additional vertices that provide an
    // outer row/column for the tile skirt.
    int rowStride = numLonVertices + 2;

    // Bottom row. Offset by rowStride + 1 to start at the lower left corner, ignoring the tile skirt.
    int offset = rowStride + 1;
    int k = 0;
    for (int i = 0; i < numLonVertices; i++)
    {
        indices[k++] = (short) (offset + i);
    }

    // Rightmost column. Offset by rowStride - 2 to start at the lower right corner, ignoring the tile skirt. Skips
    // the bottom vertex, which is already included in the bottom row.
    offset = 2 * rowStride - 2;
    for (int j = 1; j < numLatVertices; j++)
    {
        indices[k++] = (short) (offset + j * rowStride);
    }

    // Top row. Offset by tileHeight* rowStride + 1 to start at the top left corner, ignoring the tile skirt. Skips
    // the rightmost vertex, which is already included in the rightmost column.
    offset = numLatVertices * rowStride + 1;
    for (int i = numLonVertices - 2; i >= 0; i--)
    {
        indices[k++] = (short) (offset + i);
    }

    // Leftmost column. Offset by rowStride + 1 to start at the lower left corner, ignoring the tile skirt. Skips
    // the topmost vertex, which is already included in the top row.
    offset = rowStride + 1;
    for (int j = numLatVertices - 2; j >= 0; j--)
    {
        indices[k++] = (short) (offset + j * rowStride);
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

    WWMatrix* mvp = [[WWMatrix alloc] initWithMultiply:[[dc navigatorState] modelviewProjection]
                                               matrixB:[[tile terrainGeometry] transformationMatrix]];
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

- (void) renderOutline:(WWDrawContext*)dc tile:(WWTerrainTile*)tile
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
    glDrawElements(GL_LINE_LOOP, _sharedGeometry.numOutlineIndices, GL_UNSIGNED_SHORT, _sharedGeometry.outlineIndices);
}

@end