/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.

 @version $Id$
 */

#import "AddWaypointController.h"
#import "FlightRoute.h"
#import "Waypoint.h"
#import "MovingMapViewController.h"
#import "UITableViewCell+TAIGAAdditions.h"

@implementation AddWaypointController

- (id) initWithWaypoint:(Waypoint*)waypoint mapViewController:(MovingMapViewController*)mapViewController
{
    self = [super initWithStyle:UITableViewStylePlain];

    [[self navigationItem] setTitle:@"Add Waypoint To"];
    [self setPreferredContentSize:CGSizeMake(320, 176)];

    _waypoint = waypoint;
    _mapViewController = mapViewController;

    return self;
}

- (NSInteger) tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section
{
    return [_mapViewController flightRouteCount] + 1;
}

- (UITableViewCell*) tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
    static NSString* cellIdentifier = @"cell";

    UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (cell == nil)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:cellIdentifier];
    }

    if ([indexPath row] < [_mapViewController flightRouteCount])
    {
        FlightRoute* flightRoute = [_mapViewController flightRouteAtIndex:(NSUInteger) [indexPath row]];
        [cell setToFlightRoute:flightRoute];
        [[cell imageView] setImage:nil]; // suppress the flight route enabled checkmark
    }
    else // New Route row
    {
        [[cell imageView] setImage:nil];
        [[cell textLabel] setText:@"New Route..."];
        [[cell detailTextLabel] setText:nil];
    }

    return cell;
}

- (void) tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    if ([indexPath row] < [_mapViewController flightRouteCount])
    {
        NSUInteger index = (NSUInteger) [indexPath row];
        [_presentingPopoverController dismissPopoverAnimated:YES];
        [_mapViewController presentFlightRouteAtIndex:index];
        [[_mapViewController flightRouteAtIndex:index] addWaypoint:_waypoint];
    }
    else // New Route row
    {
        [_presentingPopoverController dismissPopoverAnimated:YES];
        [_mapViewController newFlightRoute:^(FlightRoute* newFlightRoute)
        {
            [newFlightRoute addWaypoint:_waypoint];
        }];
    }
}


@end