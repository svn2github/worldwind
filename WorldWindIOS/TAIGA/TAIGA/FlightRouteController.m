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

- (FlightRouteController*) initWithWorldWindView:(WorldWindView*)wwv flightRouteLayer:(WWRenderableLayer*)flightRouteLayer waypointDatabase:(WaypointDatabase*)waypointDatabase
{
    self = [super initWithStyle:UITableViewStylePlain];

    UIBarButtonItem* addButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd
                                                                                   target:self
                                                                                   action:@selector(presentNewRouteView)];
    [[self navigationItem] setTitle:@"Flight Routes"];
    [[self navigationItem] setLeftBarButtonItem:addButtonItem];
    [[self navigationItem] setRightBarButtonItem:[self editButtonItem]];
    [[self tableView] setSeparatorStyle:UITableViewCellSeparatorStyleNone];
    [self setPreferredContentSize:CGSizeMake(350, 1000)];

    _wwv = wwv;
    _flightRouteLayer = flightRouteLayer;
    _waypointDatabase = waypointDatabase;
    [self restoreAllFlightRouteState]; // restore state with waypointFile

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

    // Ignore notifications for flight routes not in this controller's layer. This avoids saving state or refreshing the
    // screen for during flight route initialization or restoration.
    if ([[_flightRouteLayer renderables] containsObject:flightRoute])
    {
        [self flightRouteDidChange:flightRoute];
    }
}

//--------------------------------------------------------------------------------------------------------------------//
//-- Flight Route Model --//
//--------------------------------------------------------------------------------------------------------------------//

- (NSUInteger) flightRouteCount
{
    return [[_flightRouteLayer renderables] count];
}

- (FlightRoute*) flightRouteAtIndex:(NSUInteger)index
{
    return [[_flightRouteLayer renderables] objectAtIndex:index];
}

- (FlightRoute*) presentedFlightRoute
{
    UIViewController* topViewController = [[self navigationController] topViewController];
    if ([topViewController isKindOfClass:[FlightRouteDetailController class]])
    {
        return [(FlightRouteDetailController*) topViewController flightRoute];
    }

    return nil;
}

- (void) presentFlightRouteAtIndex:(NSUInteger)index
{
    UIViewController* detailController = [self flightRouteDetailControllerAtIndex:index];
    [[self navigationController] popToRootViewControllerAnimated:NO];
    [[self navigationController] pushViewController:detailController animated:YES];
    [[(FlightRouteDetailController*) detailController flightRoute] setEnabled:YES]; // make the flight route visible on the map
}

- (void) newFlightRoute:(void (^)(FlightRoute* newFlightRoute))completionBlock
{
    newFlightRouteCompletionBlock = completionBlock;
    [[self navigationController] popToRootViewControllerAnimated:NO];
    [self presentNewRouteView];
}

- (UIViewController*) flightRouteDetailControllerAtIndex:(NSUInteger)index
{
    FlightRoute* flightRoute = [self flightRouteAtIndex:index];
    return [[FlightRouteDetailController alloc] initWithFlightRoute:flightRoute waypointDatabase:_waypointDatabase view:_wwv];
}

- (void) addFlightRouteAtIndex:(NSUInteger)index withDisplayName:(NSString*)displayName
{
    FlightRoute* flightRoute = [[FlightRoute alloc] init];
    [flightRoute setDisplayName:displayName];
    [flightRoute setAltitude:1524]; // 5,000ft
    [flightRoute setColorIndex:flightRouteColorIndex];
    [flightRoute setUserObject:[[NSProcessInfo processInfo] globallyUniqueString]]; // Create a state key for the flight route.
    [[_flightRouteLayer renderables] insertObject:flightRoute atIndex:index]; // Add flight route to layer after initialization to avoid saving state during initialization.

    if (++flightRouteColorIndex >= [[FlightRoute flightRouteColors] count])
    {
        flightRouteColorIndex = 0;
    }

    [self saveFlightRouteState:flightRoute];
    [self saveFlightRouteListState];
    [WorldWindView requestRedraw];
}

- (void) removeFlightRouteAtIndex:(NSUInteger)index
{
    FlightRoute* flightRoute = [[_flightRouteLayer renderables] objectAtIndex:index];
    [_flightRouteLayer removeRenderable:flightRoute];

    [self removeFlightRouteState:flightRoute];
    [self saveFlightRouteListState];
    [WorldWindView requestRedraw];

    [[NSNotificationCenter defaultCenter] postNotificationName:TAIGA_FLIGHT_ROUTE_REMOVED object:flightRoute];
}

- (void) moveFlightRouteFromIndex:(NSUInteger)fromIndex toIndex:(NSUInteger)toIndex
{
    NSMutableArray* flightRoutes = [_flightRouteLayer renderables];
    FlightRoute* flightRoute = [flightRoutes objectAtIndex:fromIndex];
    [flightRoutes removeObjectAtIndex:fromIndex];
    [flightRoutes insertObject:flightRoute atIndex:toIndex];

    [self saveFlightRouteListState];
    [WorldWindView requestRedraw];
}

