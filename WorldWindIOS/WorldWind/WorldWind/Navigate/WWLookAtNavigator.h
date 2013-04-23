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
    CGPoint lastPanTranslation;
    double gestureBeginRange;
    double gestureBeginHeading;
    double gestureBeginTilt;
    // Animation properties.
    WWPosition* animBeginLookAt;
    WWPosition* animEndLookAt;
    double animBeginRange;
    double animEndRange;
    double animMidRange;
}

/// @name Navigator Attributes

@property (nonatomic) WWPosition* lookAt;

@property (nonatomic) double range;

@property (nonatomic) double heading;

@property (nonatomic) double tilt;

@property (nonatomic) double roll;

/// @name Initializing Navigators

- (WWLookAtNavigator*) initWithView:(WorldWindView*)viewToNavigate;

/// @name Gesture Recognizer Interface for Subclasses

- (void) handlePanFrom:(UIPanGestureRecognizer*)recognizer;

- (void) handlePinchFrom:(UIPinchGestureRecognizer*)recognizer;

- (void) handleRotationFrom:(UIRotationGestureRecognizer*)recognizer;

- (void) handleVerticalPanFrom:(UIPanGestureRecognizer*)recognizer;

- (BOOL) gestureRecognizer:(UIGestureRecognizer*)recognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer*)otherRecognizer;

- (BOOL) gestureRecognizerShouldBegin:(UIGestureRecognizer*)recognizer;

/// @name Animation Interface for Subclasses

- (void) gotoLookAtPosition:(WWPosition*)lookAt range:(double)range overDuration:(NSTimeInterval)duration;

@end