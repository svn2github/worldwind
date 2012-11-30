/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import "WorldWind/Terrain/WWGlobe.h"
#import "WorldWind/Terrain/WWTessellator.h"
#import "WorldWind/WWLog.h"

@implementation WWGlobe

- (WWGlobe *) init
{
    self = [super init];

    _tessellator = [[WWTessellator alloc] initWithGlobe:self];

    return self;
}

- (WWTerrainTileList*) tessellate:(WWDrawContext*)dc
{
    if (dc == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Draw contexts is nil")
    }

    return [_tessellator tessellate:dc];
}

@end
