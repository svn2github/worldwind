/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import "WorldWind/Terrain/WWTessellator.h"
#import "WorldWind/Geometry/WWBoundingBox.h"
#import "WorldWind/Geometry/WWLine.h"
#import "WorldWind/Geometry/WWMatrix.h"
#import "WorldWind/Geometry/WWPosition.h"
#import "WorldWind/Geometry/WWSector.h"
#import "WorldWind/Geometry/WWVec4.h"
#import "WorldWind/Navigate/WWNavigatorState.h"
#import "WorldWind/Pick/WWPickedObject.h"
#import "WorldWind/Render/WWDrawContext.h"
#import "WorldWind/Render/WWGpuProgram.h"
#import "WorldWind/Shaders/WWBasicProgram.h"
#import "WorldWind/Terrain/WWGlobe.h"
#import "WorldWind/Terrain/WWTerrainSharedGeometry.h"
#import "WorldWind/Terrain/WWTerrainTile.h"
#import "WorldWind/Terrain/WWTerrainTileList.h"
#import "WorldWind/Util/WWFrameStatistics.h"
#import "WorldWind/Util/WWGpuResourceCache.h"
#import "WorldWind/Util/WWLevel.h"
#import "WorldWind/Util/WWLevelSet.h"
#import "WorldWind/Util/WWMath.h"
#import "WorldWind/Util/WWMemoryCache.h"
#import "WorldWind/WorldWindConstants.h"
#import "WorldWind/WWLog.h"

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

    NSTimeInterval lastElevationsChange = [[[dc globe] elevationTimestamp] timeIntervalSinceReferenceDate];
    if ([currentTiles count] > 0
            && elevationTimestamp == lastElevationsChange
            && lastMVP != nil && [[[dc navigatorState] modelviewProjection] isEqual:lastMVP])
    {
        return currentTiles;
    }
    lastMVP = [[dc navigatorState] modelviewProjection];

    [self->currentTiles removeAllTiles];
    self->currentCoverage = nil;
    elevationTimestamp = lastElevationsChange; // Store the elevation timestamp to prevent it from changing during tessellation.

    if ([self->topLevelTiles count] == 0)
    {
        [self createTopLevelTiles];
    }

    for (WWTerrainTile* tile in self->topLevelTiles)
    {
        [tile update:dc];

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
        [child update:dc];

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
    return [tile geometryTimestamp] != elevationTimestamp;
}

- (void) regenerateTileGeometry:(WWDrawContext*)dc tile:(WWTerrainTile*)tile
{
    [self buildTileVertices:dc tile:tile];
    [self buildSharedGeometry:tile];
    [tile setGeometryTimestamp:elevationTimestamp];
}

