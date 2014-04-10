/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.

 @version $Id$
 */

#import "EditWaypointPopoverController.h"
#import "FlightRoute.h"
#import "MutableWaypoint.h"
#import "WaypointDatabase.h"
#import "MovingMapViewController.h"
#import "UITableViewCell+TAIGAAdditions.h"
#import "TAIGA.h"
#import "UnitsFormatter.h"
#import "WorldWind/Geometry/WWLocation.h"
#import "WorldWind/Geometry/WWPosition.h"
#import "WorldWind/Geometry/WWVec4.h"
#import "WorldWind/Navigate/WWNavigatorState.h"
#import "WorldWind/Render/WWSceneController.h"
#import "WorldWind/Terrain/WWGlobe.h"
#import "WorldWind/WorldWindView.h"

static NSString* EditWaypointActionRemove = @"Remove Waypoint";

@implementation EditWaypointPopoverController

- (id) initWithFlightRoute:(FlightRoute*)flightRoute waypointIndex:(NSUInteger)waypointIndex mapViewController:(MovingMapViewController*)mapViewController
{
    _flightRoute = flightRoute;
    _waypointIndex = waypointIndex;
    _mapViewController = mapViewController;
    oldWaypoint = [flightRoute waypointAtIndex:waypointIndex];
    [self populateTableCells];

    UIImage* rightButtonImage = [UIImage imageNamed:@"all-directions"];
    UIBarButtonItem* rightButtonItem = [[UIBarButtonItem alloc] initWithImage:rightButtonImage style:UIBarButtonItemStylePlain target:nil action:NULL];
    tableViewController = [[UITableViewController alloc] initWithStyle:UITableViewStylePlain];
    [tableViewController setPreferredContentSize:CGSizeMake(240, 44 * [tableCells count])];
    [[tableViewController navigationItem] setTitle:@"Waypoint"];
    [[tableViewController navigationItem] setRightBarButtonItem:rightButtonItem];
    [[tableViewController tableView] setDataSource:self];
    [[tableViewController tableView] setDelegate:self];
    [[tableViewController tableView] setBounces:NO];
    [[tableViewController tableView] setSeparatorStyle:UITableViewCellSeparatorStyleNone];
    navigationController = [[UINavigationController alloc] initWithRootViewController:tableViewController];
    cancelButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelSelected)];

    self = [super initWithContentViewController:navigationController];
    [self setDelegate:self];

    return self;
}

- (void) cancelSelected
{
    [self dismissPopoverAnimated:YES];
    [self rejectChanges];
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

- (void) removeConfirmed
{
    [self dismissPopoverAnimated:YES];
    [_flightRoute removeWaypointAtIndex:_waypointIndex];
    // TODO: Remove marker waypoints from the waypoint database.
}

- (void) alertView:(UIAlertView*)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if ([alertView cancelButtonIndex] != buttonIndex)
    {
        [self removeConfirmed];
    }
}

- (void) popoverControllerDidDismissPopover:(UIPopoverController*)popoverController
{
    // End editing and keep the changes when the user soft-dismisses this popover. Note that this method is not called
    // when dismissPopoverAnimated is called directly.
    [self commitChanges];
}

- (void) commitChanges
{
    if (newWaypoint != nil)
    {
        // TODO: Remove old marker waypoints from the waypoint database.
        [[_mapViewController waypointDatabase] addWaypoint:newWaypoint];
    }
}

- (void) rejectChanges
{
    if (newWaypoint != nil)
    {
        [_flightRoute replaceWaypointAtIndex:_waypointIndex withWaypoint:oldWaypoint];
    }
}

- (void) popoverDraggingDidBegin
{
    // TODO: Review this logic for a potential bug where the newWaypoint state is not saved.
    if (newWaypoint == nil)
    {
        newWaypoint = [[MutableWaypoint alloc] initWithType:WaypointTypeMarker
                                            degreesLatitude:[oldWaypoint latitude]
                                                  longitude:[oldWaypoint longitude]];
        [_flightRoute replaceWaypointAtIndex:_waypointIndex withWaypoint:newWaypoint];

        // Make the waypoint cell match the change in the waypoint. Use UIKit animations to display the change smoothly.
        NSIndexPath* indexPath = [NSIndexPath indexPathForRow:0 inSection:0];
        NSArray* indexPathArray = [NSArray arrayWithObject:indexPath];
        [[tableCells objectAtIndex:0] setToWaypoint:newWaypoint];
        [[tableViewController tableView] reloadRowsAtIndexPaths:indexPathArray
                                               withRowAnimation:UITableViewRowAnimationAutomatic];

        // Display the cancel button in the left side of the navigation bar.
        [[tableViewController navigationItem] setLeftBarButtonItem:cancelButtonItem animated:YES];
    }

    [WorldWindView startRedrawing];
}

- (void) popoverDraggingDidEnd
{
    [WorldWindView stopRedrawing];
}

- (BOOL) popoverPointWillChange:(CGPoint)newPoint
{
    WorldWindView* wwv = [_mapViewController wwv];
    WWLine* ray = [[[wwv sceneController] navigatorState] rayFromScreenPoint:newPoint];
    WWVec4* point = [[WWVec4 alloc] init];

    // TODO: Intersect against a larger ellipsoid that passes through the waypoint altitude.
    if (![[[wwv sceneController] globe] intersectWithRay:ray result:point])
    {
        return NO;
    }

    WWPosition* pos = [[WWPosition alloc] init];
    [[[wwv sceneController] globe] computePositionFromPoint:[point x] y:[point y] z:[point z] outputPosition:pos];
    [newWaypoint setDegreesLatitude:[pos latitude] longitude:[pos longitude]];
    [newWaypoint setDisplayName:[[TAIGA unitsFormatter] formatDegreesLatitude:[pos latitude] longitude:[pos longitude]]];
    [_flightRoute updateWaypointAtIndex:_waypointIndex];

    // Make the waypoint cell match the change in the waypoint. Use UIKit animations to display the change instantly.
    NSIndexPath* indexPath = [NSIndexPath indexPathForRow:0 inSection:0];
    NSArray* indexPathArray = [NSArray arrayWithObject:indexPath];
    [[tableCells objectAtIndex:0] setToWaypoint:newWaypoint];
    [[tableViewController tableView] reloadRowsAtIndexPaths:indexPathArray withRowAnimation:UITableViewRowAnimationNone];

    return YES;
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

    NSString* cellText = [[[tableView cellForRowAtIndexPath:indexPath] textLabel] text];
    if ([cellText isEqual:EditWaypointActionRemove])
    {
        [self removeSelected];
    }

}

@end