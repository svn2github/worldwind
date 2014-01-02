/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.

 @version $Id$
 */

#import <Foundation/Foundation.h>
#import "WorldWind/Navigate/WWAbstractNavigator.h"

@class WWLocation;
@class WWVec4;

@interface WWFirstPersonNavigator : WWAbstractNavigator <UIGestureRecognizerDelegate>
{
@protected
    // Gesture Recognizer properties.
    UIPanGestureRecognizer* panGestureRecognizer;
    UIPinchGestureRecognizer* pinchGestureRecognizer;
    UIRotationGestureRecognizer* rotationGestureRecognizer;
    UIPanGestureRecognizer* twoFingerPanGestureRecognizer;
    NSArray* pinchRotationGestureRecognizers;
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
    NSDate* animationBeginDate;
    NSDate* animationEndDate;
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

/// @name Initializing Navigators

- (WWFirstPersonNavigator*) initWithView:(WorldWindView*)view;

- (WWFirstPersonNavigator*) initWithView:(WorldWindView*)view navigatorToMatch:(id<WWNavigator>)navigator;

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