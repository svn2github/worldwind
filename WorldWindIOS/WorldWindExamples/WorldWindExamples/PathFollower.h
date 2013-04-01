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
    NSTimer* timer;
    NSTimeInterval offsetTime;
    NSTimeInterval beginTime;
    NSTimeInterval currentTime;
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
@property(nonatomic, getter=isEnabled) BOOL enabled;

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
* Starts the timer that moves the path marker along the path.
*/
- (void) startTimer;

/**
* Stops the timer that moves the path marker along the path.
*/
- (void) stopTimer;

/**
* Indicates that the path following timer has fired.
*
* @param notifyingTimer The timer that sent his message.
*/
- (void) timerDidFire:(NSTimer*)notifyingTimer;

/**
* Computes the position corresponding to the specified time.
*
* @param time The elapsed time since, in seconds.
* @param outPosition The position that receives the computed position.
*
* @return YES if the time interval identifies a time between the beginning and end of the path, NO if the time interval
* represents a time at or beyond the end of the path.
*
* @return The computed position.
*/
- (BOOL) positionForTimeInterval:(NSTimeInterval)timeInterval outPosition:(WWPosition*)result;

/**
* Starts observing messages sent to the notification center by the World Wind Navigator.
*/
- (void) startObservingNavigator;

/**
* Stops observing messages sent to the notification center by the World Wind Navigator.
*/
- (void) stopObservingNavigator;

/**
* Interprets messages sent to the notification center by the World Wind Navigator.
*
* This disables path following if a navigator animation has ended or been cancelled, or if a navigator gesture has been
* recognized. This starts the path following timer when the initial navigator animation ends.
*
* @param notification The notification to interpret.
*/
- (void) handleNavigatorNotification:(NSNotification*)notification;

@end