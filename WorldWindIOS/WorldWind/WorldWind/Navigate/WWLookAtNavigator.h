/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.

 @version $Id$
 */

#import <Foundation/Foundation.h>
#import "WorldWind/Navigate/WWAbstractNavigator.h"

@class WWPosition;

@interface WWLookAtNavigator : WWAbstractNavigator <UIGestureRecognizerDelegate>
{
@protected
    // Gesture Recognizer properties.
    UIPanGestureRecognizer* panGestureRecognizer;
    UIPinchGestureRecognizer* pinchGestureRecognizer;
    UIRotationGestureRecognizer* rotationGestureRecognizer;
    UIPanGestureRecognizer* verticalPanGestureRecognizer;
    NSArray* panPinchRotationGestureRecognizers;
    CGPoint lastPanTranslation;
    double gestureBeginRange;
    double gestureBeginHeading;
    double gestureBeginTilt;
    // Animation properties.
    NSDate* animationBeginDate;
    NSDate* animationEndDate;
    WWPosition* animBeginLookAt;
    WWPosition* animEndLookAt;
    double animBeginRange;
    double animEndRange;
    double animMidRange;
    double animBeginHeading;
    double animEndHeading;
    double animBeginTilt;
    double animEndTilt;
    double animBeginRoll;
    double animEndRoll;
}

/// @name Navigator Attributes

@property (nonatomic) WWPosition* lookAtPosition;

@property (nonatomic) double range;

/// @name Initializing Navigators

- (WWLookAtNavigator*) initWithView:(WorldWindView*)view;

- (WWLookAtNavigator*) initWithView:(WorldWindView*)view navigatorToMatch:(id<WWNavigator>)navigator;

/// @name Gesture Recognizer Interface for Subclasses

- (void) handlePanFrom:(UIPanGestureRecognizer*)recognizer;

- (void) handlePinchFrom:(UIPinchGestureRecognizer*)recognizer;

- (void) handleRotationFrom:(UIRotationGestureRecognizer*)recognizer;

- (void) handleVerticalPanFrom:(UIPanGestureRecognizer*)recognizer;

- (BOOL) gestureRecognizer:(UIGestureRecognizer*)recognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer*)otherRecognizer;

- (BOOL) gestureRecognizerShouldBegin:(UIGestureRecognizer*)recognizer;

- (BOOL) gestureRecognizerIsVerticalPan:(UIPanGestureRecognizer*)recognizer;

@end