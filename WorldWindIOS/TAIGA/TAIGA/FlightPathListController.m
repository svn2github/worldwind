/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.

 @version $Id$
 */

#import "FlightPathListController.h"
#import "FlightPathDetailController.h"
#import "FlightPath.h"
#import "Waypoint.h"
#import "WaypointFile.h"
#import "WorldWind/Layer/WWRenderableLayer.h"
#import "WorldWind/Util/WWColor.h"
#import "WorldWind/WorldWindConstants.h"
#import "WorldWind/WWLog.h"
#import "AppConstants.h"

@implementation FlightPathListController

//--------------------------------------------------------------------------------------------------------------------//
//-- Initializing FlightPathListController --//
//--------------------------------------------------------------------------------------------------------------------//

- (FlightPathListController*) initWithLayer:(WWRenderableLayer*)layer
{
    self = [super initWithStyle:UITableViewStylePlain];

    UIBarButtonItem* addButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd
                                                                                   target:self
                                                                                   action:@selector(handleAddButtonTap)];
    [[self navigationItem] setTitle:@"Flight Routes"];
    [[self navigationItem] setLeftBarButtonItem:addButtonItem];
    [[self navigationItem] setRightBarButtonItem:[self editButtonItem]];
    [self setPreferredContentSize:CGSizeMake(350, 1000)];

    _layer = layer;

    NSURL* airportsUrl = [NSURL URLWithString:@"http://worldwindserver.net/taiga/dafif/ARPT2_ALASKA.TXT"];
    waypointFile = [[WaypointFile alloc] init];
    [waypointFile loadDAFIFAirports:airportsUrl finishedBlock:^
    {
        [self didLoadWaypoints];
    }];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleFlightRouteNotification:)
                                                 name:TAIGA_FLIGHT_ROUTE_CHANGED object:nil];

    return self;
}

- (void) didLoadWaypoints
{
    [self restoreAllFlightPathState];
    [[self tableView] reloadData];
    [self requestRedraw];
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
    FlightPath* flightPath = [notification object];

    // Ignore notifications for flight paths not in this controller's layer. This avoids saving state or refreshing the
    // screen for during flight path initialization or restoration.
    if ([[_layer renderables] containsObject:flightPath])
    {
        [self flightPathDidChange:flightPath];
    }
}

//--------------------------------------------------------------------------------------------------------------------//
//-- Flight Path Model --//
//--------------------------------------------------------------------------------------------------------------------//

- (NSUInteger) flightPathCount
{
    return [[_layer renderables] count];
}

- (FlightPath*) flightPathAtIndex:(NSUInteger)index
{
    return [[_layer renderables] objectAtIndex:index];
}

- (UIViewController*) flightPathDetailControllerAtIndex:(NSUInteger)index
{
    FlightPath* flightPath = [self flightPathAtIndex:index];
    return [[FlightPathDetailController alloc] initWithFlightPath:flightPath waypointFile:waypointFile];
}

- (void) addFlightPathAtIndex:(NSUInteger)index withDisplayName:(NSString*)displayName
{
    FlightPath* flightPath = [[FlightPath alloc] init];
    [flightPath setDisplayName:displayName];
    [flightPath setAltitude:1524]; // 5,000ft
    [flightPath setColorIndex:flightPathColorIndex];
    [flightPath setUserObject:[[NSProcessInfo processInfo] globallyUniqueString]]; // Create a state key for the flight path.
    [[_layer renderables] insertObject:flightPath atIndex:index]; // Add flight path to layer after initialization to avoid saving state during initialization.

    if (++flightPathColorIndex >= [[FlightPath flightPathColors] count])
    {
        flightPathColorIndex = 0;
    }

    [self saveFlightPathState:flightPath];
    [self saveFlightPathListState];
    [self requestRedraw];
}

- (void) removeFlightPathAtIndex:(NSUInteger)index
{
    FlightPath* flightPath = [[_layer renderables] objectAtIndex:index];
    [_layer removeRenderable:flightPath];

    [self removeFlightPathState:flightPath];
    [self saveFlightPathListState];
    [self requestRedraw];
}

- (void) moveFlightPathFromIndex:(NSUInteger)fromIndex toIndex:(NSUInteger)toIndex
{
    NSMutableArray* flightPaths = [_layer renderables];
    FlightPath* path = [flightPaths objectAtIndex:fromIndex];
    [flightPaths removeObjectAtIndex:fromIndex];
    [flightPaths insertObject:path atIndex:toIndex];

    [self saveFlightPathListState];
    [self requestRedraw];
}

