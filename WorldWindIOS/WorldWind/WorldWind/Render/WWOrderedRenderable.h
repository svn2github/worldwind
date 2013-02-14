/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import <Foundation/Foundation.h>
#import "WorldWind/Render/WWRenderable.h"

/**
* Represents a shape that participates in the scene controller's ordered renderable sorting. Ordered renderables are
* drawn back to front, with their relative position indicated by their distance from the eye point.
*/
@protocol WWOrderedRenderable <WWRenderable>

/**
* The shape's distance from the eye point, in meters.
*
* @return The shape's distance from the eye point, in meters.
*/
- (double) eyeDistance;

@end