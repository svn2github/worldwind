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
#import "WorldWind/Util/WWGpuResourceCache.h"
#import "WorldWind/WorldWindConstants.h"
#import "WorldWind/Geometry/WWLine.h"
#import "WorldWind/Geometry/WWPosition.h"
#import "WorldWind/Pick/WWPickedObject.h"
#import "WorldWind/Util/WWMath.h"

@implementation WWTessellator

//--------------------------------------------------------------------------------------------------------------------//
//-- Initializing Tessellators --//
//--------------------------------------------------------------------------------------------------------------------//

- (WWTessellator*) initWithGlobe:(WWGlobe*)globe
{
    if (globe == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Globe is nil")
    }

    self = [super init];

    if (self != nil)
    {
        _globe = globe;

        self->levels = [[WWLevelSet alloc] initWithSector:[[WWSector alloc] initWithFullSphere]
                                           levelZeroDelta:[[WWLocation alloc] initWithDegreesLatitude:45 longitude:45]
                                                numLevels:15 // Approximately 9.6 meter resolution with 45x45 degree and 32x32 density tiles.
                                                tileWidth:32
                                               tileHeight:32];

        self->topLevelTiles = [[NSMutableArray alloc] init];
        self->currentTiles = [[WWTerrainTileList alloc] initWithTessellator:self];
        self->tileCache = [[WWMemoryCache alloc] initWithCapacity:5000000 lowWater:4000000]; // Holds 316 32x32 tiles.
        self->detailHintOrigin = 1.1;
    }

    return self;
}

- (void) dealloc
{
    if (self->tileElevations)
    {
        free(self->tileElevations);
    }
}

//--------------------------------------------------------------------------------------------------------------------//
//-- Tessellating a Globe --//
//--------------------------------------------------------------------------------------------------------------------//

