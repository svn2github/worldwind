/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.

 @version $Id$
 */

#import "FlightRouteController.h"
#import "FlightRouteDetailController.h"
#import "FlightRoute.h"
#import "Waypoint.h"
#import "WaypointDatabase.h"
#import "AppConstants.h"
#import "WorldWind/Layer/WWRenderableLayer.h"
#import "WorldWind/WorldWindView.h"
#import "WorldWind/WWLog.h"
#import "UITableViewCell+TAIGAAdditions.h"

@implementation FlightRouteController

//--------------------------------------------------------------------------------------------------------------------//
//-- Initializing FlightRouteController --//
//--------------------------------------------------------------------------------------------------------------------//

- (FlightRouteController*) initWithWorldWindView:(WorldWindView*)wwv waypointDatabase:(WaypointDatabase*)waypointDatabase
{
    self = [super initWithStyle:UITableViewStylePlain];

    _displayName = @"Flight Routes";
    _enabled = YES;
    _wwv = wwv;
    _waypointDatabase = waypointDatabase;

    flightRoutes = [[NSMutableArray alloc] init];

    UIBarButtonItem* addButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd
                                                                                   target:self
                                                                                   action:@selector(addButtonItemTapped)];
    [[self navigationItem] setTitle:@"Flight Routes"];
    [[self navigationItem] setLeftBarButtonItem:addButtonItem];
    [[self navigationItem] setRightBarButtonItem:[self editButtonItem]];
    [[self tableView] setSeparatorStyle:UITableViewCellSeparatorStyleNone];
    [self setPreferredContentSize:CGSizeMake(350, 1000)];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleFlightRouteNotification:)
                                                 name:TAIGA_FLIGHT_ROUTE_CHANGED object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleFlightRouteNotification:)
                                                 name:TAIGA_FLIGHT_ROUTE_WAYPOINT_INSERTED object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleFlightRouteNotification:)
                                                 name:TAIGA_FLIGHT_ROUTE_WAYPOINT_REMOVED object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleFlightRouteNotification:)
                                                 name:TAIGA_FLIGHT_ROUTE_WAYPOINT_MOVED object:nil];

    return self;
}

- (void) addButtonItemTapped
{
    // Create a new flight route using a user-specified display name, then present its detail view.
    [self newFlightRoute:^(FlightRoute* newFlightRoute)
    {
        NSUInteger index = (NSUInteger) [self flightRouteCount];
        [self insertFlightRoute:newFlightRoute atIndex:index];
        [self presentFlightRouteAtIndex:index editing:YES];
    }];
}

- (void) navigationController:(UINavigationController*)navigationController
       willShowViewController:(UIViewController*)viewController
                     animated:(BOOL)animated
{
    // This keeps all the nested popover controllers the same size as this top-level controller.
    viewController.preferredContentSize = navigationController.topViewController.view.frame.size;
}

- (void) handleFlightRouteNotification:(NSNotification*)notification
{
    FlightRoute* flightRoute = [notification object];

    // Ignore notifications for flight routes not in this controller's layer. This also avoids saving state or
    // refreshing the screen for during flight route initialization or restoration.
    if ([flightRoutes containsObject:flightRoute])
    {
        [self flightRouteDidChange:flightRoute];
    }
}

//--------------------------------------------------------------------------------------------------------------------//
//-- Managing the Flight Route List --//
//--------------------------------------------------------------------------------------------------------------------//

- (NSUInteger) flightRouteCount
{
    return [flightRoutes count];
}

- (FlightRoute*) flightRouteAtIndex:(NSUInteger)index
{
    return [flightRoutes objectAtIndex:index];
}

- (NSUInteger) indexOfFlightRoute:(FlightRoute*)flightRoute
{
    if (flightRoute == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Flight route is nil")
    }

    return [flightRoutes indexOfObject:flightRoute];
}

- (BOOL) containsFlightRoute:(FlightRoute*)flightRoute
{
    if (flightRoute == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Flight route is nil")
    }

    return [flightRoutes containsObject:flightRoute];
}

