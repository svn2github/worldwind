/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.

 @version $Id$
 */

#import "DraggablePopoverController.h"
#import "WorldWind/Geometry/WWPosition.h"
#import "WorldWind/Geometry/WWVec4.h"
#import "WorldWind/Navigate/WWNavigatorState.h"
#import "WorldWind/Render/WWSceneController.h"
#import "WorldWind/Terrain/WWGlobe.h"
#import "WorldWind/WorldWindView.h"

@implementation DraggablePopoverController

- (id) initWithContentViewController:(UIViewController*)viewController
{
    self = [super initWithContentViewController:viewController];

    panGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePanFrom:)];
    [[viewController view] addGestureRecognizer:panGestureRecognizer];

    _dragEnabled = YES;

    return self;
}

- (void) presentPopoverFromPosition:(WWPosition*)position inView:(WorldWindView*)view permittedArrowDirections:(UIPopoverArrowDirection)arrowDirections animated:(BOOL)animated
{
    WWVec4* modelPoint = [[WWVec4 alloc] init];
    [[[view sceneController] globe] computePointFromPosition:[position latitude] longitude:[position longitude]
                                                    altitude:[position altitude] outputPoint:modelPoint];

    WWVec4* screenPoint = [[WWVec4 alloc] init];
    [[[view sceneController] navigatorState] project:modelPoint result:screenPoint];

    CGPoint uiPoint = [[[view sceneController] navigatorState] convertPointToView:screenPoint];

    _position = [[WWPosition alloc] initWithPosition:position];
    _point = uiPoint;
    _view = view;
    _arrowDirections = arrowDirections;

    [self presentPopoverFromRect:CGRectMake(_point.x, _point.y, 1, 1) inView:_view permittedArrowDirections:_arrowDirections animated:animated];
}

- (void) handlePanFrom:(UIPanGestureRecognizer*)recognizer
{
    if ([recognizer state] == UIGestureRecognizerStateBegan)
    {
        gestureBeginPoint = _point;
        [self beginDrag];
    }
    else if ([recognizer state] == UIGestureRecognizerStateEnded || [recognizer state] == UIGestureRecognizerStateCancelled)
    {
        [self endDrag];
    }
    else if ([recognizer state] == UIGestureRecognizerStateChanged)
    {
        CGPoint translation = [recognizer translationInView:[[self contentViewController] view]];
        CGPoint newPoint = CGPointMake(gestureBeginPoint.x + translation.x, gestureBeginPoint.y + translation.y);
        if (CGRectContainsPoint([_view bounds], newPoint))
        {
            WWLine* ray = [[[_view sceneController] navigatorState] rayFromScreenPoint:newPoint];
            WWVec4* p = [[WWVec4 alloc] init];
            if ([[[_view sceneController] globe] intersectWithRay:ray result:p])
            {
                [[[_view sceneController] globe] computePositionFromPoint:[p x] y:[p y] z:[p z] outputPosition:_position];
                _point = newPoint;

                [self presentPopoverFromRect:CGRectMake(_point.x, _point.y, 1, 1) inView:_view permittedArrowDirections:_arrowDirections animated:NO];
                [self positionDidChange];
            }
        }
    }
}

- (BOOL) gestureRecognizerShouldBegin:(UIGestureRecognizer*)gestureRecognizer
{
    return _dragEnabled;
}

- (void) beginDrag
{
    // Subclasses must implement this method.
}

- (void) endDrag
{
    // Subclasses must implement this method.
}

- (void) positionDidChange
{
    // Subclasses must implement this method to determine when the popover's position changes.
}

@end