- (WWTerrainTileList*) tessellate:(WWDrawContext*)dc
{
    if (dc == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Draw context is nil")
    }

    NSDate* lastElevationsChange = [[dc globe] elevationTimestamp];
    if ([currentTiles count] > 0
            && elevationTimestamp != nil && [elevationTimestamp isEqualToDate:lastElevationsChange]
            && lastMVP != nil && [[[dc navigatorState] modelviewProjection] isEqual:lastMVP])
    {
        return currentTiles;
    }
    lastMVP = [[dc navigatorState] modelviewProjection];

    [self->currentTiles removeAllTiles];
    self->currentCoverage = nil;
    self->elevationTimestamp = lastElevationsChange; // Store the elevation timestamp to prevent it from changing during tessellation.

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

//--------------------------------------------------------------------------------------------------------------------//
//-- Creating Tessellator Tiles --//
//--------------------------------------------------------------------------------------------------------------------//

- (WWTile*) createTile:(WWSector*)sector level:(WWLevel*)level row:(int)row column:(int)column
{
    return [[WWTerrainTile alloc] initWithSector:sector level:level row:row column:column tessellator:self];
}

//--------------------------------------------------------------------------------------------------------------------//
//-- Methods of Interest Only to Subclasses --//
//--------------------------------------------------------------------------------------------------------------------//

- (void) createTopLevelTiles
{
    [self->topLevelTiles removeAllObjects];
    [WWTile createTilesForLevel:[self->levels firstLevel] tileFactory:self tilesOut:self->topLevelTiles];
}

- (void) addTileOrDescendants:(WWDrawContext*)dc tile:(WWTerrainTile*)tile
{
    if ([self tileMeetsRenderCriteria:dc tile:tile])
    {
        [self addTile:dc tile:tile];
        return;
    }

    WWLevel* nextLevel = [[tile level] nextLevel];
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
    if ([self mustRegenerateTileGeometry:dc tile:tile])
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

- (BOOL) isTileVisible:(WWDrawContext*)dc tile:(WWTerrainTile*)tile
{
    return [[tile extent] intersects:[[dc navigatorState] frustumInModelCoordinates]];
}

- (BOOL) tileMeetsRenderCriteria:(WWDrawContext*)dc tile:(WWTerrainTile*)tile
{
    // TODO: Consider also using the best-resolution test in the desktop and android versions.
    return [[tile level] isLastLevel] || ![tile mustSubdivide:dc detailFactor:(detailHintOrigin + _detailHint)];
}

- (BOOL) mustRegenerateTileGeometry:(WWDrawContext*)dc tile:(WWTerrainTile*)tile
{
    if ([tile terrainGeometry] == nil)
    {
        return YES;
    }
    else
    {
        NSDate* timestamp = [tile timestamp];
        return timestamp == nil || [timestamp compare:self->elevationTimestamp] == NSOrderedAscending;
    }
}

- (void) regenerateTileGeometry:(WWDrawContext*)dc tile:(WWTerrainTile*)tile
{
    WWTerrainGeometry* terrainGeometry = tile.terrainGeometry;
    if (terrainGeometry == nil)
    {
        terrainGeometry = [[WWTerrainGeometry alloc] init];
        [tile setTerrainGeometry:terrainGeometry];
    }

    // Cartesian tile coordinates are relative to a local origin, called the reference center. Compute the reference
    // center here and establish a translation transform that is used later to move the tile coordinates into place
    // relative to the globe.
    WWVec4* refCenter = terrainGeometry.referenceCenter;
    [self referenceCenterForTile:dc tile:tile outputPoint:refCenter];
    [terrainGeometry.transformationMatrix setToTranslation:refCenter.x y:refCenter.y z:refCenter.z];

    [self buildTileVertices:dc tile:tile];
    [self buildSharedGeometry:tile];
    [[dc gpuResourceCache] removeResourceForKey:[tile cacheKey]]; // remove out of date VBOs from the GPU resource cache

    // Set the geometry timestamp to the globe's elevation timestamp on which the geometry is based. This ensures that
    // the geometry timestamp can be reliably compared to the elevation timestamp in subsequent frames, and avoids
    // creating redundant NSDate objects.
    [tile setTimestamp:self->elevationTimestamp];
}

- (void) referenceCenterForTile:(WWDrawContext*)dc tile:(WWTerrainTile*)tile outputPoint:(WWVec4*)result
{
    WWSector* sector = tile.sector;

    double lat = 0.5 * (sector.minLatitude + tile.sector.maxLatitude);
    double lon = 0.5 * (sector.minLongitude + tile.sector.maxLongitude);

    double elevation = [dc.globe elevationForLatitude:lat longitude:lon];
    elevation *= dc.verticalExaggeration;

    [dc.globe computePointFromPosition:lat longitude:lon altitude:elevation outputPoint:result];
}

- (void) buildTileVertices:(WWDrawContext*)dc tile:(WWTerrainTile*)tile
{
    // The number of vertices in each dimension is 1 more than the number of cells.
    int numLatVertices = tile.tileWidth + 1;
    int numLonVertices = tile.tileHeight + 1;

    if (!self->tileElevations)
    {
        self->tileElevations = malloc((size_t) numLatVertices * numLonVertices * sizeof(double));
    }

    // Retrieve the elevations for all vertices in the tile. The returned elevations will already have vertical
    // exaggeration applied.
    memset(self->tileElevations, 0, (size_t) (numLatVertices * numLonVertices * sizeof(double)));
    [dc.globe elevationsForSector:tile.sector
                           numLat:numLatVertices
                           numLon:numLonVertices
                 targetResolution:tile.texelSize
             verticalExaggeration:dc.verticalExaggeration
                           result:self->tileElevations];

    // The min elevation is used to determine the necessary depth of the tile skirts.
    double minElevation = dc.globe.minElevation * dc.verticalExaggeration;

    // Allocate space for the Cartesian vertices.
    if (!tile.terrainGeometry.points)
    {
        int numPoints = (numLatVertices + 2) * (numLonVertices + 2);
        tile.terrainGeometry.numPoints = numPoints;
        tile.terrainGeometry.points = malloc((size_t) (numPoints * 3 * sizeof(float)));
    }

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
                        elevations:&self->tileElevations[elevOffset]
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

    [self cacheSharedGeometryVBOs:dc];

    // Enable the program's vertex attribute, if one exists.
    vertexPointLocation = [program getAttributeLocation:@"vertexPoint"];
    glEnableVertexAttribArray((GLuint) vertexPointLocation);

    WWGpuResourceCache* gpuResourceCache = [dc gpuResourceCache];

    if (![dc pickingMode])
    {
        // Enable the program's texture coordinate attribute.
        vertexTexCoordLocation = [program getAttributeLocation:@"vertexTexCoord"];
        NSNumber* texCoordVboId = (NSNumber*) [gpuResourceCache getResourceForKey:[_sharedGeometry texCoordVboCacheKey]];
        glEnableVertexAttribArray((GLuint) vertexTexCoordLocation);
        glBindBuffer(GL_ARRAY_BUFFER, (GLuint) [texCoordVboId intValue]);
        glVertexAttribPointer((GLuint) vertexTexCoordLocation, 2, GL_FLOAT, false, 0, 0);
    }

    NSNumber* indicesVboId = (NSNumber*) [gpuResourceCache getResourceForKey:[_sharedGeometry indicesVboCacheKey]];
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, (GLuint) [indicesVboId intValue]);
}

- (void) endRendering:(WWDrawContext*)dc
{
    if (dc == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Draw context is nil")
    }

    glBindBuffer(GL_ARRAY_BUFFER, 0);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0);

    glDisableVertexAttribArray((GLuint) vertexPointLocation);

    if (![dc pickingMode])
    {
        glDisableVertexAttribArray((GLuint) vertexTexCoordLocation);
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
    [program loadUniformMatrix:@"mvpMatrix" matrix:mvp];

    GLuint vboId;
    WWGpuResourceCache* gpuResourceCache = [dc gpuResourceCache];
    NSNumber* vbo = (NSNumber*) [gpuResourceCache getResourceForKey:[tile cacheKey]];
    if (vbo == nil)
    {
        WWTerrainGeometry* terrainGeometry = tile.terrainGeometry;
        GLsizei size = [terrainGeometry numPoints] * 3 * sizeof(float);
        glGenBuffers(1, &vboId);
        glBindBuffer(GL_ARRAY_BUFFER, vboId);
        glBufferData(GL_ARRAY_BUFFER, size, [terrainGeometry points], GL_STATIC_DRAW);
        [gpuResourceCache putResource:[[NSNumber alloc] initWithInt:vboId]
                         resourceType:WW_GPU_VBO
                                 size:size
                               forKey:[tile cacheKey]];
    }
    else
    {
        vboId = (GLuint) [vbo intValue];
        glBindBuffer(GL_ARRAY_BUFFER, vboId);
    }

    glVertexAttribPointer((GLuint) vertexPointLocation, 3, GL_FLOAT, GL_FALSE, 0, 0);
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

    glDrawElements(GL_TRIANGLE_STRIP, _sharedGeometry.numIndices, GL_UNSIGNED_SHORT, 0);
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
    glDisableVertexAttribArray((GLuint) vertexTexCoordLocation);

    // Must turn off indices buffer, which was turned on in beginRendering.
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0);

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
    glDisableVertexAttribArray((GLuint) vertexTexCoordLocation);

    // Must turn off indices buffer, which was turned on in beginRendering.
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0);

    glDrawElements(GL_LINE_LOOP, _sharedGeometry.numOutlineIndices, GL_UNSIGNED_SHORT, _sharedGeometry.outlineIndices);
}

