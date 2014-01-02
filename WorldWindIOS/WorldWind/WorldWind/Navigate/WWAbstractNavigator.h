/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.

 @version $Id$
 */

#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>
#import <UIKit/UIKit.h>
#import "WorldWind/Navigate/WWNavigator.h"

@class WorldWindView;
@class WWMatrix;
@class WWPosition;

@interface WWAbstractNavigator : NSObject <WWNavigator>
{
@protected
    // Display link interface properties.
    CADisplayLink* displayLink;
    int displayLinkObservers;
    // Animation interface properties.
    BOOL animating;
    void (^animationBlock)(NSDate* timestamp, BOOL* stop);
    void (^completionBlock)(BOOL finished);
}

/// @name Navigator Attributes

@property (nonatomic, readonly, weak) WorldWindView* view; // Keep a weak reference to the parent view to prevent a circular reference.

@property (nonatomic) double heading;

@property (nonatomic) double tilt;

@property (nonatomic) double roll;

@property (nonatomic, readonly) double nearDistance;

@property (nonatomic, readonly) double farDistance;

/// @name Initializing Navigators

- (WWAbstractNavigator*) initWithView:(WorldWindView*)view;

/// @name Navigator Protocol for Subclasses

- (id<WWNavigatorState>) currentStateForModelview:(WWMatrix*)modelview;

/// @name Core Location Interface for Subclasses

- (WWPosition*) lastKnownPosition;

/// @name Display Link Interface for Subclasses

- (void) startDisplayLink;

- (void) stopDisplayLink;

- (void) displayLinkDidFire:(CADisplayLink*)notifyingDisplayLink;

/// @name Gesture Recognizer Interface for Subclasses

- (void) gestureRecognizerDidBegin:(UIGestureRecognizer*)recognizer;

- (void) gestureRecognizerDidEnd:(UIGestureRecognizer*)recognizer;

/// @name Animation Interface for Subclasses

- (void) beginAnimation;

- (void) endAnimation:(BOOL)finished;

- (void) updateAnimation:(NSDate*)timestamp;

- (void) doUpdateAnimation:(NSDate*)timestamp;

- (void) setupAnimationWithDuration:(NSTimeInterval)duration animations:(void (^)(void))animations;

@end