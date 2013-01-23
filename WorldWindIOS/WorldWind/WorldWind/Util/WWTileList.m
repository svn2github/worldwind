/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import "WorldWind/Util/WWTileList.h"
#import "WorldWind/WWLog.h"


@implementation WWTileList

- (WWTileList*) initWithTiles:(NSArray*)tiles
{
    if (tiles == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Tessellator is nil")
    }

    self = [super init];

    _tiles = tiles;

    return self;
}

- (long) sizeInBytes
{
    return [_tiles count] * [[_tiles objectAtIndex:0] sizeInBytes];
}

@end