/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.

 @version $Id$
 */

#import "AddWaypointPopoverController.h"
#import "Waypoint.h"
#import "FlightRoute.h"
#import "MovingMapViewController.h"
#import "UITableViewCell+TAIGAAdditions.h"
#import "WaypointDatabase.h"

@implementation AddWaypointPopoverController

- (id) initWithWaypoint:(Waypoint*)waypoint mapViewController:(MovingMapViewController*)mapViewController
{
    addWaypointController = [[UITableViewController alloc] initWithStyle:UITableViewStylePlain];
    [addWaypointController setPreferredContentSize:CGSizeMake(320, 88)];
    [[addWaypointController navigationItem] setTitle:@"Waypoint"];
    [[addWaypointController tableView] setDataSource:self];
    [[addWaypointController tableView] setDelegate:self];
    [[addWaypointController tableView] setBounces:NO];
    [[addWaypointController tableView] setSeparatorStyle:UITableViewCellSeparatorStyleNone];

    flightRouteChooser = [[UITableViewController alloc] initWithStyle:UITableViewStylePlain];
    [flightRouteChooser setPreferredContentSize:CGSizeMake(320, 176)];
    [[flightRouteChooser navigationItem] setTitle:@"Add Waypoint To"];
    [[flightRouteChooser tableView] setDataSource:self];
    [[flightRouteChooser tableView] setDelegate:self];

    navigationController = [[UINavigationController alloc] initWithRootViewController:addWaypointController];
    [navigationController setDelegate:self];

    self = [super initWithContentViewController:navigationController];

    _waypoint = waypoint;
    _mapViewController = mapViewController;

    [self populateAddWaypointTable];
    [self populateFlightRouteTable];

    return self;
}

- (void) addToRouteRowTapped
{
    if ([_mapViewController presentedFlightRoute] != nil)
    {
        [self doAddToRoute:[_mapViewController presentedFlightRoute]];
    }
    else
    {
        [navigationController pushViewController:flightRouteChooser animated:YES];
    }
}

- (void) flightRouteTapped:(NSUInteger)index
{
    [self doAddToRoute:[_mapViewController flightRouteAtIndex:index]];
    [_mapViewController presentFlightRouteAtIndex:index editing:NO];
}

- (void) newFlightRouteTapped
{
    [_mapViewController newFlightRoute:^(FlightRoute* newFlightRoute)
    {
        NSUInteger index = (NSUInteger) [_mapViewController flightRouteCount];
        [_mapViewController insertFlightRoute:newFlightRoute atIndex:index]; // append to the end of the route list
        [_mapViewController presentFlightRouteAtIndex:index editing:YES]; // create new routes in editing mode
        [self doAddToRoute:newFlightRoute];
    }];
}

- (void) doAddToRoute:(FlightRoute*)flightRoute
{
    [self dismissPopoverAnimated:YES];
    [flightRoute addWaypoint:_waypoint];

    if (_addWaypointToDatabase)
    {
        [[_mapViewController waypointDatabase] addWaypoint:_waypoint];
    }
}

//--------------------------------------------------------------------------------------------------------------------//
//-- UITableViewDataSource --//
//--------------------------------------------------------------------------------------------------------------------//

- (void) populateAddWaypointTable
{
    addWaypointTableCells = [[NSMutableArray alloc] init];

    UITableViewCell* cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
    [cell setToWaypoint:_waypoint];
    [cell setUserInteractionEnabled:NO];
    [addWaypointTableCells addObject:cell];

    cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
    [[cell textLabel] setText:@"Add to Route"];
    [[cell textLabel] setTextColor:[cell tintColor]];
    [[cell textLabel] setTextAlignment:NSTextAlignmentCenter];
    [addWaypointTableCells addObject:cell];
}

- (void) populateFlightRouteTable
{
    flightRouteTableCells = [[NSMutableArray alloc] init];

    for (NSUInteger index = 0; index < [_mapViewController flightRouteCount]; index++)
    {
        FlightRoute* flightRoute = [_mapViewController flightRouteAtIndex:index];
        UITableViewCell* cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:nil];
        [cell setToFlightRoute:flightRoute];
        [[cell imageView] setImage:nil]; // suppress the flight route enabled checkmark
        [flightRouteTableCells addObject:cell];
    }

    UITableViewCell* cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
    [[cell textLabel] setText:@"New Route..."];
    [flightRouteTableCells addObject:cell];
}

- (NSInteger) tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section
{
    if (tableView == [addWaypointController tableView])
    {
        return [addWaypointTableCells count];
    }
    else // flightRouteChooser
    {
        return [flightRouteTableCells count];
    }
}

- (UITableViewCell*) tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
    if (tableView == [addWaypointController tableView])
    {
        return [addWaypointTableCells objectAtIndex:(NSUInteger) [indexPath row]];
    }
    else // flightRouteChooser
    {
        return [flightRouteTableCells objectAtIndex:(NSUInteger) [indexPath row]];
    }
}

//--------------------------------------------------------------------------------------------------------------------//
//-- UITableViewDelegate --//
//--------------------------------------------------------------------------------------------------------------------//

- (void) tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    if (tableView == [addWaypointController tableView] && [indexPath row] == 1) // Add to Route row tapped
    {
        [self addToRouteRowTapped];
    }
    else if (tableView == [flightRouteChooser tableView] && [indexPath row] < [_mapViewController flightRouteCount]) // Flight route row tapped
    {
        [self flightRouteTapped:(NSUInteger) [indexPath row]];
    }
    else if (tableView == [flightRouteChooser tableView]) // New Route row tapped
    {
        [self newFlightRouteTapped];
    }
}

//--------------------------------------------------------------------------------------------------------------------//
//-- UINavigationControllerDelegate --//
//--------------------------------------------------------------------------------------------------------------------//

- (void) navigationController:(UINavigationController*)navController didShowViewController:(UIViewController*)viewController animated:(BOOL)animated
{
    CGSize viewSize = [viewController preferredContentSize];
    CGSize navBarSize = [navController navigationBar].bounds.size;
    [self setPopoverContentSize:CGSizeMake(viewSize.width, viewSize.height + navBarSize.height) animated:animated];
}

@end