/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>

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
    CADisplayLink* displayLink;
    NSTimeInterval offsetTime;
    NSTimeInterval beginTime;
    NSTimeInterval currentTime;
    WWPosition* currentPosition;
    double currentHeading;
    double currentIndex;
    WWSphere* marker;
    WWRenderableLayer* layer;
    NSTimeInterval animBeginTime;
    NSTimeInterval animEndTime;
    NSTimeInterval animBeginHeading;
    NSTimeInterval animEndHeading;
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
* Starts the display link that moves the path marker along the path.
*/
- (void) startDisplayLink;

/**
* Stops the display link that moves the path marker along the path.
*/
- (void) stopDisplayLink;

/**
* Indicates that the path following display link has fired.
*
* @param notifyingDisplayLink The display link that sent his message.
*/
- (void) displayLinkDidFire:(CADisplayLink*)notifyingDisplayLink;

/**
* Updates the current path position and heading corresponding to the specified time.
*
* @param time The elapsed time since the beginning of the path, in seconds.
*
* @return YES if the time interval identifies a time between the beginning and end of the path, NO if the time interval
* represents a time at or beyond the end of the path.
*/
- (BOOL) updatePositionForElapsedTime:(NSTimeInterval)time;

/**
* Computes the current index in the path's list of positions corresponding to the specified time.
*
* The returned index ranges from 0 to count - 1, where count is the number of positions in the path. This returns
* count - 1 if the time interval represents a time at or beyond the end of the path.
*
* The integral portion of the returned number indicates the position ordinal corresponding to the beginning of the
* current path segment. The fractional portion of the returned number indicates the percentage travelled between the
* begin and end positions of the current path segment.
*
* @param time The elapsed time since the beginning of the path, in seconds.
*
* @return The current index in the path's list of positions.
*/
- (double) pathIndexForElapsedTime:(NSTimeInterval)time;

/**
* Indicates that this path follower has moved from one path segment to another.
*
* The specified positions indicate the begin and end positions associated with the new segment.
*
* @param beginPosition The new segment's beginning position.
* @param endPosition The new segment's ending position.
*/
- (void) segmentDidChange:(WWPosition*)beginPosition endPosition:(WWPosition*)endPosition;

/**
* Updates the view elements corresponding to this path follower.
*/
- (void) updateView;

/**
* Animates the World Wind view's navigator to the specified position and heading over a period of time.
*
* @param position The navigator's new position.
* @param heading The navigator's new heading, in degrees.
*/
- (void) animateNavigatorToPosition:(WWPosition*)position headingDegrees:(double)heading;

/**
* Sets the World Wind view's navigator to the specified position.
*
* @param position The navigator's new position.
*/
- (void) setNavigatorToPosition:(WWPosition*)position;

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
* recognized. This starts the path following display link when the initial navigator animation ends.
*
* @param notification The notification to interpret.
*/
- (void) handleNavigatorNotification:(NSNotification*)notification;

@end