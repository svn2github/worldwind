/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.

 @version $Id$
 */

#import <Foundation/Foundation.h>

@class WWPickedObject;
@class WorldWindView;

@interface UIPopoverController (TAIGAAdditions)

- (void) presentPopoverFromPickedObject:(WWPickedObject*)pickedObject
                                 inView:(WorldWindView*)view
               permittedArrowDirections:(UIPopoverArrowDirection)arrowDirections
                               animated:(BOOL)animated;

@end
