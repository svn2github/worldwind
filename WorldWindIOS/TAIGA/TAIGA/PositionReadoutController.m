/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import "PositionReadoutController.h"
#import "AppConstants.h"
#import "FlightRoute.h"
#import "MovingMapViewController.h"
#import "AddWaypointController.h"
#import "WorldWind/Geometry/WWPosition.h"

@implementation PositionReadoutController

- (id) init
{
    self = [super initWithStyle:UITableViewStylePlain];

    [[self navigationItem] setTitle:@"Waypoint"];
    [[self tableView] setBounces:NO];
    [[self tableView] setSeparatorStyle:UITableViewCellSeparatorStyleNone];
    [self setPreferredContentSize:CGSizeMake(320, 128)];

    tableCells = [[NSMutableArray alloc] init];
    tableRowHeights = [[NSMutableArray alloc] init];

    return self;
}

- (void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    CGSize size = [self preferredContentSize];
    [_presentingPopoverController setPopoverContentSize:CGSizeMake(size.width, size.height + 44) animated:animated];
}

- (void) setPosition:(WWPosition*)position
{
    _position = position;

    [tableCells removeAllObjects];
    [tableRowHeights removeAllObjects];

    UITableViewCell* cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue2 reuseIdentifier:nil];
    [[cell textLabel] setText:@"Latitude"];
    [[cell textLabel] setTextAlignment:NSTextAlignmentLeft];
    [[cell detailTextLabel] setText:[NSString localizedStringWithFormat:@"%.4f\u00B0", [_position latitude]]];
    [cell setUserInteractionEnabled:NO];
    [tableCells addObject:cell];
    [tableRowHeights addObject:@28];

    cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue2 reuseIdentifier:nil];
    [[cell textLabel] setText:@"Longitude"];
    [[cell textLabel] setTextAlignment:NSTextAlignmentLeft];
    [[cell detailTextLabel] setText:[NSString localizedStringWithFormat:@"%.4f\u00B0", [_position longitude]]];
    [cell setUserInteractionEnabled:NO];
    [tableCells addObject:cell];
    [tableRowHeights addObject:@28];

    cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue2 reuseIdentifier:nil];
    [[cell textLabel] setText:@"Altitude"];
    [[cell textLabel] setTextAlignment:NSTextAlignmentLeft];
    [[cell detailTextLabel] setText:[NSString localizedStringWithFormat:@"%d feet",
                                                                        (int) ([_position altitude] * TAIGA_METERS_TO_FEET)]];
    [cell setUserInteractionEnabled:NO];
    [tableCells addObject:cell];
    [tableRowHeights addObject:@28];

    cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
    [[cell textLabel] setText:@"Add to Route"];
    [[cell textLabel] setTextColor:[cell tintColor]];
    [[cell textLabel] setTextAlignment:NSTextAlignmentCenter];
    [cell setAccessoryType:[_mapViewController presentedFlightRoute] != nil ?
            UITableViewCellAccessoryNone : UITableViewCellAccessoryDetailButton];
    [tableCells addObject:cell];
    [tableRowHeights addObject:@44];

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

- (CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [[tableRowHeights objectAtIndex:(NSUInteger) [indexPath row]] floatValue];
}

- (void) tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    // TODO: Create a waypoint from the position

    if ([indexPath row] == 3 && [[tableView cellForRowAtIndexPath:indexPath] accessoryType] == UITableViewCellAccessoryNone)
    {
        //[[_mapViewController presentedFlightRoute] addWaypoint:nil];
        //[_presentingPopoverController dismissPopoverAnimated:YES];
    }
    else if ([indexPath row] == 3)
    {
        //AddWaypointController* addController = [[AddWaypointController alloc] initWithWaypoint:nil mapViewController:_mapViewController];
        //[addController setPresentingPopoverController:_presentingPopoverController];
        //[[self navigationController] pushViewController:addController animated:YES];
    }
}

@end