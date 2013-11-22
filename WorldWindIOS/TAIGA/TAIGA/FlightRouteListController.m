/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.

 @version $Id$
 */

#import "FlightRouteListController.h"
#import "FlightRouteDetailController.h"
#import "FlightRoute.h"
#import "Waypoint.h"
#import "WaypointFile.h"
#import "AppConstants.h"
#import "WorldWind/Geometry/WWExtent.h"
#import "WorldWind/Geometry/WWPosition.h"
#import "WorldWind/Geometry/WWVec4.h"
#import "WorldWind/Layer/WWRenderableLayer.h"
#import "WorldWind/Navigate/WWNavigator.h"
#import "WorldWind/Render/WWSceneController.h"
#import "WorldWind/Terrain/WWGlobe.h"
#import "WorldWind/Util/WWColor.h"
#import "WorldWind/Util/WWMath.h"
#import "WorldWind/WorldWindView.h"
#import "WorldWind/WorldWindConstants.h"
#import "WorldWind/WWLog.h"

static const NSTimeInterval FlightRouteNavigatorDuration = 1.5;

@implementation FlightRouteListController

//--------------------------------------------------------------------------------------------------------------------//
//-- Initializing FlightRouteListController --//
//--------------------------------------------------------------------------------------------------------------------//

- (FlightRouteListController*) initWithWaypointFile:(WaypointFile*)waypointFile worldWindView:(WorldWindView*)wwv flightRouteLayer:(WWRenderableLayer*)flightRouteLayer
{
    self = [super initWithStyle:UITableViewStylePlain];

    UIBarButtonItem* addButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd
                                                                                   target:self
                                                                                   action:@selector(handleAddButtonTap)];
    [[self navigationItem] setTitle:@"Flight Routes"];
    [[self navigationItem] setLeftBarButtonItem:addButtonItem];
    [[self navigationItem] setRightBarButtonItem:[self editButtonItem]];
    [[self tableView] setSeparatorStyle:UITableViewCellSeparatorStyleNone];
    [self setPreferredContentSize:CGSizeMake(350, 1000)];

    _waypointFile = waypointFile;
    _wwv = wwv;
    _flightRouteLayer = flightRouteLayer;

    [self restoreAllFlightRouteState]; // restore state with waypointFile

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleFlightRouteNotification:)
                                                 name:TAIGA_FLIGHT_ROUTE_CHANGED object:nil];

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
        [self flightRouteDidChange:flightRoute notification:notification];
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

- (UIViewController*) flightRouteDetailControllerAtIndex:(NSUInteger)index
{
    FlightRoute* flightRoute = [self flightRouteAtIndex:index];
    return [[FlightRouteDetailController alloc] initWithFlightRoute:flightRoute waypointFile:_waypointFile];
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
    [self requestRedraw];
}

- (void) removeFlightRouteAtIndex:(NSUInteger)index
{
    FlightRoute* flightRoute = [[_flightRouteLayer renderables] objectAtIndex:index];
    [_flightRouteLayer removeRenderable:flightRoute];

    [self removeFlightRouteState:flightRoute];
    [self saveFlightRouteListState];
    [self requestRedraw];
}

- (void) moveFlightRouteFromIndex:(NSUInteger)fromIndex toIndex:(NSUInteger)toIndex
{
    NSMutableArray* flightRoutes = [_flightRouteLayer renderables];
    FlightRoute* flightRoute = [flightRoutes objectAtIndex:fromIndex];
    [flightRoutes removeObjectAtIndex:fromIndex];
    [flightRoutes insertObject:flightRoute atIndex:toIndex];

    [self saveFlightRouteListState];
    [self requestRedraw];
}

