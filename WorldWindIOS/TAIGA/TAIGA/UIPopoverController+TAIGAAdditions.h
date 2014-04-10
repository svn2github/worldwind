/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.

 @version $Id$
 */

#import <Foundation/Foundation.h>

@class WorldWindView;
@class WWPosition;

@interface UIPopoverController (TAIGAAdditions)

- (void) presentPopoverFromPoint:(CGPoint)point
                          inView:(UIView*)view
        permittedArrowDirections:(UIPopoverArrowDirection)arrowDirections
                        animated:(BOOL)animated;

- (void) presentPopoverFromPosition:(WWPosition*)position
                             inView:(WorldWindView*)view
           permittedArrowDirections:(UIPopoverArrowDirection)arrowDirections
                           animated:(BOOL)animated;

@end