- (void) addFlightRoute:(FlightRoute*)flightRoute
{
    if (flightRoute == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Flight route is nil")
    }

    NSUInteger index = [flightRoutes count];
    [flightRoutes insertObject:flightRoute atIndex:index];
    [self didInsertFlightRoute:flightRoute atIndex:index];
}

- (void) insertFlightRoute:(FlightRoute*)flightRoute atIndex:(NSUInteger)index
{
    if (flightRoute == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Flight route is nil")
    }

    if (index > [flightRoutes count])
    {
        NSString* msg = [[NSString alloc] initWithFormat:@"Index %d is out of range", index];
        WWLOG_AND_THROW(NSInvalidArgumentException, msg)
    }

    [flightRoutes insertObject:flightRoute atIndex:index];
    [self didInsertFlightRoute:flightRoute atIndex:index];
}

- (void) removeFlightRoute:(FlightRoute*)flightRoute
{
    if (flightRoute == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Flight route is nil")
    }

    NSUInteger index = [flightRoutes indexOfObject:flightRoute];
    if (index != NSNotFound)
    {
        [flightRoutes removeObjectAtIndex:index];
        [self didRemoveFlightRoute:flightRoute atIndex:index];
    }
}

- (void) removeFlightRouteAtIndex:(NSUInteger)index
{
    if (index >= [flightRoutes count])
    {
        NSString* msg = [[NSString alloc] initWithFormat:@"Index %d is out of range", index];
        WWLOG_AND_THROW(NSInvalidArgumentException, msg)
    }

    FlightRoute* flightRoute = [flightRoutes objectAtIndex:index];
    [flightRoutes removeObjectAtIndex:index];
    [self didRemoveFlightRoute:flightRoute atIndex:index];
}

- (void) moveFlightRouteAtIndex:(NSUInteger)fromIndex toIndex:(NSUInteger)toIndex
{
    if (fromIndex >= [flightRoutes count])
    {
        NSString* msg = [[NSString alloc] initWithFormat:@"From index %d is out of range", fromIndex];
        WWLOG_AND_THROW(NSInvalidArgumentException, msg)
    }

    if (toIndex >= [flightRoutes count])
    {
        NSString* msg = [[NSString alloc] initWithFormat:@"To index %d is out of range", toIndex];
        WWLOG_AND_THROW(NSInvalidArgumentException, msg)
    }

    FlightRoute* flightRoute = [flightRoutes objectAtIndex:fromIndex];
    [flightRoutes removeObjectAtIndex:fromIndex];
    [flightRoutes insertObject:flightRoute atIndex:toIndex];
    [self didMoveFlightRoute:flightRoute fromIndex:fromIndex toIndex:toIndex];
}

- (void) didInsertFlightRoute:(FlightRoute*)flightRoute atIndex:(NSUInteger)index
{
    // Make the flight route table view match the change in the model, using UIKit animations to display the change.
    // The index indicates the flight route that has been inserted.
    NSIndexPath* indexPath = [NSIndexPath indexPathForRow:index inSection:0];
    NSArray* indexPathArray = [NSArray arrayWithObject:indexPath];
    [[self tableView] insertRowsAtIndexPaths:indexPathArray withRowAnimation:UITableViewRowAnimationFade];
    [[self tableView] scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionNone animated:YES];

    // Save the flight route model state and the flight route list state.
    [self saveFlightRouteState:flightRoute];
    [self saveFlightRouteListState];

    // Redraw any WorldWindViews that might be displaying the flight route.
    [WorldWindView requestRedraw];
}

- (void) didRemoveFlightRoute:(FlightRoute*)flightRoute atIndex:(NSUInteger)index
{
    // Make the flight route table view match the change in the model, using UIKit animations to display the change.
    // The index indicates the flight route that has been removed.
    NSIndexPath* indexPath = [NSIndexPath indexPathForRow:index inSection:0];
    NSArray* indexPathArray = [NSArray arrayWithObject:indexPath];
    [[self tableView] deleteRowsAtIndexPaths:indexPathArray withRowAnimation:UITableViewRowAnimationAutomatic];

    // Remove the flight route model state, save the flight route list state.
    [self removeFlightRouteState:flightRoute];
    [self saveFlightRouteListState];

    // Post a notification that the flight route has been removed and redraw any WorldWindViews that might be displaying
    // the flight route.
    [[NSNotificationCenter defaultCenter] postNotificationName:TAIGA_FLIGHT_ROUTE_REMOVED object:flightRoute];
    [WorldWindView requestRedraw];
}

