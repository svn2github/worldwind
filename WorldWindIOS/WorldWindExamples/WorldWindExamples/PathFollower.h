/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import <Foundation/Foundation.h>

@class WWPath;
@class WorldWindView;
@class WWSphere;
@class WWRenderableLayer;
@class WWPosition;

/**
* Uses a marker to indicated a moving position at a specified speed along a specified path.
*/
@interface PathFollower : NSObject
{
@protected
    NSDate* startTime;
    WWSphere* marker;
    WWRenderableLayer* layer;
    NSTimer* timer;
}

/// @name Attributes

/// The path to follow.
@property(nonatomic, readonly) WWPath* path;

/// The speed at which to follow the path, in meters per second.
@property(nonatomic, readonly) double speed;

/// The World Wind view in which to display the marker.
@property(nonatomic, readonly) WorldWindView* wwv;

/// @name Initializing

/**
* Initialize this path follower to a specified path, speed and World Wind view.
*
* The application must call this class' start method to begin the path following.
*
* This method adds a layer to the World Wind model. The layer contains a single renderable, the marker.
*
* @param path The path to follow.
* @param speed The speed at which to follow the path, in meters per second.
* @param view The World Wind view in which to display the marker.
*/
- (PathFollower*) initWithPath:(WWPath*)path speed:(double)speed view:(WorldWindView*)view;

/// @name Operations

/**
* Remove this path followers marker from its layer and the layer from the World Wind layer list.
*
* This method must be called to remove the marker from the screen.
*/
- (void) dispose;

/**
* Starts the path following.
*/
- (void) start;

/**
* Stops the path following.
*/
- (void) stop;

/// @name Methods of Interest Only to Subclasses

/**
* Computes the position corresponding to the elapsed time.
*
* @return The computed position.
*/
- (WWPosition*) computePositionForNow;

@end