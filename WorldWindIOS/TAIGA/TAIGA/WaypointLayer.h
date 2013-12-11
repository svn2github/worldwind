/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.

 @version $Id$
 */

#import <Foundation/Foundation.h>
#import "WorldWind/Layer/WWRenderableLayer.h"

@class WaypointFile;

@interface WaypointLayer : WWRenderableLayer

- (WaypointLayer*) init;

- (void) setWaypoints:(WaypointFile*)waypointFile;

@end