- (void) didMoveFlightRoute:(FlightRoute*)flightRoute fromIndex:(NSUInteger)fromIndex toIndex:(NSUInteger)toIndex
{
    // Remove the flight route list state.
    [self saveFlightRouteListState];

    // Redraw any WorldWindViews that might be displaying the flight route.
    [WorldWindView requestRedraw];
}

- (void) flightRouteDidChange:(FlightRoute*)flightRoute
{
    // Make the flight route table view match the change in the model, using UIKit animations to display the change.
    NSInteger index  = [flightRoutes indexOfObject:flightRoute];
    NSIndexPath* indexPath = [NSIndexPath indexPathForRow:index inSection:0];
    NSArray* indexPathArray = [NSArray arrayWithObject:indexPath];
    [[self tableView] reloadRowsAtIndexPaths:indexPathArray withRowAnimation:UITableViewRowAnimationAutomatic];

    // Save the flight route model state.
    [self saveFlightRouteState:flightRoute];

    // Redraw any WorldWindViews that might be displaying the flight route.
    [WorldWindView requestRedraw];
}

//--------------------------------------------------------------------------------------------------------------------//
//-- Creating and Presenting Flight Routes --//
//--------------------------------------------------------------------------------------------------------------------//

- (void) newFlightRoute:(void (^)(FlightRoute* newFlightRoute))completionBlock
{
    if (completionBlock == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Completion block is nil")
    }

    newFlightRouteCompletionBlock = completionBlock;

    UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:@"New Flight Route"
                                                        message:@"Enter a name for this route."
                                                       delegate:self
                                              cancelButtonTitle:@"Cancel"
                                              otherButtonTitles:@"Ok", nil];
    [alertView setAlertViewStyle:UIAlertViewStylePlainTextInput];
    [alertView show];
}

- (void) alertView:(UIAlertView*)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 1) // Ok button tapped
    {
        // Create a new flight route with its display name set to the UIAlert's text field contents, the default
        // altitude, a color from the list of flight route colors, and a unique state key.
        FlightRoute* newFlightRoute = [[FlightRoute alloc] init];
        [newFlightRoute setDisplayName:[[alertView textFieldAtIndex:0] text]];
        [newFlightRoute setAltitude:1524]; // 5,000ft
        [newFlightRoute setColorIndex:newFlightRouteColorIndex];
        [newFlightRoute setUserObject:[[NSProcessInfo processInfo] globallyUniqueString]];

        // Advance the flight route color to the next item in the circular list of flight route colors.
        if (++newFlightRouteColorIndex >= [[FlightRoute flightRouteColors] count])
        {
            newFlightRouteColorIndex = 0;
        }

        // Invoke the new flight route completion block.
        newFlightRouteCompletionBlock(newFlightRoute);
    }

    newFlightRouteCompletionBlock = NULL;
}

- (FlightRoute*) presentedFlightRoute
{
    for (UIViewController* vc in [[self navigationController] viewControllers])
    {
        if ([vc isKindOfClass:[FlightRouteDetailController class]])
        {
            return [(FlightRouteDetailController*) vc flightRoute];
        }
    }

    return nil;
}

- (void) presentFlightRouteAtIndex:(NSUInteger)index editing:(BOOL)editing
{
    if ([[self navigationController] topViewController] != self)
    {
        [[self navigationController] popToViewController:self animated:NO];
    }

    FlightRoute* flightRoute = [self flightRouteAtIndex:index];
    UIViewController* detailController = [[FlightRouteDetailController alloc] initWithFlightRoute:flightRoute waypointDatabase:_waypointDatabase view:_wwv];
    [detailController setEditing:editing animated:NO]; // The detail controller is not yet visible. No need to animate to the editing state.
    [[self navigationController] pushViewController:detailController animated:YES];
}