- (void) cacheSharedGeometryVBOs:(WWDrawContext*)dc
{
    WWGpuResourceCache* gpuResourceCache = [dc gpuResourceCache];

    NSNumber* texCoordVbo = (NSNumber*) [gpuResourceCache getResourceForKey:[_sharedGeometry texCoordVboCacheKey]];
    if (texCoordVbo == nil)
    {
        GLuint texCoordVboId;
        glGenBuffers(1, &texCoordVboId);
        glBindBuffer(GL_ARRAY_BUFFER, texCoordVboId);
        glBufferData(GL_ARRAY_BUFFER, [_sharedGeometry numTexCoords] * 2 * sizeof(float), [_sharedGeometry texCoords],
                GL_STATIC_DRAW);
        [gpuResourceCache putResource:[[NSNumber alloc] initWithInt:texCoordVboId]
                         resourceType:WW_GPU_VBO
                                 size:[_sharedGeometry numTexCoords] * 2 * sizeof(float)
                               forKey:[_sharedGeometry texCoordVboCacheKey]];
        glBindBuffer(GL_ARRAY_BUFFER, 0);
    }

    NSNumber* indicesVbo = (NSNumber*) [gpuResourceCache getResourceForKey:[_sharedGeometry indicesVboCacheKey]];
    if (indicesVbo == nil)
    {
        GLuint indicesVboId;
        glGenBuffers(1, &indicesVboId);
        glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, indicesVboId);
        glBufferData(GL_ELEMENT_ARRAY_BUFFER, [_sharedGeometry numIndices] * sizeof(short), [_sharedGeometry indices],
                GL_STATIC_DRAW);
        [gpuResourceCache putResource:[[NSNumber alloc] initWithInt:indicesVboId]
                         resourceType:WW_GPU_VBO
                                 size:[_sharedGeometry numIndices] * sizeof(short)
                               forKey:[_sharedGeometry indicesVboCacheKey]];
        glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0);
    }
}

