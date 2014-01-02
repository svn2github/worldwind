/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import <Foundation/Foundation.h>

@protocol WWNavigator;
@class WorldWindView;
@class WWPath;
@class WWSphere;
@class WWRenderableLayer;
@class WWPosition;

/**
* Uses a marker to indicated a moving position at a specified speed along a specified path.
*/
@interface PathFollower : NSObject
{
@protected
    BOOL followingPath;
    NSTimeInterval beginTime;
    NSTimeInterval markTime;
    NSTimeInterval elapsedTime;
    NSTimeInterval headingBeginTime;
    NSTimeInterval headingEndTime;
    double beginHeading;
    double endHeading;
    double lastHeading;
    double currentHeading;
    WWPosition* currentPosition;
    WWSphere* marker;
    WWRenderableLayer* layer;
}

/// @name Attributes

/// The path to follow.
@property(nonatomic, readonly) WWPath* path;

/// The speed at which to follow the path, in meters per second.
@property(nonatomic, readonly) double speed;

/// The World Wind view in which to display the marker.
@property(nonatomic, readonly) WorldWindView* wwv;

/// Indicates whether or not the path follower is enabled. YES indicates that the marker should move along the path
/// until it reaches the end; NO indicates that the path follower should display the marker at its current location but
/// otherwise do nothing.
@property(nonatomic) BOOL enabled;

/// Indicates whether or not the path follower has reached the end of the path.
@property(nonatomic, readonly) BOOL finished;

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

/// @name Methods of Interest Only to Subclasses

/**
* Navigates the WorldWindView to the current position along the path, then begins following the path.
*/
- (void) startFollowingPath;

/**
* Moves a marker along the current path position at the specified speed, while keeping the WorldWindView centered on the
* current path position.
*/
- (void) followPath;

/**
* Updates the current path position and heading corresponding to the specified time interval.
*
* @param seconds The elapsed time since the beginning of the path, in seconds.
*/
- (void) updateCurrentPositionWithTimeInterval:(NSTimeInterval)seconds;

/**
* Updates a marker object to appear at the current path position.
*/
- (void) markCurrentPosition;

/**
* Updates the navigator to place the current path position in the center of the WorldWindView.
*/
- (void) followCurrentPosition;

/**
* Configures the navigator with the current path position and current path heading. The behavior of this method depends
* on the navigator type. When the navigator is a WWFirstPersonNavigator this sets the navigator's eye position to the
* specified position; Otherwise this sets the navigator looking at the specified position from a pre-defined distance.
*/
- (void) setNavigator:(id<WWNavigator>)navigator withPosition:(WWPosition*)position heading:(double)heading;

/**
* Called when the WorldWindView's navigator instance changes. This typically indicates that the application has switched
* between two navigator types.
*/
- (void) navigatorDidChange;

@end