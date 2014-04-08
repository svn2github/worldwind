/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.

 @version $Id$
 */

#import "EditWaypointPopoverController.h"
#import "FlightRoute.h"
#import "MovingMapViewController.h"
#import "UITableViewCell+TAIGAAdditions.h"

static NSString* EditWaypointActionDone = @"Done";
static NSString* EditWaypointActionMove = @"Move Waypoint";
static NSString* EditWaypointActionRemove = @"Remove Waypoint";
static NSString* EditWaypointActionUndo = @"Undo";

@implementation EditWaypointPopoverController

- (id) initWithFlightRoute:(FlightRoute*)flightRoute waypointIndex:(NSUInteger)waypointIndex mapViewController:(MovingMapViewController*)mapViewController
{
    BOOL isEditing = [mapViewController isEditingFlightRoute:flightRoute waypointAtIndex:waypointIndex];

    tableViewController = [[UITableViewController alloc] initWithStyle:UITableViewStylePlain];
    [tableViewController setPreferredContentSize:CGSizeMake(240, isEditing ? 176 : 132)];
    [[tableViewController navigationItem] setTitle:[flightRoute displayName]];
    [[tableViewController tableView] setDataSource:self];
    [[tableViewController tableView] setDelegate:self];
    [[tableViewController tableView] setBounces:NO];
    [[tableViewController tableView] setSeparatorStyle:UITableViewCellSeparatorStyleNone];
    navigationController = [[UINavigationController alloc] initWithRootViewController:tableViewController];

    self = [super initWithContentViewController:navigationController];

    _flightRoute = flightRoute;
    _waypointIndex = waypointIndex;
    _mapViewController = mapViewController;

    [self populateTableCells];
    [self setDelegate:self];

    return self;
}

- (void) doneSelected
{
    [self dismissPopoverAnimated:YES];
    [_mapViewController endEditingFlightRoute:YES]; // end editing and keep the changes
}

- (void) moveSelected
{
    [self dismissPopoverAnimated:YES];
    [_mapViewController beginEditingFlightRoute:_flightRoute waypointAtIndex:_waypointIndex];
}

- (void) removeSelected
{
    UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:EditWaypointActionRemove
                                                        message:nil
                                                       delegate:self
                                              cancelButtonTitle:@"Cancel"
                                              otherButtonTitles:@"Remove", nil];
    [alertView show];
}

- (void) undoSelected
{
    [self dismissPopoverAnimated:YES];
    [_mapViewController endEditingFlightRoute:NO]; // end editing and discard the changes
}

- (void) popoverControllerDidDismissPopover:(UIPopoverController*)popoverController
{
    // End editing and keep the changes when the user soft-dismisses this popover. Note that this method is not called
    // when dismissPopoverAnimated is called directly.
    if ([_mapViewController isEditingFlightRoute:_flightRoute waypointAtIndex:_waypointIndex])
    {
        [_mapViewController endEditingFlightRoute:YES];
    }
}

- (void) alertView:(UIAlertView*)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if ([alertView cancelButtonIndex] != buttonIndex) // Remove button tapped
    {
        [self dismissPopoverAnimated:YES];
        [_flightRoute removeWaypointAtIndex:_waypointIndex];
    }
}

//--------------------------------------------------------------------------------------------------------------------//
//-- UITableViewDataSource --//
//--------------------------------------------------------------------------------------------------------------------//

- (void) populateTableCells
{
    tableCells = [[NSMutableArray alloc] init];

    UITableViewCell* cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
    [cell setToWaypoint:[_flightRoute waypointAtIndex:_waypointIndex]];
    [cell setUserInteractionEnabled:NO];
    [tableCells addObject:cell];

    if ([_mapViewController isEditingFlightRoute:_flightRoute waypointAtIndex:_waypointIndex])
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
        [[cell textLabel] setText:EditWaypointActionDone];
        [[cell textLabel] setTextColor:[cell tintColor]];
        [[cell textLabel] setTextAlignment:NSTextAlignmentCenter];
        [tableCells addObject:cell];

        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
        [[cell textLabel] setText:EditWaypointActionUndo];
        [[cell textLabel] setTextColor:[cell tintColor]];
        [[cell textLabel] setTextAlignment:NSTextAlignmentCenter];
        [tableCells addObject:cell];
    }
    else
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
        [[cell textLabel] setText:EditWaypointActionMove];
        [[cell textLabel] setTextColor:[cell tintColor]];
        [[cell textLabel] setTextAlignment:NSTextAlignmentCenter];
        [tableCells addObject:cell];
    }

    cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
    [[cell textLabel] setText:EditWaypointActionRemove];
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
    UITableViewCell* cell = [tableView cellForRowAtIndexPath:indexPath];
    NSString* cellText = [[cell textLabel] text];

    if ([cellText isEqual:EditWaypointActionDone])
    {
        [self doneSelected];
    }
    else if ([cellText isEqual:EditWaypointActionMove])
    {
        [self moveSelected];
    }
    else if ([cellText isEqual:EditWaypointActionRemove])
    {
        [self removeSelected];
    }
    else if ([cellText isEqual:EditWaypointActionUndo])
    {
        [self undoSelected];
    }
}

@end