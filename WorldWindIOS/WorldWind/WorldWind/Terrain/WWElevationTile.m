/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.

 @version $Id$
 */

#import "WorldWind/Terrain/WWElevationTile.h"
#import "WorldWind/Terrain/WWElevationImage.h"
#import "WorldWind/Geometry/WWSector.h"
#import "WorldWind/Util/WWMemoryCache.h"
#import "WorldWind/WWLog.h"

@implementation WWElevationTile

- (WWElevationTile*) initWithSector:(WWSector*)sector
                              level:(WWLevel*)level
                                row:(int)row
                             column:(int)column
                          imagePath:(NSString*)imagePath
                              cache:(WWMemoryCache*)cache
{
    // superclass checks sector, level, row and column arguments.

    self = [super initWithSector:sector level:level row:row column:column];

    if (imagePath == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Tile image path is nil")
    }

    if (cache == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Cache is nil")
    }

    if (self != nil)
    {
        _imagePath = imagePath;
        _memoryCache = cache;
    }

    return self;
}

- (long) sizeInBytes
{
    return 8 + [_imagePath length] + [super sizeInBytes];
}

- (WWElevationImage*) image
{
    return [_memoryCache getValueForKey:_imagePath];
}

@end