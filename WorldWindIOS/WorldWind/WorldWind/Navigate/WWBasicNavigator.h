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

@interface WWBasicNavigator : NSObject<WWNavigator>
{
@protected
    WorldWindView* view;
    UIPanGestureRecognizer* panGestureRecognizer;
    UIPinchGestureRecognizer* pinchGestureRecognizer;
    WWLocation* beginLookAt;
    double beginRange;
}

@property (nonatomic) double fieldOfView;
@property (nonatomic) double nearDistance;
@property (nonatomic) double farDistance;
@property (nonatomic) WWLocation* lookAt;
@property (nonatomic) double range;

- (WWBasicNavigator*) initWithView:(WorldWindView*)viewToNavigate;

- (id<WWNavigatorState>) currentState;

- (void) handlePanFrom:(UIPanGestureRecognizer*)recognizer;

- (void) handlePinchFrom:(UIPinchGestureRecognizer*)recognizer;

- (void) updateView;

@end
