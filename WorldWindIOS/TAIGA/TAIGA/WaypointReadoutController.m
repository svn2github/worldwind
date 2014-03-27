/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.

 @version $Id$
 */

#import "WaypointReadoutController.h"
#import "Waypoint.h"
#import "UITableViewCell+TAIGAAdditions.h"

@implementation WaypointReadoutController

- (id) init
{
    self = [super initWithStyle:UITableViewStylePlain];

    [self setPreferredContentSize:CGSizeMake(240, 88)];
    [[self navigationItem] setTitle:@"Waypoint"];
    [[self tableView] setBounces:NO];
    [[self tableView] setSeparatorStyle:UITableViewCellSeparatorStyleNone];

    tableCells = [[NSMutableArray alloc] init];

    return self;
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
        // TODO
        //[_presentingPopoverController dismissPopoverAnimated:YES];
    }
}

@end