- (void) flightRouteDidChange:(FlightRoute*)flightRoute notification:(NSNotification*)notification
{
    // Refresh the table row corresponding to the flight route that changed.
    NSInteger index  = [[_flightRouteLayer renderables] indexOfObject:flightRoute];
    NSIndexPath* indexPath = [NSIndexPath indexPathForRow:index inSection:0];
    [[self tableView] reloadRowsAtIndexPaths:[NSArray arrayWithObject:indexPath]
                            withRowAnimation:UITableViewRowAnimationAutomatic];

    // Save the flight route's state and request that the WorldWindView to redraw itself. The view must be redrawn even
    // when the navigator logic below is not invoked in order to display flight route changes that do not result in
    // changes to the navigator.
    [self saveFlightRouteState:flightRoute];
    [self requestRedraw];

    // Show the the flight route in the WorldWindView when the flight route's waypoint list has changed.
    if ([[notification userInfo] objectForKey:TAIGA_FLIGHT_ROUTE_WAYPOINT_INDEX] != nil)
    {
        [self navigateToFlightRoute:flightRoute];
    }
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
            Waypoint* waypoint = [_waypointFile waypointForKey:wpKey];
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

- (NSInteger) numberOfSectionsInTableView:(UITableView*)tableView
{
    return 1;
}

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
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
        [cell setAccessoryType:UITableViewCellAccessoryDetailButton];
        [[cell imageView] setImage:[[UIImage imageNamed:@"431-yes.png"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]];
    }

    FlightRoute* flightRoute = [self flightRouteAtIndex:(NSUInteger) [indexPath row]];
    NSDictionary* colorAttrs = [[FlightRoute flightRouteColors] objectAtIndex:[flightRoute colorIndex]];
    [[cell imageView] setHidden:![flightRoute enabled]];
    [[cell imageView] setTintColor:[[colorAttrs objectForKey:@"color"] uiColor]];
    [[cell textLabel] setText:[flightRoute displayName]];

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

- (void) handleAddButtonTap
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
    }
}

//--------------------------------------------------------------------------------------------------------------------//
//-- WorldWindView Interface --//
//--------------------------------------------------------------------------------------------------------------------//

- (void) navigateToFlightRoute:(FlightRoute*)flightRoute
{
    WWGlobe* globe = [[_wwv sceneController] globe];
    id<WWExtent> extent = [flightRoute extentOnGlobe:globe];

    if (extent == nil)
        return; // empty flight route; nothing to navigate to

    // Compute the center and radius of a region that bounds the flight path's waypoints. If the flight route contains
    // only a single unique waypoint we use default radius of 100km. This sphere defines the region that will be shown
    // in the left half of the WorldWindView's viewport.
    WWPosition* center = [[WWPosition alloc] initWithZeroPosition];
    WWVec4* centerPoint = [extent center];
    [globe computePositionFromPoint:[centerPoint x] y:[centerPoint y] z:[centerPoint z] outputPosition:center];
    double globeRadius = MAX([globe equatorialRadius], [globe polarRadius]);
    double radiusMeters = [extent radius] > 0 ? [extent radius] : 100000;
    double radiusDegrees = DEGREES(radiusMeters / globeRadius);

    // Compute the scale that we'll apply to the region's radius in order to make it fit in the left half of the
    // WorldWindView's viewport. The navigator will fit the radius we provide into the smaller of the two viewport
    // dimensions. When the device is in portrait mode, the radius is fit to the viewport width, so the visible region's
    // radius must be twice the actual region's radius. When the device is in landscape mode, the radius is fit to the
    // viewport height, so the visible region's radius must be scaled based on the relative size of the viewport width
    // and height.
    id<WWNavigator> navigator = [_wwv navigator];
    CGRect viewport = [_wwv viewport];
    CGFloat viewportWidth = CGRectGetWidth(viewport);
    CGFloat viewportHeight = CGRectGetHeight(viewport);
    double radiusScale = viewportWidth < viewportHeight ? 2 : (viewportWidth < 2 * viewportHeight ? 2 * viewportHeight / viewportWidth : 1);

    // Navigate to the center and radius of the a region that places the flight route's bounding sector in the left half
    // of the WorldWindView's viewport. This region has its center at the eastern edge of the flight route relative to
    // the navigator's current heading, and has its radius scaled such that the flight route fits in half of the
    // viewport width.
    WWPosition* lookAtCenter = [[WWPosition alloc] initWithZeroPosition];
    [WWLocation greatCircleLocation:center azimuth:[navigator heading] + 90 distance:radiusDegrees outputLocation:lookAtCenter];
    double lookAtRadius = radiusMeters * radiusScale;
    [navigator animateToRegionWithCenter:lookAtCenter radius:lookAtRadius overDuration:FlightRouteNavigatorDuration];
}

- (void) requestRedraw
{
    [[NSNotificationCenter defaultCenter] postNotificationName:WW_REQUEST_REDRAW object:self];
}

@end