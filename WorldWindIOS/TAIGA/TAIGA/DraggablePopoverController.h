/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.

 @version $Id$
 */

#import <Foundation/Foundation.h>

@class WWPosition;
@class WorldWindView;

@interface DraggablePopoverController : UIPopoverController <UIGestureRecognizerDelegate>
{
@protected
    UIPanGestureRecognizer* panGestureRecognizer;
    CGPoint gestureBeginPoint;
}

@property (nonatomic, readonly) WWPosition* position;

@property (nonatomic, readonly) CGPoint point;

@property (nonatomic, readonly) WorldWindView* view;

@property (nonatomic, readonly) UIPopoverArrowDirection arrowDirections;

@property (nonatomic) BOOL dragEnabled;

- (void) presentPopoverFromPosition:(WWPosition*)position inView:(WorldWindView*)view permittedArrowDirections:(UIPopoverArrowDirection)arrowDirections animated:(BOOL)animated;

- (void) beginDrag;

- (void) endDrag;

- (void) positionDidChange;

@end