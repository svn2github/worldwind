/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.

 @version $Id$
 */

#import <Foundation/Foundation.h>
#import "WorldWind/Navigate/WWAbstractNavigator.h"

@class WWVec4;
@class WWPosition;

@interface WWFirstPersonNavigator : WWAbstractNavigator <UIGestureRecognizerDelegate>
{
@protected
    // Gesture Recognizer properties.
    UIPanGestureRecognizer* panGestureRecognizer;
    UIPinchGestureRecognizer* pinchGestureRecognizer;
    UIRotationGestureRecognizer* rotationGestureRecognizer;
    UIPanGestureRecognizer* twoFingerPanGestureRecognizer;
    CGPoint lastPanTranslation;
    double gestureBeginHeading;
    double gestureBeginTilt;
    // Touch Point Gesture properties.
    WWVec4* touchPoint;
    WWVec4* touchPointNormal;
    WWMatrix* touchPointModelview;
    WWMatrix* touchPointPinch;
    WWMatrix* touchPointRotation;
    id<WWNavigatorState> touchPointBeginState;
    int touchPointGestures;
    // Animation properties.
    WWLocation* animBeginLocation;
    WWLocation* animEndLocation;
    double animBeginAltitude;
    double animEndAltitude;
    double animMidAltitude;
    double animBeginHeading;
    double animEndHeading;
    double animBeginTilt;
    double animEndTilt;
    double animBeginRoll;
    double animEndRoll;
}

/// @name Navigator Attributes

@property (nonatomic) WWPosition* eyePosition;

@property (nonatomic) double heading;

@property (nonatomic) double tilt;

@property (nonatomic) double roll;

/// @name Initializing Navigators

- (WWFirstPersonNavigator*) initWithView:(WorldWindView*)view;

- (WWFirstPersonNavigator*) initWithView:(WorldWindView*)view navigatorToMatch:(id<WWNavigator>)navigator;

/// @name Animating to a Location of Interest

- (void) gotoEyePosition:(WWPosition*)eyePosition
            overDuration:(NSTimeInterval)duration;

- (void) gotoEyePosition:(WWPosition*)eyePosition
          headingDegrees:(double)heading
             tiltDegrees:(double)tilt
             rollDegrees:(double)roll
            overDuration:(NSTimeInterval)duration;

/// @name Gesture Recognizer Interface for Subclasses

- (void) handlePanFrom:(UIPanGestureRecognizer*)recognizer;

- (void) handlePinchFrom:(UIPinchGestureRecognizer*)recognizer;

- (void) handleRotationFrom:(UIRotationGestureRecognizer*)recognizer;

- (void) handleTwoFingerPanFrom:(UIPanGestureRecognizer*)recognizer;

- (BOOL) gestureRecognizer:(UIGestureRecognizer*)recognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer*)otherRecognizer;

- (BOOL) gestureRecognizerShouldBegin:(UIGestureRecognizer*)recognizer;

- (void) beginTouchPointGesture:(UIGestureRecognizer*)recognizer;

- (void) endTouchPointGesture:(UIGestureRecognizer*)recognizer;

- (void) applyTouchPointGestures;

- (WWVec4*) touchPointFor:(UIGestureRecognizer*)recognizer;

@end