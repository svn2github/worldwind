/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.

 @version $Id$
 */

#import "AnyGestureRecognizer.h"
#import <UIKit/UIGestureRecognizerSubclass.h>

@implementation AnyGestureRecognizer

- (void) touchesBegan:(NSSet*)touches withEvent:(UIEvent*)event
{
    [super touchesBegan:touches withEvent:event];
    [self setState:UIGestureRecognizerStateBegan];
}

- (void) touchesMoved:(NSSet*)touches withEvent:(UIEvent*)event
{
    [super touchesMoved:touches withEvent:event];
    [self setState:UIGestureRecognizerStateChanged];
}

- (void) touchesEnded:(NSSet*)touches withEvent:(UIEvent*)event
{
    [super touchesEnded:touches withEvent:event];
    [self setState:UIGestureRecognizerStateEnded];
}

- (void) touchesCancelled:(NSSet*)touches withEvent:(UIEvent*)event
{
    [super touchesCancelled:touches withEvent:event];
    [self setState:UIGestureRecognizerStateCancelled];
}


@end