/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import "WWTileList.h"


@implementation WWTileList

- (WWTileList*) initWithTiles:(NSArray*)tiles
{
    self = [super init];

    _tiles = tiles;

    return self;
}

- (long) sizeInBytes
{
    return [_tiles count] * [[_tiles objectAtIndex:0] sizeInBytes];
}

@end