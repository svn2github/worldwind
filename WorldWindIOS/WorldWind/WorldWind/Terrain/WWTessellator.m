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

#define NUM_LAT_SUBDIVISIONS 3
#define NUM_LON_SUBDIVISIONS 6

@implementation WWTessellator

- (WWTessellator*) initWithGlobe:(WWGlobe *)globe
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
        }
    }
}

- (WWTerrainTileList*) tessellate:(WWDrawContext*)dc
{
    WWTerrainTileList* tiles = [[WWTerrainTileList alloc] initWithTessellator:self];
    
    NSUInteger count = [self->topLevelTiles count];
    for (NSUInteger i = 0; i < count; i++)
    {
        [tiles addTile:[self->topLevelTiles objectAtIndex:i]];
    }
    
    tiles.sector = WWSECTOR_FULL_SPHERE;
    
    return tiles;
}

- (void) beginRendering:(WWDrawContext *)dc
{
    
}

- (void) endRendering:(WWDrawContext *)dc
{
    
}

- (void) beginRendering:(WWDrawContext *)dc terrainTile:(WWTerrainTile*)tile
{
    
}

- (void) endRendering:(WWDrawContext *)dc terrainTile:(WWTerrainTile*)tile
{
    
}

- (void) render:(WWDrawContext *)dc tile:(WWTerrainTile*)tile
{
    
}

@end
