/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.

 @version $Id$
 */

#import "FlightRouteController.h"
#import "FlightRouteDetailController.h"
#import "NewFlightRouteController.h"
#import "FlightRoute.h"
#import "AppConstants.h"
#import "UITableViewCell+TAIGAAdditions.h"
#import "WorldWind/Layer/WWRenderableLayer.h"
#import "WorldWind/WorldWindView.h"
#import "WorldWind/WWLog.h"

@implementation FlightRouteController

//--------------------------------------------------------------------------------------------------------------------//
//-- Initializing FlightRouteController --//
//--------------------------------------------------------------------------------------------------------------------//

- (id) initWithWorldWindView:(WorldWindView*)wwv
{
    self = [super initWithStyle:UITableViewStylePlain];

    _displayName = @"Flight Routes";
    _enabled = YES;
    _wwv = wwv;

    flightRoutes = [[NSMutableArray alloc] init];

    UIBarButtonItem* addButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd
                                                                                   target:self
                                                                                   action:@selector(addButtonItemTapped)];
    [[self navigationItem] setTitle:@"Flight Routes"];
    [[self navigationItem] setLeftBarButtonItem:addButtonItem];
    [[self navigationItem] setRightBarButtonItem:[self editButtonItem]];
    [[self tableView] setSeparatorStyle:UITableViewCellSeparatorStyleNone];
    [self setPreferredContentSize:CGSizeMake(350, 1000)];

    NSNotificationCenter* ns = [NSNotificationCenter defaultCenter];
    [ns addObserver:self selector:@selector(flightRouteDidChange:) name:TAIGA_FLIGHT_ROUTE_ATTRIBUTE_CHANGED object:nil];
    [ns addObserver:self selector:@selector(flightRouteDidChange:) name:TAIGA_FLIGHT_ROUTE_WAYPOINT_INSERTED object:nil];
    [ns addObserver:self selector:@selector(flightRouteDidChange:) name:TAIGA_FLIGHT_ROUTE_WAYPOINT_REMOVED object:nil];
    [ns addObserver:self selector:@selector(flightRouteDidChange:) name:TAIGA_FLIGHT_ROUTE_WAYPOINT_REPLACED object:nil];
    [ns addObserver:self selector:@selector(flightRouteDidChange:) name:TAIGA_FLIGHT_ROUTE_WAYPOINT_MOVED object:nil];

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

- (void) viewDidLoad
{
    [super viewDidLoad];

    [self restoreState];
}

- (void) navigationController:(UINavigationController*)navigationController
       willShowViewController:(UIViewController*)viewController
                     animated:(BOOL)animated
{
    // This keeps all the nested popover controllers the same size as this top-level controller.
    viewController.preferredContentSize = navigationController.topViewController.view.frame.size;
}

