/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.

 @version $Id$
 */

#import <Foundation/Foundation.h>

@interface DraggablePopoverController : UIPopoverController <UIPopoverControllerDelegate, UIGestureRecognizerDelegate>
{
@protected
    CADisplayLink* displayLink;
    UIPanGestureRecognizer* panGestureRecognizer;
    CGPoint gestureBeginPoint;
    CGPoint gestureNewPoint;
}

@property (nonatomic, readonly) CGPoint point;

@property (nonatomic, readonly) UIView* view;

@property (nonatomic, readonly) UIPopoverArrowDirection arrowDirections;

@property (nonatomic) BOOL dragEnabled;

- (void) presentPopoverFromPoint:(CGPoint)point
                          inView:(UIView*)view
        permittedArrowDirections:(UIPopoverArrowDirection)arrowDirections
                        animated:(BOOL)animated;

- (void) popoverDraggingDidBegin;

- (void) popoverDraggingDidEnd;

- (BOOL) popoverPointWillChange:(CGPoint)newPoint;

@end