//--------------------------------------------------------------------------------------------------------------------//
//-- Saving and Restoring Flight Route State --//
//--------------------------------------------------------------------------------------------------------------------//

- (void) saveFlightRouteState:(FlightRoute*)flightRoute
{
    NSMutableArray* waypointKeys = [NSMutableArray arrayWithCapacity:[flightRoute waypointCount]];
    for (NSUInteger i = 0; i < [flightRoute waypointCount]; i++)
    {
        Waypoint* waypoint = [flightRoute waypointAtIndex:i];
        [waypointKeys addObject:[waypoint key]];
    }

    id key = [flightRoute userObject];
    NSUserDefaults* userState = [NSUserDefaults standardUserDefaults];
    [userState setObject:[flightRoute displayName] forKey:[NSString stringWithFormat:@"gov.nasa.worldwind.taiga.flightpath.%@.displayName", key]];
    [userState setBool:[flightRoute enabled] forKey:[NSString stringWithFormat:@"gov.nasa.worldwind.taiga.flightpath.%@.enabled", key]];
    [userState setDouble:[flightRoute altitude] forKey:[NSString stringWithFormat:@"gov.nasa.worldwind.taiga.flightpath.%@.altitude", key]];
    [userState setInteger:[flightRoute colorIndex] forKey:[NSString stringWithFormat:@"gov.nasa.worldwind.taiga.flightpath.%@.colorIndex", key]];
    [userState setObject:waypointKeys forKey:[NSString stringWithFormat:@"gov.nasa.worldwind.taiga.flightpath.%@.waypointKeys", key]];
    [userState synchronize];
}

- (void) removeFlightRouteState:(FlightRoute*)flightRoute
{
    id key = [flightRoute userObject];
    NSUserDefaults* userState = [NSUserDefaults standardUserDefaults];
    [userState removeObjectForKey:[NSString stringWithFormat:@"gov.nasa.worldwind.taiga.flightpath.%@.displayName", key]];
    [userState removeObjectForKey:[NSString stringWithFormat:@"gov.nasa.worldwind.taiga.flightpath.%@.enabled", key]];
    [userState removeObjectForKey:[NSString stringWithFormat:@"gov.nasa.worldwind.taiga.flightpath.%@.altitude", key]];
    [userState removeObjectForKey:[NSString stringWithFormat:@"gov.nasa.worldwind.taiga.flightpath.%@.colorIndex", key]];
    [userState removeObjectForKey:[NSString stringWithFormat:@"gov.nasa.worldwind.taiga.flightpath.%@.waypointKeys", key]];
    [userState synchronize];
}

- (void) saveFlightRouteListState
{
    NSMutableArray* flightRouteKeys = [NSMutableArray arrayWithCapacity:[flightRoutes count]];
    for (FlightRoute* flightRoute in flightRoutes)
    {
        [flightRouteKeys addObject:[flightRoute userObject]];
    }

    NSUserDefaults* userState = [NSUserDefaults standardUserDefaults];
    [userState setObject:flightRouteKeys forKey:@"gov.nasa.worldwind.taiga.flightPathKeys"];
    [userState setInteger:newFlightRouteColorIndex forKey:@"gov.nasa.worldwind.taiga.flightPathColorIndex"];
    [userState synchronize];
}

