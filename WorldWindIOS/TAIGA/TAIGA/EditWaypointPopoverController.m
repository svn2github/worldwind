/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.

 @version $Id$
 */

#import "EditWaypointPopoverController.h"
#import "MovingMapViewController.h"
#import "Waypoint.h"
#import "FlightRoute.h"
#import "UITableViewCell+TAIGAAdditions.h"

@implementation EditWaypointPopoverController

- (id) initWithWaypoint:(Waypoint*)waypoint flightRoute:(FlightRoute*)flightRoute mapViewController:(MovingMapViewController*)mapViewController
{
    tableViewController = [[UITableViewController alloc] initWithStyle:UITableViewStylePlain];
    [tableViewController setPreferredContentSize:CGSizeMake(240, 88)];
    [[tableViewController navigationItem] setTitle:[flightRoute displayName]];
    [[tableViewController tableView] setDataSource:self];
    [[tableViewController tableView] setDelegate:self];
    [[tableViewController tableView] setBounces:NO];
    [[tableViewController tableView] setSeparatorStyle:UITableViewCellSeparatorStyleNone];
    navigationController = [[UINavigationController alloc] initWithRootViewController:tableViewController];

    self = [super initWithContentViewController:navigationController];

    _waypoint = waypoint;
    _flightRoute = flightRoute;
    _mapViewController = mapViewController;

    [self populateTableCells];

    return self;
}

- (void) removeFromRouteRowTapped
{
    [self dismissPopoverAnimated:YES];
    [_flightRoute removeWaypoint:_waypoint];
}

//--------------------------------------------------------------------------------------------------------------------//
//-- UITableViewDataSource --//
//--------------------------------------------------------------------------------------------------------------------//

- (void) populateTableCells
{
    tableCells = [[NSMutableArray alloc] init];

    UITableViewCell* cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
    [cell setToWaypoint:_waypoint];
    [cell setUserInteractionEnabled:NO];
    [tableCells addObject:cell];

    cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
    [[cell textLabel] setText:@"Remove from Route"];
    [[cell textLabel] setTextColor:[UIColor redColor]];
    [[cell textLabel] setTextAlignment:NSTextAlignmentCenter];
    [tableCells addObject:cell];
}

- (NSInteger) tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section
{
    return [tableCells count];
}

- (UITableViewCell*) tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
    return [tableCells objectAtIndex:(NSUInteger) [indexPath row]];
}

//--------------------------------------------------------------------------------------------------------------------//
//-- UITableViewDelegate --//
//--------------------------------------------------------------------------------------------------------------------//

- (void) tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    if ([indexPath row] == 1) // Remove from Route row tapped
    {
        [self removeFromRouteRowTapped];
    }
}

@end