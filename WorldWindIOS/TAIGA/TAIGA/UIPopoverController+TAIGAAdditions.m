/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.

 @version $Id$
 */

#import "UIPopoverController+TAIGAAdditions.h"
#import "WorldWind/Geometry/WWPosition.h"
#import "WorldWind/Geometry/WWVec4.h"
#import "WorldWind/Navigate/WWNavigatorState.h"
#import "WorldWind/Render/WWSceneController.h"
#import "WorldWind/Terrain/WWGlobe.h"
#import "WorldWind/WorldWindView.h"

@implementation UIPopoverController (TAIGAAdditions)

- (void) presentPopoverFromPosition:(WWPosition*)position
                             inView:(WorldWindView*)view
           permittedArrowDirections:(UIPopoverArrowDirection)arrowDirections
                           animated:(BOOL)animated
{
    WWVec4* modelPoint = [[WWVec4 alloc] init];
    [[[view sceneController] globe] computePointFromPosition:[position latitude] longitude:[position longitude]
                                                    altitude:[position altitude] outputPoint:modelPoint];

    WWVec4* screenPoint = [[WWVec4 alloc] init];
    [[[view sceneController] navigatorState] project:modelPoint result:screenPoint];

    CGPoint uiPoint = [[[view sceneController] navigatorState] convertPointToView:screenPoint];
    CGRect uiRect = CGRectMake(uiPoint.x, uiPoint.y, 1, 1);

    [self presentPopoverFromRect:uiRect inView:view permittedArrowDirections:arrowDirections animated:animated];
}

@end