- (void) buildTileVertices:(WWDrawContext*)dc tile:(WWTerrainTile*)tile
{
    WWSector* sector = [tile sector];
    double ve = [dc verticalExaggeration];

    // Cartesian tile coordinates are relative to a local origin, called the reference center. Compute the reference
    // center here and establish a translation transform that is used later to move the tile coordinates into place
    // relative to the globe.
    WWVec4* refCenter = [tile referenceCenter];
    [refCenter set:[[tile referencePoints] objectAtIndex:4]]; // Use the tile's centroid point with the min elevation.
    [[tile transformationMatrix] setTranslation:[refCenter x] y:[refCenter y] z:[refCenter z]];

    // The number of vertices in each dimension is 1 more than the number of cells.
    int numLatVertices = [tile tileWidth] + 1;
    int numLonVertices = [tile tileHeight] + 1;
    int vertexStride = 3;

    // Retrieve the elevations for all vertices in the tile. The returned elevations will already have vertical
    // exaggeration applied.
    if (!tileElevations)
    {
        tileElevations = malloc((size_t) numLatVertices * numLonVertices * sizeof(double));
    }
    memset(tileElevations, 0, (size_t) (numLatVertices * numLonVertices * sizeof(double)));
    [_globe elevationsForSector:sector
                           numLat:numLatVertices
                           numLon:numLonVertices
                 targetResolution:[tile texelSize]
             verticalExaggeration:ve
                           result:tileElevations];

    // Allocate space for the Cartesian vertices.
    float* points = [tile points];
    if (!points)
    {
        int numPoints = (numLatVertices + 2) * (numLonVertices + 2);
        points = malloc((size_t) (numPoints * vertexStride * sizeof(float)));
        [tile setNumPoints:numPoints];
        [tile setPoints:points];
    }

    // The min elevation is used to determine the necessary depth of the tile skirts.
    double borderElevation = [_globe minElevation] * ve;
    [_globe computePointsFromPositions:sector
                                numLat:numLatVertices
                                numLon:numLonVertices
                       metersElevation:tileElevations
                       borderElevation:borderElevation
                                offset:refCenter
                           outputArray:points
                          outputStride:vertexStride];
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

- (void) beginRendering:(WWDrawContext* __unsafe_unretained)dc
{
    if (dc == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Draw context is nil")
    }

    WWGpuProgram* __unsafe_unretained program = [dc currentProgram]; // use the current program; the caller configures other program state
    if (program == nil)
    {
        WWLog(@"Current program is nil");
        return;
    }

    [self cacheSharedGeometryVBOs:dc];

    // Keep track of the program's attribute locations. The tessellator does not know which program the caller has
    // bound, and therefore must look up the location of attributes by name.
    vertexPointLocation = [program attributeLocation:@"vertexPoint"];
    vertexTexCoordLocation = [program attributeLocation:@"vertexTexCoord"];
    mvpMatrixLocation = [program uniformLocation:@"mvpMatrix"];
    glEnableVertexAttribArray((GLuint) vertexPointLocation);

    WWGpuResourceCache* __unsafe_unretained gpuResourceCache = [dc gpuResourceCache];

    if (vertexTexCoordLocation >= 0) // location of vertexTexCoord attribute is -1 when the basic program is bound
    {
        NSNumber* __unsafe_unretained texCoordVboId = (NSNumber*) [gpuResourceCache resourceForKey:[_sharedGeometry texCoordVboCacheKey]];
        glBindBuffer(GL_ARRAY_BUFFER, (GLuint) [texCoordVboId intValue]);
        glVertexAttribPointer((GLuint) vertexTexCoordLocation, 2, GL_FLOAT, false, 0, 0);
        glEnableVertexAttribArray((GLuint) vertexTexCoordLocation);
    }

    NSNumber* __unsafe_unretained indicesVboId = (NSNumber*) [gpuResourceCache resourceForKey:[_sharedGeometry indicesVboCacheKey]];
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, (GLuint) [indicesVboId intValue]);
}

- (void) endRendering:(WWDrawContext* __unsafe_unretained)dc
{
    if (dc == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Draw context is nil")
    }

    glBindBuffer(GL_ARRAY_BUFFER, 0);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0);

    // Restore the global OpenGL vertex attribute array state.
    glDisableVertexAttribArray((GLuint) vertexPointLocation);

    if (vertexTexCoordLocation >= 0) // location of vertexTexCoord attribute is -1 when the basic program is bound
    {
        glDisableVertexAttribArray((GLuint) vertexTexCoordLocation);
    }
}

