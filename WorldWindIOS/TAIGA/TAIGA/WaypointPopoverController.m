/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.

 @version $Id$
 */

#import "WaypointPopoverController.h"
#import "Waypoint.h"
#import "WaypointCell.h"
#import "FlightRoute.h"
#import "WorldWind/Pick/WWPickedObject.h"

@implementation WaypointPopoverController

- (id) init
{
    self = [self initWithContentViewController:[[UITableViewController alloc] initWithStyle:UITableViewStylePlain]];

    UITableView* tableView = [(UITableViewController*) [self contentViewController] tableView];
    [tableView setDataSource:self];
    [tableView setDelegate:self];
    [tableView setBounces:NO];

    tableCells = [[NSMutableArray alloc] init];

    return self;
}

- (void) presentPopoverFromPickedObject:(WWPickedObject*)po inView:(UIView*)view
               permittedArrowDirections:(UIPopoverArrowDirection)arrowDirections animated:(BOOL)animated
{
    [tableCells removeAllObjects];
    pickedObject = po;

    WaypointCell* waypointCell = [[WaypointCell alloc] initWithReuseIdentifier:nil];
    [waypointCell setToWaypoint:[pickedObject userObject]];
    [waypointCell setUserInteractionEnabled:NO];
    [tableCells addObject:waypointCell];

    if (_activeFlightRoute != nil)
    {
        NSString* text = [_activeFlightRoute containsWaypoint:[po userObject]] ? @"Remove from Flight Route" : @"Add To Flight Route";
        UITableViewCell* addToRouteCell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
        [[addToRouteCell textLabel] setText:text];
        [[addToRouteCell textLabel] setTextColor:[[[self contentViewController] view] tintColor]];
        [addToRouteCell setSeparatorInset:[waypointCell separatorInset]];
        [tableCells addObject:addToRouteCell];
    }

    UITableView* tableView = [(UITableViewController*) [self contentViewController] tableView];
    [self setPopoverContentSize:CGSizeMake(320, [tableView rowHeight] * [tableCells count])];
    [tableView setSeparatorStyle:[tableCells count] == 1 ? UITableViewCellSeparatorStyleNone : UITableViewCellSeparatorStyleSingleLine];
    [tableView reloadData];

    CGPoint point = [pickedObject pickPoint];
    CGRect rect = CGRectMake(point.x, point.y, 1, 1);
    [super presentPopoverFromRect:rect inView:view permittedArrowDirections:arrowDirections animated:animated];
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
        NSString* cellText = [[[tableView cellForRowAtIndexPath:indexPath] textLabel] text];
        if ([cellText hasPrefix:@"Add"])
        {
            [_activeFlightRoute addWaypoint:[pickedObject userObject]];
        }
        else if ([cellText hasPrefix:@"Remove"])
        {
            [_activeFlightRoute removeWaypoint:[pickedObject userObject]];
        }

        [self dismissPopoverAnimated:YES];
    }
}

@end