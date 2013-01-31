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
@property (readonly, nonatomic) double nearDistance;

/**
* TODO
*/
@property (readonly, nonatomic) double farDistance;

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

/// @name Getting a Navigator State Snapshot

/**
* TODO
*
* @return TODO
*/
- (id<WWNavigatorState>) currentState;

/// @name Changing the Location of Interest

/**
* TODO
*
* @param location TODO
* @param animate TODO
*
* @exception TODO
*/
- (void) gotoLocation:(WWLocation*)location animate:(BOOL)animate;

/**
* TODO
*
* @param location TODO
* @param duration TODO
*
* @exception TODO
*/
- (void) gotoLocation:(WWLocation*)location overDuration:(NSTimeInterval)duration;

/**
* TODO
*
* @param location TODO
* @param distance TODO
* @param animate TODO
*
* @exception TODO
*/
- (void) gotoLocation:(WWLocation*)location fromDistance:(double)distance animate:(BOOL)animate;

/**
* TODO
*
* @param location TODO
* @param distance TODO
* @param duration TODO
*
* @exception TODO
*/
- (void) gotoLocation:(WWLocation*)location fromDistance:(double)distance overDuration:(NSTimeInterval)duration;

/**
* TODO
*
* @param center TODO
* @param radius TODO
* @param animate TODO
*
* @exception TODO
*/
- (void) gotoRegionWithCenter:(WWLocation*)center radius:(double)radius animate:(BOOL)animate;

/**
* TODO
*
* @param center TODO
* @param radius TODO
* @param duration TODO
*
* @exception TODO
*/
- (void) gotoRegionWithCenter:(WWLocation*)center radius:(double)radius overDuration:(NSTimeInterval)duration;

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
* @param duration TODO
*/
- (void) startAnimationWithBeginLocation:(WWLocation*)beginLocation
                             endLocation:(WWLocation*)endLocation
                              beginRange:(double)beginRange
                                endRange:(double)endRange
                                duration:(NSTimeInterval)duration;

/**
* TODO
*/
- (void) stopAnimation;

/**
* TODO
*
* @param date TODO
*/
- (void) updateAnimationForDate:(NSDate*)date;

/**
* TODO
*
* @param beginLocation TODO
* @param endLocation TODO
* @param beginRange TODO
* @param endRange TODO
*/
- (double) durationForAnimationWithBeginLocation:(WWLocation*)beginLocation
                                     endLocation:(WWLocation*)endLocation
                                      beginRange:(double)beginRange
                                        endRange:(double)endRange;
/**
* TODO
*
* @param beginLocation TODO
* @param endLocation TODO
*
* @return TODO
*/
- (double) rangeToFitBeginLocation:(WWLocation*)beginLocation endLocation:(WWLocation*)endLocation;

@end