/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.

 @version $Id$
 */

#import "UITableViewCell+TAIGAAdditions.h"
#import "FlightRoute.h"
#import "Waypoint.h"
#import "TAIGA.h"
#import "UnitsFormatter.h"
#import "WorldWind/Geometry/WWLocation.h"
#import "WorldWind/Geometry/WWPosition.h"
#import "WorldWind/Util/WWColor.h"

@implementation UITableViewCell (TAIGAAdditions)

- (void) setToLocation:(WWLocation*)location
{
    if (location == nil)
    {
        return;
    }

    NSString* text = [[TAIGA unitsFormatter] formatDegreesLatitude:[location latitude] longitude:[location longitude]];
    [self setSeparatorInset:UIEdgeInsetsZero];
    [[self imageView] setImage:nil];
    [[self textLabel] setText:text];
    [[self textLabel] setTextAlignment:NSTextAlignmentCenter];
    [[self textLabel] setAdjustsFontSizeToFitWidth:YES];
    [[self detailTextLabel] setText:nil];
}

- (void) setToPosition:(WWPosition*)position
{
    if (position == nil)
    {
        return;
    }

    NSString* text = [[TAIGA unitsFormatter] formatDegreesLatitude:[position latitude] longitude:[position longitude] metersAltitude:[position altitude]];
    [self setSeparatorInset:UIEdgeInsetsZero];
    [[self imageView] setImage:nil];
    [[self textLabel] setText:text];
    [[self textLabel] setTextAlignment:NSTextAlignmentCenter];
    [[self textLabel] setAdjustsFontSizeToFitWidth:YES];
    [[self detailTextLabel] setText:nil];
}

- (void) setToFlightRoute:(FlightRoute*)flightRoute
{
    if (flightRoute == nil)
    {
        return;
    }

    NSDictionary* colorAttrs = [[FlightRoute flightRouteColors] objectAtIndex:[flightRoute colorIndex]];

    [[self imageView] setImage:[UIImage imageNamed:@"431-yes.png"]];
    [[self imageView] setHidden:![flightRoute enabled]];
    [[self textLabel] setText:[flightRoute displayName]];
    [[self textLabel] setAdjustsFontSizeToFitWidth:YES];
    [[self detailTextLabel] setText:[colorAttrs objectForKey:@"displayName"]];
    [[self detailTextLabel] setTextColor:[[colorAttrs objectForKey:@"color"] uiColor]];
}

- (void) setToWaypoint:(Waypoint*)waypoint
{
    if (waypoint == nil)
    {
        return;
    }

    [self setSeparatorInset:UIEdgeInsetsMake(0, 50, 0, 0)];
    [[self imageView] setImage:[waypoint iconImage]];
    [[self textLabel] setText:[waypoint displayName]];
    [[self textLabel] setTextAlignment:NSTextAlignmentLeft];
    [[self textLabel] setAdjustsFontSizeToFitWidth:YES];
    [[self detailTextLabel] setText:[[TAIGA unitsFormatter] formatMetersAltitude:[waypoint altitude]]];
}

@end