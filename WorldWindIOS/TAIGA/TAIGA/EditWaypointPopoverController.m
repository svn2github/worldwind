/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.

 @version $Id$
 */

#import "EditWaypointPopoverController.h"
#import "FlightRoute.h"
#import "Waypoint.h"
#import "MovingMapViewController.h"
#import "AltitudePicker.h"
#import "UIPopoverController+TAIGAAdditions.h"
#import "WorldWind/Geometry/WWLocation.h"
#import "WorldWind/Geometry/WWPosition.h"
#import "WorldWind/Geometry/WWVec4.h"
#import "WorldWind/Navigate/WWNavigatorState.h"
#import "WorldWind/Render/WWSceneController.h"
#import "WorldWind/Terrain/WWGlobe.h"
#import "WorldWind/Util/WWMath.h"
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
//    [[tableViewController navigationItem] setRightBarButtonItem:rightButtonItem];
    [[tableViewController tableView] setDataSource:self];
    [[tableViewController tableView] setDelegate:self];
    [[tableViewController tableView] setBounces:NO];
    [[tableViewController tableView] setSeparatorStyle:UITableViewCellSeparatorStyleNone];

    navigationController = [[UINavigationController alloc] initWithRootViewController:tableViewController];
    [navigationController setDelegate:self];

    self = [super initWithContentViewController:navigationController];

    return self;
}

- (void) showCancelButton
{
    UIBarButtonItem* cancelButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelSelected)];
    [[tableViewController navigationItem] setLeftBarButtonItem:cancelButtonItem animated:YES];
}

- (void) cancelSelected
{
    [self dismissPopoverAnimated:YES];
    [_flightRoute replaceWaypointAtIndex:_waypointIndex withWaypoint:oldWaypoint];
}

- (void) waypointSelected
{
    Waypoint* waypoint = [_flightRoute waypointAtIndex:_waypointIndex];

    AltitudePicker* picker = [[AltitudePicker alloc] initWithFrame:CGRectMake(0, 0, 320, 216)];
    [picker addTarget:self action:@selector(altitudeSelected:) forControlEvents:UIControlEventValueChanged];
    [picker setToVFRAltitudes];
    [picker setAltitude:[waypoint altitude]];

    UIViewController* viewController = [[UIViewController alloc] init];
    [viewController setPreferredContentSize:CGSizeMake(320, 216)];
    [viewController setView:picker];
    [viewController setTitle:@"Waypoint Altitude"];
    [navigationController pushViewController:viewController animated:YES];
}

- (void) altitudeSelected:(id)sender
{
    // Replace the flight route waypoint with a waypoint at the new altitude.
    Waypoint* waypoint = [_flightRoute waypointAtIndex:_waypointIndex];
    Waypoint* newWaypoint = [[Waypoint alloc] initWithWaypoint:waypoint metersAltitude:[sender altitude]];
    [_flightRoute replaceWaypointAtIndex:_waypointIndex withWaypoint:newWaypoint];

    // Update the waypoint cell to match the change in the waypoint altitude.
    [[[tableCells objectAtIndex:0] textLabel] setText:[newWaypoint descriptionWithAltitude]];
    [[tableViewController tableView] reloadData];

    // Update the popover point to match the change in the waypoint altitude.
    WWPosition* newPosition = [[WWPosition alloc] initWithDegreesLatitude:[newWaypoint latitude] longitude:[newWaypoint longitude] altitude:[newWaypoint altitude]];
    [self presentPopoverFromPosition:newPosition inView:(WorldWindView*) [self view] permittedArrowDirections:[self arrowDirections] animated:YES];

    // Display the cancel button in the left side of the navigation bar. This enables the user to undo this change.
    [self showCancelButton];
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
}

- (void) alertView:(UIAlertView*)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if ([alertView cancelButtonIndex] != buttonIndex)
    {
        [self removeConfirmed];
    }
}

- (void) popoverDraggingDidBegin
{
    [super popoverDraggingDidBegin];

    [WorldWindView startRedrawing];

    // Display the cancel button in the left side of the navigation bar. This enables the user to undo this change.
    [self showCancelButton];
}

- (void) popoverDraggingDidEnd
{
    [super popoverDraggingDidEnd];

    [WorldWindView stopRedrawing];
}

- (BOOL) popoverPointWillChange:(CGPoint)newPoint
{
    Waypoint* waypoint = [_flightRoute waypointAtIndex:_waypointIndex];
    WorldWindView* wwv = [_mapViewController wwv];
    WWGlobe* globe = [[wwv sceneController] globe];
    WWLine* ray = [[[wwv sceneController] navigatorState] rayFromScreenPoint:newPoint];
    WWVec4* point = [[WWVec4 alloc] init];

    // Compute the intersection of a ray through the popover's screen point against a larger ellipsoid that passes
    // through the waypoint altitude. This ensures that the waypoint's new location accurately tracks with the popover.
    double equatorialRadius = [globe equatorialRadius] + [waypoint altitude];
    double polarRadius = [globe polarRadius] + [waypoint altitude];
    if (![WWMath computeEllipsoidalGlobeIntersection:ray equatorialRadius:equatorialRadius polarRadius:polarRadius result:point])
    {
        return NO;
    }

    // Replace the flight route waypoint with a waypoint at the popover's new screen point. Force the new waypoint's
    // altitude to match the old waypoint altitude, as we only want to change waypoint location.
    WWPosition* pos = [[WWPosition alloc] init];
    [[[wwv sceneController] globe] computePositionFromPoint:[point x] y:[point y] z:[point z] outputPosition:pos];
    Waypoint* newWaypoint = [[Waypoint alloc] initWithDegreesLatitude:[pos latitude] longitude:[pos longitude] metersAltitude:[waypoint altitude]];
    [_flightRoute replaceWaypointAtIndex:_waypointIndex withWaypoint:newWaypoint];

    // Update the waypoint cell to match the change in the waypoint location without animating.
    NSIndexPath* indexPath = [NSIndexPath indexPathForRow:0 inSection:0];
    [[[tableCells objectAtIndex:0] textLabel] setText:[newWaypoint descriptionWithAltitude]];
    [[tableViewController tableView] reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];

    return YES;
}

//--------------------------------------------------------------------------------------------------------------------//
//-- UITableViewDataSource --//
//--------------------------------------------------------------------------------------------------------------------//

- (void) populateTableCells
{
    tableCells = [[NSMutableArray alloc] init];

    UITableViewCell* cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
    Waypoint* waypoint = [_flightRoute waypointAtIndex:_waypointIndex];
    [cell setAccessoryType:UITableViewCellAccessoryDisclosureIndicator];
    [[cell textLabel] setText:[waypoint descriptionWithAltitude]];
    [[cell textLabel] setTextAlignment:NSTextAlignmentCenter];
    [[cell textLabel] setAdjustsFontSizeToFitWidth:YES];
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
    else
    {
        [self waypointSelected];
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
    [self setDragEnabled:viewController == tableViewController];
}

@end