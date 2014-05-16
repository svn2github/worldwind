/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.

 @version $Id$
 */

#import "DraggablePopoverController.h"
#import "UIPopoverController+TAIGAAdditions.h"

#define DISPLAY_LINK_FRAME_INTERVAL (3)

@implementation DraggablePopoverController

- (id) initWithContentViewController:(UIViewController*)viewController
{
    self = [super initWithContentViewController:viewController];

    panGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePanFrom:)];
    [panGestureRecognizer setDelegate:self];
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
        gestureNewPoint = _point;
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
        gestureNewPoint.x = gestureBeginPoint.x + translation.x;
        gestureNewPoint.y = gestureBeginPoint.y + translation.y;

        // Limit the new point's coordinates to the view's bounds.
        CGRect bounds = [_view bounds];
        if (gestureNewPoint.x < CGRectGetMinX(bounds))
            gestureNewPoint.x = CGRectGetMinX(bounds);
        if (gestureNewPoint.x > CGRectGetMaxX(bounds))
            gestureNewPoint.x = CGRectGetMaxX(bounds);
        if (gestureNewPoint.y < CGRectGetMinY(bounds))
            gestureNewPoint.y = CGRectGetMinY(bounds);
        if (gestureNewPoint.y > CGRectGetMaxY(bounds))
            gestureNewPoint.y = CGRectGetMaxY(bounds);
    }
}

- (BOOL) gestureRecognizerShouldBegin:(UIGestureRecognizer*)gestureRecognizer
{
    return _dragEnabled;
}

- (void) popoverDraggingDidBegin
{
    displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(displayLinkDidFire)];
    [displayLink setFrameInterval:DISPLAY_LINK_FRAME_INTERVAL];
    [displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
}

- (void) popoverDraggingDidEnd
{
    [displayLink invalidate];
    displayLink = nil;
}

- (void) displayLinkDidFire
{
    // Update the popover to display its arrow at the new point's coordinates, provided a subclass does not suppress
    // this change.
    if ([self popoverPointWillChange:gestureNewPoint])
    {
        _point = gestureNewPoint;
        [super presentPopoverFromPoint:_point inView:_view permittedArrowDirections:_arrowDirections animated:NO];
    }
}

- (BOOL) popoverPointWillChange:(CGPoint)newPoint
{
    return YES; // Subclasses should implement this method.
}

@end