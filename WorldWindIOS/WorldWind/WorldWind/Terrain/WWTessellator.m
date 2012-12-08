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
    [self buildSharedGeometry];

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
    if (dc == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Draw context is nil")
    }

    return tile.terrainGeometry == nil;
}

- (void) regenerateGeometry:(WWDrawContext*)dc tile:(WWTerrainTile*)tile
{
    if (dc == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Draw context is nil")
    }

    tile.terrainGeometry = [[WWTerrainGeometry alloc] init];

    WWSector* sector = tile.sector;

    WWVec4* refCenter = [[WWVec4 alloc] initWithZeroVector];
    double lat = 0.5 * (sector.minLatitude + tile.sector.maxLatitude);
    double lon = 0.5 * (sector.minLongitude + tile.sector.maxLongitude);
    [dc.globe computePointFromPosition:lat longitude:lon altitude:0 outputPoint:refCenter];
    tile.terrainGeometry.referenceCenter = refCenter;

    float* points = malloc(5 * 3 * sizeof(float)); // TODO: free this
    tile.terrainGeometry.points = points;
    tile.terrainGeometry.numPoints = 5;

    points[0] = (float) refCenter.x;
    points[1] = (float) refCenter.y;
    points[2] = (float) refCenter.z;

    lat = sector.minLatitude;
    lon = sector.minLongitude;
    [dc.globe computePointFromPosition:lat longitude:lon altitude:0 outputArray:&points[3]];

    lat = sector.minLatitude;
    lon = sector.maxLongitude;
    [dc.globe computePointFromPosition:lat longitude:lon altitude:0 outputArray:&points[6]];

    lat = sector.maxLatitude;
    lon = sector.maxLongitude;
    [dc.globe computePointFromPosition:lat longitude:lon altitude:0 outputArray:&points[9]];

    lat = sector.maxLatitude;
    lon = sector.minLongitude;
    [dc.globe computePointFromPosition:lat longitude:lon altitude:0 outputArray:&points[12]];
}

- (void) buildSharedGeometry
{
    _sharedGeometry = [[WWTerrainSharedGeometry alloc] init];

    // Assign indices for a triangle fan.
    short* indices = (short*) malloc(6 * sizeof(short));
    indices[0] = 0;
    indices[1] = 1;
    indices[2] = 2;
    indices[3] = 3;
    indices[4] = 4;
    indices[5] = 1;
    _sharedGeometry.indices = indices;

    // Assigne wireframe indices for a line loop.
    short* wireframeIndices = (short*) malloc(4 * sizeof(short));
    wireframeIndices[0] = 1;
    wireframeIndices[1] = 2;
    wireframeIndices[2] = 3;
    wireframeIndices[3] = 4;
    _sharedGeometry.wireframeIndices = wireframeIndices;
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
    int location = [program getAttributeLocation:@"Position"];
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

    int location = [program getAttributeLocation:@"Position"];
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

    [dc.currentProgram loadUniformMatrix:@"Modelview" matrix:dc.modelviewProjection];
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

    int location = [dc.currentProgram getAttributeLocation:@"Position"];
    WWTerrainGeometry* terrainGeometry = tile.terrainGeometry;
    glVertexAttribPointer((GLuint) location, 3, GL_FLOAT, GL_FALSE, 0, terrainGeometry.points);
    glDrawElements(GL_TRIANGLE_FAN, 6, GL_UNSIGNED_SHORT, _sharedGeometry.indices);
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

    int location = [dc.currentProgram getAttributeLocation:@"Position"];
    WWTerrainGeometry* terrainGeometry = tile.terrainGeometry;
    glVertexAttribPointer((GLuint) location, 3, GL_FLOAT, GL_FALSE, 0, terrainGeometry.points);
    glDrawElements(GL_LINE_LOOP, 6, GL_UNSIGNED_SHORT, _sharedGeometry.wireframeIndices);
}
@end