- (void) beginRendering:(WWDrawContext* __unsafe_unretained)dc tile:(WWTerrainTile* __unsafe_unretained)tile
{
    if (dc == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Draw context is nil")
    }

    if (tile == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Terrain tile is nil")
    }

    WWMatrix* mvp = [[WWMatrix alloc] initWithMultiply:[[dc navigatorState] modelviewProjection]
                                               matrixB:[tile transformationMatrix]];
    [WWGpuProgram loadUniformMatrix:mvp location:(GLuint) mvpMatrixLocation];

    WWGpuResourceCache* __unsafe_unretained gpuResourceCache = [dc gpuResourceCache];
    NSNumber* __unsafe_unretained vbo = (NSNumber*) [gpuResourceCache resourceForKey:[tile geometryVboCacheKey]];
    if (vbo == nil)
    {
        GLsizei size = [tile numPoints] * 3 * sizeof(float);
        GLuint vboId;
        glGenBuffers(1, &vboId);
        glBindBuffer(GL_ARRAY_BUFFER, vboId);
        glBufferData(GL_ARRAY_BUFFER, size, [tile points], GL_STATIC_DRAW);
        [gpuResourceCache putResource:[[NSNumber alloc] initWithInt:vboId]
                         resourceType:WW_GPU_VBO
                                 size:size
                               forKey:[tile geometryVboCacheKey]];
        [tile setGeometryVboTimestamp:[tile geometryTimestamp]];
        [[dc frameStatistics] incrementVboLoadCount:1];
    }
    else if ([tile geometryVboTimestamp] != [tile geometryTimestamp])
    {
        GLsizei size = [tile numPoints] * 3 * sizeof(float);
        GLuint vboId = (GLuint) [vbo intValue];
        glBindBuffer(GL_ARRAY_BUFFER, vboId);
        glBufferSubData(GL_ARRAY_BUFFER, 0, size, [tile points]);
        [tile setGeometryVboTimestamp:[tile geometryTimestamp]];
    }
    else
    {
        GLuint vboId = (GLuint) [vbo intValue];
        glBindBuffer(GL_ARRAY_BUFFER, vboId);
    }

    glVertexAttribPointer((GLuint) vertexPointLocation, 3, GL_FLOAT, GL_FALSE, 0, 0);
}

- (void) endRendering:(WWDrawContext* __unsafe_unretained)dc tile:(WWTerrainTile* __unsafe_unretained)tile
{
}

- (void) render:(WWDrawContext* __unsafe_unretained)dc tile:(WWTerrainTile* __unsafe_unretained)tile
{
    if (dc == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Draw context is nil")
    }

    if (tile == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Terrain tile is nil")
    }

    glDrawElements(GL_TRIANGLE_STRIP, [_sharedGeometry numIndices], GL_UNSIGNED_SHORT, 0);
}

- (void) renderWireframe:(WWDrawContext*)dc tile:(WWTerrainTile*)tile
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

- (void) cacheSharedGeometryVBOs:(WWDrawContext* __unsafe_unretained)dc
{
    WWGpuResourceCache* __unsafe_unretained gpuResourceCache = [dc gpuResourceCache];

    NSNumber* __unsafe_unretained texCoordVbo = (NSNumber*) [gpuResourceCache resourceForKey:[_sharedGeometry texCoordVboCacheKey]];
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
        [[dc frameStatistics] incrementVboLoadCount:1];
        glBindBuffer(GL_ARRAY_BUFFER, 0);
    }

    NSNumber* __unsafe_unretained indicesVbo = (NSNumber*) [gpuResourceCache resourceForKey:[_sharedGeometry indicesVboCacheKey]];
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
        [[dc frameStatistics] incrementVboLoadCount:1];
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

    [dc bindProgramForKey:[WWBasicProgram programKey] class:[WWBasicProgram class]];
    WWBasicProgram* program = (WWBasicProgram*) [dc currentProgram];
    if (program == nil)
    {
        return;
    }

    unsigned int colorInt = dc.uniquePickColor;
    unsigned int minColorCode = colorInt >> 8; // shift alpha out of the way

    // Draw each terrain tile in a unique color. The fact that the colors are sequential is used below to determine
    // which tile is under the pick point.

    [self beginRendering:dc];
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
            [self beginRendering:dc tile:tile];

            @try
            {
                [program loadPickColor:colorInt];
                [self render:dc tile:tile]; // render the tile
            }
            @finally
            {
                [self endRendering:dc tile:tile];
            }
        }
    }
    @finally
    {
        [self endRendering:dc];
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
    WWVec4* refCenter = [tile referenceCenter];
    [[ray origin] subtract3:refCenter];

    // Check all triangles for intersection with the pick ray.

    BOOL found;
    WWVec4* pickedPoint = [[WWVec4 alloc] initWithZeroVector];
    int nIndices = [_sharedGeometry numIndices];
    short* indices = [_sharedGeometry indices];
    float* points = [tile points];
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