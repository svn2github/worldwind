/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.

 @version $Id$
 */

#import "UIPopoverController+TAIGAAdditions.h"
#import "WorldWind/Pick/WWPickedObject.h"
#import "WorldWind/WorldWindView.h"

@implementation UIPopoverController (TAIGAAdditions)

- (void) presentPopoverFromPickedObject:(WWPickedObject*)pickedObject
                                 inView:(WorldWindView*)view
               permittedArrowDirections:(UIPopoverArrowDirection)arrowDirections
                               animated:(BOOL)animated
{
    CGPoint point = [pickedObject pickPoint];
    CGRect rect = CGRectMake(point.x, point.y, 1, 1);
    [self presentPopoverFromRect:rect inView:view permittedArrowDirections:arrowDirections animated:animated];
}

@end