- (void) restoreFlightRouteState
{
    NSUserDefaults* userState = [NSUserDefaults standardUserDefaults];
    NSMutableArray* waypoints = [[NSMutableArray alloc] initWithCapacity:8];

    NSArray* flightRouteKeys = [userState objectForKey:@"gov.nasa.worldwind.taiga.flightPathKeys"];
    for (NSString* frKey in flightRouteKeys)
    {
        [waypoints removeAllObjects];
        NSArray* waypointKeys = [userState arrayForKey:[NSString stringWithFormat:@"gov.nasa.worldwind.taiga.flightpath.%@.waypointKeys", frKey]];
        for (NSString* wpKey in waypointKeys)
        {
            Waypoint* waypoint = [_waypointDatabase waypointForKey:wpKey];
            if (waypoint != nil)
            {
                [waypoints addObject:waypoint];
            }
            else
            {
                WWLog(@"Unrecognized waypoint key %@", wpKey);
            }
        }

        NSString* displayName = [userState stringForKey:[NSString stringWithFormat:@"gov.nasa.worldwind.taiga.flightpath.%@.displayName", frKey]];
        BOOL enabled = [userState boolForKey:[NSString stringWithFormat:@"gov.nasa.worldwind.taiga.flightpath.%@.enabled", frKey]];
        double altitude = [userState doubleForKey:[NSString stringWithFormat:@"gov.nasa.worldwind.taiga.flightpath.%@.altitude", frKey]];
        NSInteger colorIndex = [userState integerForKey:[NSString stringWithFormat:@"gov.nasa.worldwind.taiga.flightpath.%@.colorIndex", frKey]];

        FlightRoute* flightRoute = [[FlightRoute alloc] initWithWaypoints:waypoints];
        [flightRoute setDisplayName:displayName];
        [flightRoute setEnabled:enabled];
        [flightRoute setAltitude:altitude];
        [flightRoute setColorIndex:(NSUInteger) colorIndex];
        [flightRoute setUserObject:frKey]; // Assign the flight route its state key.
        [flightRoutes addObject:flightRoute];  // Add flight route to layer after initialization to avoid saving state during restore.
    }

    newFlightRouteColorIndex = (NSUInteger) [userState integerForKey:@"gov.nasa.worldwind.taiga.flightPathColorIndex"];

    [[self tableView] reloadData];
}

//--------------------------------------------------------------------------------------------------------------------//
//-- Displaying Flight Routes in a UITable --//
//--------------------------------------------------------------------------------------------------------------------//

- (NSInteger) tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self flightRouteCount];
}

- (UITableViewCell*) tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
    static NSString* cellIdentifier = @"cell";

    UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (cell == nil)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:cellIdentifier];
        [cell setAccessoryType:UITableViewCellAccessoryDetailButton];
    }

    FlightRoute* flightRoute = [self flightRouteAtIndex:(NSUInteger) [indexPath row]];
    [cell setToFlightRoute:flightRoute];

    return cell;
}

- (void) tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    // Set the flight route's visibility. Modify the model before the modifying the view. The view will be updated by
    // the notification by [FlightRoute setEnabled].
    FlightRoute* flightRoute = [self flightRouteAtIndex:(NSUInteger) [indexPath row]];
    [flightRoute setEnabled:![flightRoute enabled]];
}

- (void) tableView:(UITableView*)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath*)indexPath
{
    [self presentFlightRouteAtIndex:(NSUInteger) [indexPath row] editing:NO];
}

- (BOOL) tableView:(UITableView*)tableView canEditRowAtIndexPath:(NSIndexPath*)indexPath
{
    return YES;
}

- (BOOL) tableView:(UITableView*)tableView canMoveRowAtIndexPath:(NSIndexPath*)indexPath
{
    return YES;
}

- (void) tableView:(UITableView*)tableView
commitEditingStyle:(UITableViewCellEditingStyle)editingStyle
 forRowAtIndexPath:(NSIndexPath*)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete)
    {
        // Remove the flight route at the editing index from the flight route model. The flight route table is updated
        // in didRemoveFlightRoute:atIndex:.
        [self removeFlightRouteAtIndex:(NSUInteger) [indexPath row]];
    }
}

- (void) tableView:(UITableView*)tableView
moveRowAtIndexPath:(NSIndexPath*)sourceIndexPath
       toIndexPath:(NSIndexPath*)destinationIndexPath
{
    // Update the flight route model to match the change in the flight route table.
    [self moveFlightRouteAtIndex:(NSUInteger) [sourceIndexPath row] toIndex:(NSUInteger) [destinationIndexPath row]];
}

//--------------------------------------------------------------------------------------------------------------------//
//-- Displaying Flight Routes in a WorldWindView --//
//--------------------------------------------------------------------------------------------------------------------//

- (void) render:(WWDrawContext*)dc
{
    if (!_enabled)
    {
        return;
    }

    for (id flightRoute in flightRoutes)
    {
        [flightRoute render:dc];
    }
}

@end