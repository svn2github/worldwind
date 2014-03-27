/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.

 @version $Id$
 */

#import "UITableViewCell+TAIGAAdditions.h"
#import "Waypoint.h"

@implementation UITableViewCell (TAIGAAdditions)

- (void) setToWaypoint:(Waypoint*)waypoint
{
    if (waypoint == nil)
    {
        return;
    }

    [self setSeparatorInset:UIEdgeInsetsMake(0, 50, 0, 0)];
    [[self imageView] setImage:[waypoint iconImage]];
    [[self textLabel] setText:[waypoint displayName]];
    [[self textLabel] setAdjustsFontSizeToFitWidth:YES];
}

@end