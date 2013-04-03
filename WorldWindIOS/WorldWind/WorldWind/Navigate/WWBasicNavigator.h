/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.

 @version $Id$
 */

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "WorldWind/Navigate/WWNavigator.h"

@class WorldWindView;

/**
* TODO
*/
@interface WWBasicNavigator : NSObject <WWNavigator, UIGestureRecognizerDelegate>

/// @name Attributes

/**
* TODO
*/
@property (nonatomic) WWLocation* lookAt;

/**
* TODO
*/
@property (nonatomic) double range;

/**
* TODO
*/
@property (nonatomic) double heading;

/**
* TODO
*/
@property (nonatomic) double tilt;

/**
* TODO
*/
@property (readonly, nonatomic) double nearDistance;

/**
* TODO
*/
@property (readonly, nonatomic) double farDistance;

/// @name Initializing the Navigator

/**
* TODO
*
* @param viewToNavigate TODO
*
* @return TODO
*
* @exception TODO
*/
- (WWBasicNavigator*) initWithView:(WorldWindView*)viewToNavigate;

/// @name Methods of Interest Only to Subclasses

/**
* TODO
*/
- (void) setInitialLocation;

/**
* TODO
*/
- (void) startDisplayLink;

/**
* TODO
*/
- (void) stopDisplayLink;

/**
* TODO
*
* @param aDisplayLink TODO
*/
- (void) displayLinkDidFire:(CADisplayLink*)aDisplayLink;

/**
* TODO
*
* @param recognizer TODO
*/
- (void) handlePanFrom:(UIPanGestureRecognizer*)recognizer;

/**
* TODO
*
* @param recognizer TODO
*/
- (void) handlePinchFrom:(UIPinchGestureRecognizer*)recognizer;

/**
* TODO
*
* @param recognizer TODO
*/
- (void) handleRotationFrom:(UIRotationGestureRecognizer*)recognizer;

/**
* TODO
*
* @param recognizer TODO
*/
- (void) handleVerticalPanFrom:(UIPanGestureRecognizer*)recognizer;

/**
* TODO
*
* @param recognizer TODO
* @param otherRecognizer TODO
*
* @return TODO
*/
- (BOOL) gestureRecognizer:(UIGestureRecognizer*)recognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer*)otherRecognizer;

/**
* TODO
*
* @param recognizer TODO
*
* @return TODO
*/
- (BOOL) gestureRecognizerShouldBegin:(UIGestureRecognizer*)recognizer;

/**
* TODO
*
* @param recognizer TODO
*/
- (void) gestureRecognizerDidBegin:(UIGestureRecognizer*)recognizer;

/**
* TODO
*
* @param recognizer TODO
*/
- (void) gestureRecognizerDidEnd:(UIGestureRecognizer*)recognizer;

/**
* TODO
*
* @param recognizer TODO
*/
- (void) postGestureRecognized:(UIGestureRecognizer*)recognizer;

/**
* TODO
*
* @param beginLocation TODO
* @param endLocation TODO
* @param beginRange TODO
* @param endRange TODO
* @param duration TODO
*/
- (void) beginAnimationWithLookAt:(WWLocation*)lookAt range:(double)range overDuration:(NSTimeInterval)duration;

/**
* TODO
*/
- (void) endAnimation;

/**
* TODO
*/
- (void) cancelAnimation;

/**
* TODO
*
* @param date TODO
*/
- (void) updateAnimationForDate:(NSDate*)date;

/**
* TODO
*/
- (void) postAnimationBegan;

/**
* TODO
*/
- (void) postAnimationEnded;

/**
* TODO
*/
- (void) postAnimationCancelled;

@end