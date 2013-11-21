/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.

 @version $Id$
 */

#import <Foundation/Foundation.h>

@class Waypoint;

@interface WaypointCell : UITableViewCell
{
@protected
    UIImageView* imageView;
    UIView* displayNameView;
    UILabel* displayNameLabel;
    UILabel* displayNameLongLabel;
}

- (id) initWithReuseIdentifier:(NSString*)reuseIdentifier;

- (void) setToWaypoint:(Waypoint*)waypoint;

@end