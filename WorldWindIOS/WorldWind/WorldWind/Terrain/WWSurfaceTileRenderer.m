/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import "WWSurfaceTileRenderer.h"
#import "WorldWind/WWLog.h"

@implementation WWSurfaceTileRenderer

- (void) renderTiles:(WWDrawContext *)dc
{
    if (dc == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Draw context is nil")
    }

}

@end