- (void) flightPathDidChange:(FlightPath*)flightPath
{
    // Refresh the table row corresponding to the flight path that changed.
    NSInteger index  = [[_layer renderables] indexOfObject:flightPath];
    NSIndexPath* indexPath = [NSIndexPath indexPathForRow:index inSection:0];
    [[self tableView] reloadRowsAtIndexPaths:[NSArray arrayWithObject:indexPath]
                            withRowAnimation:UITableViewRowAnimationAutomatic];

    [self saveFlightPathState:flightPath];
    [self requestRedraw];
}

- (void) saveFlightPathState:(FlightPath*)flightPath
{
    NSMutableArray* waypointKeys = [NSMutableArray arrayWithCapacity:[flightPath waypointCount]];
    for (NSUInteger i = 0; i < [flightPath waypointCount]; i++)
    {
        Waypoint* waypoint = [flightPath waypointAtIndex:i];
        [waypointKeys addObject:[waypoint key]];
    }

    id key = [flightPath userObject];
    NSUserDefaults* userState = [NSUserDefaults standardUserDefaults];
    [userState setObject:[flightPath displayName] forKey:[NSString stringWithFormat:@"gov.nasa.worldwind.taiga.flightpath.%@.displayName", key]];
    [userState setBool:[flightPath enabled] forKey:[NSString stringWithFormat:@"gov.nasa.worldwind.taiga.flightpath.%@.enabled", key]];
    [userState setDouble:[flightPath altitude] forKey:[NSString stringWithFormat:@"gov.nasa.worldwind.taiga.flightpath.%@.altitude", key]];
    [userState setInteger:[flightPath colorIndex] forKey:[NSString stringWithFormat:@"gov.nasa.worldwind.taiga.flightpath.%@.colorIndex", key]];
    [userState setObject:waypointKeys forKey:[NSString stringWithFormat:@"gov.nasa.worldwind.taiga.flightpath.%@.waypointKeys", key]];
    [userState synchronize];
}

- (void) removeFlightPathState:(FlightPath*)flightPath
{
    id key = [flightPath userObject];
    NSUserDefaults* userState = [NSUserDefaults standardUserDefaults];
    [userState removeObjectForKey:[NSString stringWithFormat:@"gov.nasa.worldwind.taiga.flightpath.%@.displayName", key]];
    [userState removeObjectForKey:[NSString stringWithFormat:@"gov.nasa.worldwind.taiga.flightpath.%@.enabled", key]];
    [userState removeObjectForKey:[NSString stringWithFormat:@"gov.nasa.worldwind.taiga.flightpath.%@.altitude", key]];
    [userState removeObjectForKey:[NSString stringWithFormat:@"gov.nasa.worldwind.taiga.flightpath.%@.colorIndex", key]];
    [userState removeObjectForKey:[NSString stringWithFormat:@"gov.nasa.worldwind.taiga.flightpath.%@.waypointKeys", key]];
    [userState synchronize];
}

- (void) saveFlightPathListState
{
    NSMutableArray* flightPaths = [_layer renderables];
    NSMutableArray* flightPathKeys = [NSMutableArray arrayWithCapacity:[flightPaths count]];
    for (FlightPath* flightPath in flightPaths)
    {
        [flightPathKeys addObject:[flightPath userObject]];
    }

    NSUserDefaults* userState = [NSUserDefaults standardUserDefaults];
    [userState setObject:flightPathKeys forKey:@"gov.nasa.worldwind.taiga.flightPathKeys"];
    [userState setInteger:flightPathColorIndex forKey:@"gov.nasa.worldwind.taiga.flightPathColorIndex"];
    [userState synchronize];
}

