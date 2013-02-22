/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import <Foundation/Foundation.h>
#import "WorldWind/Render/WWRenderable.h"

/**
* Represents a shape that participates in the scene controller's ordered renderable sorting. Ordered renderables are
* drawn back to front, with their relative position indicated by their distance from the eye point. If ordered
* renderables have the same eye distance, the one inserted first is drawn first.
*/
@protocol WWOrderedRenderable <WWRenderable>

/// @name Ordered Renderable Attributes

/**
* The shape's distance from the eye point, in meters.
*
* @return The shape's distance from the eye point, in meters.
*/
- (double) eyeDistance;

/**
* Set the shape's eye distance.
*
* @param eyeDistance The eye distance, in meters.
*/
- (void) setEyeDistance:(double)eyeDistance;

/**
* The shape's insertion time, the time it was placed in the ordered renderable list, in double precision seconds since
* the epoch.
*
* @return The shape's insertion time.
*/
- (NSTimeInterval) insertionTime;

/**
* Sets the shapes insertion time, the time it was placed in the ordered renderable list, in double precision seconds
* since the epoch.
*
* @param insertionTime The shape's insertion time.
*/
- (void) setInsertionTime:(NSTimeInterval)insertionTime;

@end