- (void) pick:(WWDrawContext*)dc
{
    WWTerrainTileList* tiles = [dc surfaceGeometry];
    CGPoint pickPoint = [dc pickPoint];
    if (tiles == nil || [tiles count] < 1)
    {
        return;
    }

    WWGpuProgram* program = [dc defaultProgram];
    if (program == nil)
    {
        return;
    }

    unsigned int colorInt = dc.uniquePickColor;
    unsigned int minColorCode = colorInt >> 8; // shift alpha out of the way

    // Draw each terrain tile in a unique color. The fact that the colors are sequential is used below to determine
    // which tile is under the pick point.

    [tiles beginRendering:dc];
    @try
    {
        for (NSUInteger i = 0; i < [tiles count]; i++)
        {
            // Get a unique pick color for each tile, even those outside the pick frustum because the colors are used
            // to compute an index into the tile list.
            if (i > 0)
            {
                colorInt = dc.uniquePickColor;
            }

            // TODO: Cull tiles against the pick frustum.

            WWTerrainTile* tile = [tiles objectAtIndex:i];
            [tile beginRendering:dc];

            @try
            {
                [program loadUniformColorInt:@"color" color:colorInt];
                [tile render:dc]; // render the tile
            }
            @finally
            {
                [tile endRendering:dc];
            }
        }
    }
    @finally
    {
        [tiles endRendering:dc];
    }

    // Assign the max color code to the color used to draw the last tile.
    unsigned int maxColorCode = colorInt >> 8;

    // Retrieve the frame buffer color under the pick point.
    unsigned int colorCode = [dc readPickColor:pickPoint] >> 8;

    // Use the color code to determine which tile, if any, is under the pick point.

    if (colorCode < minColorCode || colorCode > maxColorCode)
    {
        return;
    }

    WWTerrainTile* pickedTile = [tiles objectAtIndex:colorCode - minColorCode];

    WWVec4* pickedPoint = [self computePickedPoint:dc tile:pickedTile pickPoint:pickPoint];
    if (pickedPoint == nil)
    {
        return;
    }

    WWPosition* position = [[WWPosition alloc] initWithZeroPosition];
    [[dc globe] computePositionFromPoint:[pickedPoint x] y:[pickedPoint y] z:[pickedPoint z]
                          outputPosition:position];

    double altitude = [[dc globe] elevationForLatitude:[position latitude] longitude:[position longitude]];
    [position setAltitude:altitude * [dc verticalExaggeration]];

    WWPickedObject* po = [[WWPickedObject alloc] initWithColorCode:colorCode
                                                        userObject:position
                                                         pickPoint:pickPoint
                                                          position:position
                                                         isTerrain:YES];
    [dc addPickedObject:po];
}

