/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.

 @version $Id$
 */

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "WorldWind/Navigate/WWNavigator.h"

@class WorldWindView;
@class WWLocation;

@interface WWBasicNavigator : NSObject <WWNavigator, UIGestureRecognizerDelegate>
{
@protected
    WorldWindView* view;
    UIPanGestureRecognizer* panGestureRecognizer;
    UIPinchGestureRecognizer* pinchGestureRecognizer;
    WWLocation* beginLookAt;
    double beginRange;
}

@property (readonly, nonatomic) double nearDistance;
@property (readonly, nonatomic) double farDistance;
@property (nonatomic) WWLocation* lookAt;
@property (nonatomic) double range;

- (WWBasicNavigator*) initWithView:(WorldWindView*)viewToNavigate;

- (id<WWNavigatorState>) currentState;

- (void) updateView;

- (void) handlePanFrom:(UIPanGestureRecognizer*)recognizer;

- (void) handlePinchFrom:(UIPinchGestureRecognizer*)recognizer;

- (BOOL) gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer;

@end