- (void) flightRouteDidChange:(FlightRoute*)flightRoute
{
    // Refresh the table row corresponding to the flight route that changed.
    NSInteger index  = [[_flightRouteLayer renderables] indexOfObject:flightRoute];
    NSIndexPath* indexPath = [NSIndexPath indexPathForRow:index inSection:0];
    [[self tableView] reloadRowsAtIndexPaths:[NSArray arrayWithObject:indexPath]
                            withRowAnimation:UITableViewRowAnimationAutomatic];

    // Save the flight route's state and request that the WorldWindView to redraw itself.
    [self saveFlightRouteState:flightRoute];
    [WorldWindView requestRedraw];
}

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
    NSMutableArray* flightRoutes = [_flightRouteLayer renderables];
    NSMutableArray* flightRouteKeys = [NSMutableArray arrayWithCapacity:[flightRoutes count]];
    for (FlightRoute* flightRoute in flightRoutes)
    {
        [flightRouteKeys addObject:[flightRoute userObject]];
    }

    NSUserDefaults* userState = [NSUserDefaults standardUserDefaults];
    [userState setObject:flightRouteKeys forKey:@"gov.nasa.worldwind.taiga.flightPathKeys"];
    [userState setInteger:flightRouteColorIndex forKey:@"gov.nasa.worldwind.taiga.flightPathColorIndex"];
    [userState synchronize];
}

- (void) restoreAllFlightRouteState
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
        [_flightRouteLayer addRenderable:flightRoute];  // Add flight route to layer after initialization to avoid saving state during restore.
    }

    flightRouteColorIndex = (NSUInteger) [userState integerForKey:@"gov.nasa.worldwind.taiga.flightPathColorIndex"];
}

//--------------------------------------------------------------------------------------------------------------------//
//-- Flight Route List Table --//
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
    UIViewController* detailController = [self flightRouteDetailControllerAtIndex:(NSUInteger) [indexPath row]];
    [[self navigationController] pushViewController:detailController animated:YES];
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
        // Modify the model before the modifying the view.
        [self removeFlightRouteAtIndex:(NSUInteger) [indexPath row]];
        // Make the view match the change in the model, using UIKit animations to display the change.
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath]
                         withRowAnimation:UITableViewRowAnimationAutomatic];
    }
}

- (void) tableView:(UITableView*)tableView
moveRowAtIndexPath:(NSIndexPath*)sourceIndexPath
       toIndexPath:(NSIndexPath*)destinationIndexPath
{
    // Modify the model. The view has already been updated by the UITableView.
    [self moveFlightRouteFromIndex:(NSUInteger) [sourceIndexPath row] toIndex:(NSUInteger) [destinationIndexPath row]];
}

//--------------------------------------------------------------------------------------------------------------------//
//-- Creating New Flight Routes --//
//--------------------------------------------------------------------------------------------------------------------//

- (void) presentNewRouteView
{
    UIAlertView* inputView = [[UIAlertView alloc] initWithTitle:@"New Flight Route"
                                                        message:@"Enter a name for this route."
                                                       delegate:self
                                              cancelButtonTitle:@"Cancel"
                                              otherButtonTitles:@"Ok", nil];
    [inputView setAlertViewStyle:UIAlertViewStylePlainTextInput];
    [inputView show];
}

- (void) alertView:(UIAlertView*)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 1) // Ok button tapped (ignore Cancel button tapped)
    {
        // Modify the model before the modifying the view.
        NSUInteger index = (NSUInteger) [self flightRouteCount]; // Append to the end of the table.
        NSString* displayName = [[alertView textFieldAtIndex:0] text]; // Flight route name text field
        [self addFlightRouteAtIndex:index withDisplayName:displayName];

        // Make the view match the change in the model. The index path's row indicates the row index that has been
        // inserted. Suppress row animations since we pushing a new view controller below.
        NSIndexPath* indexPath = [NSIndexPath indexPathForRow:index inSection:0];
        [[self tableView] insertRowsAtIndexPaths:[NSArray arrayWithObject:indexPath]
                                withRowAnimation:UITableViewRowAnimationNone];
        [[self tableView] scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionNone
                                        animated:NO];

        // Show the flight route detail controller in its edit state. Suppress animations when transitioning to the edit
        // state since we're pushing a new view controller.
        UIViewController* detailController = [self flightRouteDetailControllerAtIndex:index];
        [detailController setEditing:YES animated:NO];
        [[self navigationController] pushViewController:detailController animated:YES];

        // Invoke the add route completion block, if any.
        if (newFlightRouteCompletionBlock != NULL)
        {
            FlightRoute* newFlightRoute = [self flightRouteAtIndex:index];
            newFlightRouteCompletionBlock(newFlightRoute);
            newFlightRouteCompletionBlock = NULL;
        }
    }
}

@end