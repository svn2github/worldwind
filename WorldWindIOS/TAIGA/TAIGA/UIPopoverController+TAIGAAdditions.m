/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.

 @version $Id$
 */

#import "UIPopoverController+TAIGAAdditions.h"
#import "WorldWind/Geometry/WWPosition.h"
#import "WorldWind/WorldWindView.h"

@implementation UIPopoverController (TAIGAAdditions)

- (void) presentPopoverFromPoint:(CGPoint)point
                          inView:(UIView*)view
        permittedArrowDirections:(UIPopoverArrowDirection)arrowDirections
                        animated:(BOOL)animated
{
    CGRect rect = CGRectMake(point.x, point.y, 1, 1);
    [self presentPopoverFromRect:rect inView:view permittedArrowDirections:arrowDirections animated:animated];
}

- (void) presentPopoverFromPosition:(WWPosition*)position
                             inView:(WorldWindView*)view
           permittedArrowDirections:(UIPopoverArrowDirection)arrowDirections
                           animated:(BOOL)animated
{
    CGPoint point;
    if ([view convertPosition:position toPoint:&point])
    {
        [self presentPopoverFromPoint:point inView:view permittedArrowDirections:arrowDirections animated:animated];
    }
}

@end