- (void) restoreAllFlightPathState
{
    NSUserDefaults* userState = [NSUserDefaults standardUserDefaults];
    NSMutableArray* waypoints = [[NSMutableArray alloc] initWithCapacity:8];

    NSArray* flightPathKeys = [userState objectForKey:@"gov.nasa.worldwind.taiga.flightPathKeys"];
    for (NSString* fpKey in flightPathKeys)
    {
        [waypoints removeAllObjects];
        NSArray* waypointKeys = [userState arrayForKey:[NSString stringWithFormat:@"gov.nasa.worldwind.taiga.flightpath.%@.waypointKeys", fpKey]];
        for (NSString* wpKey in waypointKeys)
        {
            Waypoint* waypoint = [waypointFile waypointForKey:wpKey];
            if (waypoint != nil)
            {
                [waypoints addObject:waypoint];
            }
            else
            {
                WWLog(@"Unrecognized waypoint key %@", wpKey);
            }
        }

        NSString* displayName = [userState stringForKey:[NSString stringWithFormat:@"gov.nasa.worldwind.taiga.flightpath.%@.displayName", fpKey]];
        BOOL enabled = [userState boolForKey:[NSString stringWithFormat:@"gov.nasa.worldwind.taiga.flightpath.%@.enabled", fpKey]];
        double altitude = [userState doubleForKey:[NSString stringWithFormat:@"gov.nasa.worldwind.taiga.flightpath.%@.altitude", fpKey]];
        NSInteger colorIndex = [userState integerForKey:[NSString stringWithFormat:@"gov.nasa.worldwind.taiga.flightpath.%@.colorIndex", fpKey]];

        FlightPath* flightPath = [[FlightPath alloc] initWithWaypoints:waypoints];
        [flightPath setDisplayName:displayName];
        [flightPath setEnabled:enabled];
        [flightPath setAltitude:altitude];
        [flightPath setColorIndex:(NSUInteger) colorIndex];
        [flightPath setUserObject:fpKey]; // Assign the flight path its state key.
        [_layer addRenderable:flightPath];  // Add flight path to layer after initialization to avoid saving state during restore.
    }

    flightPathColorIndex = (NSUInteger) [userState integerForKey:@"gov.nasa.worldwind.taiga.flightPathColorIndex"];
}

//--------------------------------------------------------------------------------------------------------------------//
//-- Flight Path List Table --//
//--------------------------------------------------------------------------------------------------------------------//

- (NSInteger) numberOfSectionsInTableView:(UITableView*)tableView
{
    return 1;
}

- (NSInteger) tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self flightPathCount];
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

    FlightPath* path = [self flightPathAtIndex:(NSUInteger) [indexPath row]];
    NSDictionary* colorAttrs = [[FlightPath flightPathColors] objectAtIndex:[path colorIndex]];
    [[cell imageView] setHidden:![path enabled]];
    [[cell imageView] setTintColor:[[colorAttrs objectForKey:@"color"] uiColor]];
    [[cell textLabel] setText:[path displayName]];

    return cell;
}

- (void) tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    // Set the flight path's visibility. Modify the model before the modifying the view. The view will be updated by
    // the notification by [FlightPath setEnabled].
    FlightPath* path = [self flightPathAtIndex:(NSUInteger) [indexPath row]];
    [path setEnabled:![path enabled]];
}

- (void) tableView:(UITableView*)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath*)indexPath
{
    UIViewController* detailController = [self flightPathDetailControllerAtIndex:(NSUInteger) [indexPath row]];
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
        [self removeFlightPathAtIndex:(NSUInteger) [indexPath row]];
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
    [self moveFlightPathFromIndex:(NSUInteger) [sourceIndexPath row] toIndex:(NSUInteger) [destinationIndexPath row]];
}

//--------------------------------------------------------------------------------------------------------------------//
//-- Creating New Flight Paths --//
//--------------------------------------------------------------------------------------------------------------------//

- (void) handleAddButtonTap
{
    UIAlertView* inputView = [[UIAlertView alloc] initWithTitle:@"New Flight Path"
                                                        message:@"Enter a name for this path."
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
        NSUInteger index = (NSUInteger) [self flightPathCount]; // Append to the end of the table.
        NSString* displayName = [[alertView textFieldAtIndex:0] text]; // Path name text field
        [self addFlightPathAtIndex:index withDisplayName:displayName];

        // Make the view match the change in the model. The index path's row indicates the row index that has been
        // inserted. Suppress row animations since we pushing a new view controller below.
        NSIndexPath* indexPath = [NSIndexPath indexPathForRow:index inSection:0];
        [[self tableView] insertRowsAtIndexPaths:[NSArray arrayWithObject:indexPath]
                                withRowAnimation:UITableViewRowAnimationNone];
        [[self tableView] scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionNone
                                        animated:NO];

        // Show the flight path detail controller in its edit state. Suppress animations when transitioning to the edit
        // state since we're pushing a new view controller.
        UIViewController* detailController = [self flightPathDetailControllerAtIndex:index];
        [detailController setEditing:YES animated:NO];
        [[self navigationController] pushViewController:detailController animated:YES];
    }
}

//--------------------------------------------------------------------------------------------------------------------//
//-- WorldWindView Interface --//
//--------------------------------------------------------------------------------------------------------------------//

- (void) requestRedraw
{
    [[NSNotificationCenter defaultCenter] postNotificationName:WW_REQUEST_REDRAW object:self];
}

@end