- (WWVec4*) computePickedPoint:(WWDrawContext*)dc tile:(WWTerrainTile*)tile pickPoint:(CGPoint)pickPoint
{
    WWLine* ray = [[dc navigatorState] rayFromScreenPoint:pickPoint];
    if (ray == nil)
    {
        return nil;
    }

    // Transform the ray to model coordinates so that we don't have to add the reference center to all the triangle
    // vertices. The pick is therefore done in model coordinates rather than world coordinates. The result, if any, is
    // transformed to world coordinates below.
    WWVec4* refCenter = [[tile terrainGeometry] referenceCenter];
    [[ray origin] subtract3:refCenter];

    // Check all triangles for intersection with the pick ray.

    BOOL found;
    WWVec4* pickedPoint = [[WWVec4 alloc] initWithZeroVector];
    int nIndices = [_sharedGeometry numIndices];
    short* indices = [_sharedGeometry indices];
    float* points = [[tile terrainGeometry] points];
    for (NSUInteger i = 0; i < nIndices - 2; i++)
    {
        // Form the 3 triangle vertices. The vertex order doesn't matter to the intersection algorithm.
        float* p0 = &points[3 * indices[i]];
        float* p1 = &points[3 * indices[i + 1]];
        float* p2 = &points[3 * indices[i + 2]];

        found = [WWMath computeTriangleIntersection:ray
                                              vax:p0[0]
                                              vay:p0[1]
                                              vaz:p0[2]
                                              vbx:p1[0]
                                              vby:p1[1]
                                              vbz:p1[2]
                                              vcx:p2[0]
                                              vcy:p2[1]
                                              vcz:p2[2]
                                           result:pickedPoint];
        if (found)
        {
            [pickedPoint add3:refCenter]; // transform the picked point from model coordinates to world coordinates
            return pickedPoint;
        }
    }

    return nil;
}

// The below method is used to compute the intersection when the containing triangle is known, as is the case when the
// triangle is determined from color coding. It's left here in anticipation of implementing the color coding algorithm.
//- (BOOL) computeTriangleIntersection2:(WWLine*)line
//                                  vax:(double)vax
//                                  vay:(double)vay
//                                  vaz:(double)vaz
//                                  vbx:(double)vbx
//                                  vby:(double)vby
//                                  vbz:(double)vbz
//                                  vcx:(double)vcx
//                                  vcy:(double)vcy
//                                  vcz:(double)vcz
//                               result:(WWVec4*)result
//{
//    static double EPSILON = 0.00001;
//
//    WWVec4* origin = [line origin];
//    WWVec4* dir = [line direction];
//
//    // find vectors for two edges sharing point a: vb - va and vc - va
//    double edge1x = vbx - vax;
//    double edge1y = vby - vay;
//    double edge1z = vbz - vaz;
//
//    double edge2x = vcx - vax;
//    double edge2y = vcy - vay;
//    double edge2z = vcz - vaz;
//
//    // Compute cross product of edge1 and edge2
//    double nx = (edge1y * edge2z) - (edge1z * edge2y);
//    double ny = (edge1z * edge2x) - (edge1x * edge2z);
//    double nz = (edge1x * edge2y) - (edge1y * edge2x);
//
//    double tvecx = [origin x] - vax;
//    double tvecy = [origin y] - vay;
//    double tvecz = [origin z] - vaz;
//
//    // Compute the dot product of N and ray direction
//    double b = nx * [dir x] + ny * [dir y] + nz * [dir z];
//    if (b > -EPSILON && b < EPSILON) // ray is parallel to triangle plane
//    {
//        return NO;
//    }
//
//    double t = -(nx * tvecx + ny * tvecy + nz * tvecz) / b;
//    [line pointAt:t result:result];
//
//    return YES;
//}

@end