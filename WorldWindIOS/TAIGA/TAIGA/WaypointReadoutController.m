/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.

 @version $Id$
 */

#import "WaypointReadoutController.h"
#import "Waypoint.h"
#import "FlightRoute.h"
#import "MovingMapViewController.h"
#import "AddWaypointController.h"
#import "UITableViewCell+TAIGAAdditions.h"

@implementation WaypointReadoutController

- (id) init
{
    self = [super initWithStyle:UITableViewStylePlain];

    [[self navigationItem] setTitle:@"Waypoint"];
    [[self tableView] setBounces:NO];
    [[self tableView] setSeparatorStyle:UITableViewCellSeparatorStyleNone];
    [self setPreferredContentSize:CGSizeMake(320, 88)];

    tableCells = [[NSMutableArray alloc] init];

    return self;
}

- (void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    CGSize size = [self preferredContentSize];
    [_presentingPopoverController setPopoverContentSize:CGSizeMake(size.width, size.height + 44) animated:animated];
}

- (void) setWaypoint:(Waypoint*)waypoint
{
    _waypoint = waypoint;

    [tableCells removeAllObjects];

    UITableViewCell* cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
    [cell setToWaypoint:_waypoint];
    [cell setUserInteractionEnabled:NO];
    [tableCells addObject:cell];

    cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
    [[cell textLabel] setText:@"Add to Route"];
    [[cell textLabel] setTextColor:[cell tintColor]];
    [[cell textLabel] setTextAlignment:NSTextAlignmentCenter];
    [cell setAccessoryType:[_mapViewController presentedFlightRoute] != nil ?
            UITableViewCellAccessoryNone : UITableViewCellAccessoryDetailButton];
    [tableCells addObject:cell];

    [[self tableView] reloadData];
}

- (NSInteger) tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section
{
    return [tableCells count];
}

- (UITableViewCell*) tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
    return [tableCells objectAtIndex:(NSUInteger) [indexPath row]];
}

- (void) tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    if ([indexPath row] == 1)
    {
        if ([[tableView cellForRowAtIndexPath:indexPath] accessoryType] == UITableViewCellAccessoryNone)
        {
            [_presentingPopoverController dismissPopoverAnimated:YES];
            [[_mapViewController presentedFlightRoute] addWaypoint:_waypoint];
        }
        else
        {
            AddWaypointController* addController = [[AddWaypointController alloc] initWithWaypoint:_waypoint mapViewController:_mapViewController];
            [addController setPresentingPopoverController:_presentingPopoverController];
            [[self navigationController] pushViewController:addController animated:YES];
        }
    }
}

@end