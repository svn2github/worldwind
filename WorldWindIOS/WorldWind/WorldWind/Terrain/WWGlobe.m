/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import "WorldWind/Terrain/WWGlobe.h"
#import "WorldWind/Terrain/WWTessellator.h"

@implementation WWGlobe

- (WWTerrainTileList*) tessellate:(WWDrawContext*)dc
{
    if (_tessellator == nil)
    {
        _tessellator = [[WWTessellator alloc] initWithGlobe:self];
    }
    
    return [_tessellator tessellate:dc];
}

@end