- (void) flightRouteDidChange:(NSNotification*)notification
{
    // Ignore notifications for flight routes not in this controller's layer. This also avoids saving state or
    // refreshing the screen for during flight route initialization or restoration.
    FlightRoute* flightRoute = [notification object];
    if (![flightRoutes containsObject:flightRoute])
        return;

    // Make the flight route table view match the change in the model, using UIKit animations to display the change.
    if ([[notification name] isEqualToString:TAIGA_FLIGHT_ROUTE_ATTRIBUTE_CHANGED])
    {
        NSInteger index  = [flightRoutes indexOfObject:flightRoute];
        NSIndexPath* indexPath = [NSIndexPath indexPathForRow:index inSection:0];
        [[self tableView] reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
    }

    // Save the flight route model state.
    [self saveState];

    // Redraw any WorldWindViews that might be displaying the flight route.
    [WorldWindView requestRedraw];
}

//--------------------------------------------------------------------------------------------------------------------//
//-- Saving and Restoring Flight Route State --//
//--------------------------------------------------------------------------------------------------------------------//

- (void) saveState
{
    if (!isSavingState)
    {
        [self performSelector:@selector(doSaveState) withObject:nil afterDelay:1.0];
        isSavingState = YES;
    }
}

- (void) doSaveState
{
    NSMutableArray* flightRoutePropertyLists = [[NSMutableArray alloc] initWithCapacity:[flightRoutes count]];
    for (FlightRoute* flightRoute in flightRoutes)
    {
        [flightRoutePropertyLists addObject:[flightRoute asPropertyList]];
    }

    NSUserDefaults* userState = [NSUserDefaults standardUserDefaults];
    [userState setInteger:newFlightRouteColorIndex forKey:@"gov.nasa.worldwind.taiga.newFlightRouteColorIndex"];
    [userState setObject:flightRoutePropertyLists forKey:@"gov.nasa.worldwind.taiga.flightRoutes"];
    [userState synchronize];

    isSavingState = NO;
}

- (void) restoreState
{
    NSUserDefaults* userState = [NSUserDefaults standardUserDefaults];
    newFlightRouteColorIndex = (NSUInteger) [userState integerForKey:@"gov.nasa.worldwind.taiga.newFlightRouteColorIndex"];

    NSArray* flightRoutePropertyLists = [userState objectForKey:@"gov.nasa.worldwind.taiga.flightRoutes"];
    for (NSDictionary* flightRoutePropertyList in flightRoutePropertyLists)
    {
        FlightRoute* flightRoute = [[FlightRoute alloc] initWithPropertyList:flightRoutePropertyList];
        [flightRoutes addObject:flightRoute];
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
    [[self tableView] insertRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    [[self tableView] scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionNone animated:YES];

    // Save the flight route model state and the flight route list state.
    [self saveState];

    // Redraw any WorldWindViews that might be displaying the flight route.
    [WorldWindView requestRedraw];
}

- (void) didRemoveFlightRoute:(FlightRoute*)flightRoute atIndex:(NSUInteger)index
{
    // Make the flight route table view match the change in the model, using UIKit animations to display the change.
    // The index indicates the flight route that has been removed.
    NSIndexPath* indexPath = [NSIndexPath indexPathForRow:index inSection:0];
    [[self tableView] deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];

    // Remove the flight route model state, save the flight route list state.
    [self saveState];

    // Post a notification that the flight route has been removed and redraw any WorldWindViews that might be displaying
    // the flight route.
    [[NSNotificationCenter defaultCenter] postNotificationName:TAIGA_FLIGHT_ROUTE_REMOVED object:flightRoute];
    [WorldWindView requestRedraw];
}

- (void) didMoveFlightRoute:(FlightRoute*)flightRoute fromIndex:(NSUInteger)fromIndex toIndex:(NSUInteger)toIndex
{
    // Remove the flight route list state.
    [self saveState];

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

    NewFlightRouteController* newRouteController = [[NewFlightRouteController alloc] init];
    [newRouteController setColorIndex:newFlightRouteColorIndex];
    [newRouteController setDefaultAltitude:1524]; // 5,000 ft
    [newRouteController setCompletionBlock:^{
        // Create a new flight route with its display name set to the new route sheet's name and altitude, and its color
        // set to the next color in the list of flight route colors.
        FlightRoute* newFlightRoute = [[FlightRoute alloc] initWithDisplayName:[newRouteController displayName]
                                                                    colorIndex:[newRouteController colorIndex]
                                                               defaultAltitude:[newRouteController defaultAltitude]];

        // Advance the flight route color to the next item in the circular list of flight route colors.
        if (++newFlightRouteColorIndex >= [[FlightRoute flightRouteColors] count])
        {
            newFlightRouteColorIndex = 0;
        }

        // Invoke the new flight route completion block.
        completionBlock(newFlightRoute);
    }];

    UINavigationController* navController = [[UINavigationController alloc] initWithRootViewController:newRouteController];
    [navController setModalPresentationStyle:UIModalPresentationFormSheet];
    [[self navigationController] presentViewController:navController animated:YES completion:NULL];
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
    UIViewController* detailController = [[FlightRouteDetailController alloc] initWithFlightRoute:flightRoute worldWindView:_wwv];
    [detailController setEditing:editing animated:NO]; // The detail controller is not yet visible. No need to animate to the editing state.
    [[self navigationController] pushViewController:detailController animated:YES];
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