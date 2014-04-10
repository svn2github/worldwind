/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.

 @version $Id$
 */

#import "DraggablePopoverController.h"
#import "UIPopoverController+TAIGAAdditions.h"

@implementation DraggablePopoverController

- (id) initWithContentViewController:(UIViewController*)viewController
{
    self = [super initWithContentViewController:viewController];

    panGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePanFrom:)];
    [[viewController view] addGestureRecognizer:panGestureRecognizer];

    _dragEnabled = YES;

    return self;
}

- (void) dealloc
{
    [[[self contentViewController] view] removeGestureRecognizer:panGestureRecognizer];
}

- (void) setContentViewController:(UIViewController*)newViewController
{
    [self setContentViewController:newViewController animated:NO];
}

- (void) setContentViewController:(UIViewController*)newViewController animated:(BOOL)animated
{
    UIViewController* oldViewController = [self contentViewController];
    [[oldViewController view] removeGestureRecognizer:panGestureRecognizer];
    [[newViewController view] addGestureRecognizer:panGestureRecognizer];

    [super setContentViewController:newViewController animated:animated];
}

- (void) presentPopoverFromPoint:(CGPoint)point
                          inView:(UIView*)view
        permittedArrowDirections:(UIPopoverArrowDirection)arrowDirections
                        animated:(BOOL)animated
{
    [super presentPopoverFromPoint:point inView:view permittedArrowDirections:arrowDirections animated:animated];

    _point = point;
    _view = view;
    _arrowDirections = arrowDirections;
}

- (void) handlePanFrom:(UIPanGestureRecognizer*)recognizer
{
    if ([recognizer state] == UIGestureRecognizerStateBegan)
    {
        gestureBeginPoint = _point;
        [self popoverDraggingDidBegin];
    }
    else if ([recognizer state] == UIGestureRecognizerStateEnded || [recognizer state] == UIGestureRecognizerStateCancelled)
    {
        [self popoverDraggingDidEnd];
    }
    else if ([recognizer state] == UIGestureRecognizerStateChanged)
    {
        // Compute the coordinates of the new point based on the current pan translation.
        CGPoint translation = [recognizer translationInView:[[self contentViewController] view]];
        CGPoint newPoint = CGPointMake(gestureBeginPoint.x + translation.x, gestureBeginPoint.y + translation.y);

        // Limit the new point's coordinates to the view's bounds.
        CGRect bounds = [_view bounds];
        if (newPoint.x < CGRectGetMinX(bounds))
            newPoint.x = CGRectGetMinX(bounds);
        if (newPoint.x > CGRectGetMaxX(bounds))
            newPoint.x = CGRectGetMaxX(bounds);
        if (newPoint.y < CGRectGetMinY(bounds))
            newPoint.y = CGRectGetMinY(bounds);
        if (newPoint.y > CGRectGetMaxY(bounds))
            newPoint.y = CGRectGetMaxY(bounds);

        // Update the popover to display its arrow at the new point's coordinates, provided a subclass does not suppress
        // this change.
        if ([self popoverPointWillChange:newPoint])
        {
            _point = newPoint;
            [super presentPopoverFromPoint:_point inView:_view permittedArrowDirections:_arrowDirections animated:NO];
        }
    }
}

- (BOOL) gestureRecognizerShouldBegin:(UIGestureRecognizer*)gestureRecognizer
{
    return _dragEnabled;
}

- (void) popoverDraggingDidBegin
{
    // Subclasses should implement this method.
}

- (void) popoverDraggingDidEnd
{
    // Subclasses should implement this method.
}

- (BOOL) popoverPointWillChange:(CGPoint)newPoint
{
    return YES; // Subclasses should implement this method.
}

@end