/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.

 @version $Id$
 */

#import "FlightRouteDetailController.h"
#import "FlightRoute.h"
#import "Waypoint.h"
#import "WaypointCell.h"
#import "WaypointFileControl.h"
#import "AltitudePicker.h"
#import "ColorPicker.h"
#import "AppConstants.h"
#import "WorldWind/Util/WWColor.h"

#define EDIT_ANIMATION_DURATION (0.3)
#define SECTION_PROPERTIES (0)
#define SECTION_WAYPOINTS (1)
#define ROW_COLOR (0)
#define ROW_ALTITUDE (1)

@implementation FlightRouteDetailController

//--------------------------------------------------------------------------------------------------------------------//
//-- Initializing FlightRouteDetailController --//
//--------------------------------------------------------------------------------------------------------------------//

- (FlightRouteDetailController*) initWithFlightRoute:(FlightRoute*)flightRoute waypointFile:(WaypointFile*)waypointFile
{
    self = [super initWithNibName:nil bundle:nil];

    [[self navigationItem] setTitle:[flightRoute displayName]];
    [[self navigationItem] setRightBarButtonItem:[self editButtonItem]];

    _flightRoute = flightRoute;
    _waypointFile = waypointFile;
    altitudeFormatter = [[NSNumberFormatter alloc] init];
    [altitudeFormatter setNumberStyle:NSNumberFormatterDecimalStyle];
    [altitudeFormatter setMultiplier:@TAIGA_METERS_TO_FEET];
    [altitudeFormatter setPositiveSuffix:@"ft MSL"];

    return self;
}

- (void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self flashScrollIndicators];
}

- (void) flashScrollIndicators
{
    [flightRouteTable flashScrollIndicators];
    [waypointFileControl flashScrollIndicators];
}

//--------------------------------------------------------------------------------------------------------------------//
//-- View Layout --//
//--------------------------------------------------------------------------------------------------------------------//

- (void) loadView
{
    UIView* view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 1, 1)];
    [view setAutoresizingMask:UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight];
    [self setView:view];

    flightRouteTable = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, 1, 1) style:UITableViewStyleGrouped];
    [flightRouteTable setDataSource:self];
    [flightRouteTable setDelegate:self];
    [flightRouteTable setAllowsSelectionDuringEditing:YES];
    [view addSubview:flightRouteTable];

    waypointFileControl = [[WaypointFileControl alloc] initWithFrame:CGRectMake(0, 0, 1, 1) target:self action:@selector(didChooseWaypoint:)];
    [waypointFileControl setWaypointFile:_waypointFile];
    [view addSubview:waypointFileControl];

    [self layout];
}

- (void) layout
{
    UIView* view = [self view];
    NSDictionary* viewsDictionary = NSDictionaryOfVariableBindings(view, flightRouteTable, waypointFileControl);

    // Disable automatic translation of autoresizing mask into constraints. We're using explicit layout constraints
    // below.
    [flightRouteTable setTranslatesAutoresizingMaskIntoConstraints:NO];
    [waypointFileControl setTranslatesAutoresizingMaskIntoConstraints:NO];

    [view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[flightRouteTable]|"
                                                                 options:0 metrics:nil views:viewsDictionary]];
    [view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[waypointFileControl]|"
                                                                 options:0 metrics:nil views:viewsDictionary]];
    normalConstraints = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|[flightRouteTable(==view)]-[waypointFileControl(>=160)]"
                                                                options:0 metrics:nil views:viewsDictionary];
    editingConstraints = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|[flightRouteTable(<=320)]-[waypointFileControl(>=160)]|"
                                                                 options:0 metrics:nil views:viewsDictionary];
    [view addConstraints:normalConstraints];
}

- (void) layoutForEditing:(BOOL)editing
{
    UIView* view = [self view];
    [view removeConstraints:editing ? normalConstraints : editingConstraints];
    [view addConstraints:editing ? editingConstraints : normalConstraints];
}

- (void) setEditing:(BOOL)editing animated:(BOOL)animated
{
    [super setEditing:editing animated:animated];

    if (animated)
    {
        [[self view] layoutIfNeeded]; // Ensure all pending layout operations have completed.
        [UIView animateWithDuration:EDIT_ANIMATION_DURATION
                              delay:0.0
                            options:UIViewAnimationOptionBeginFromCurrentState // Animate scroll views from their current state.
                         animations:^
                         {
                             [self layoutForEditing:editing];
                             [[self view] layoutIfNeeded]; // Force layout to capture constraint frame changes in the animation block.
                         }
                         completion:^(BOOL finished)
                         {
                             [self flashScrollIndicators];
                         }];
    }
    else
    {
        [self layoutForEditing:editing];
        [[self view] layoutIfNeeded]; // Force layout to capture constraint frame changes now.
        [self flashScrollIndicators];
    }

    // Place the table in editing mode and refresh the properties section, which has custom editing controls.
    [flightRouteTable setEditing:editing animated:animated];
}

//--------------------------------------------------------------------------------------------------------------------//
//-- UITableViewDataSource and UITableViewDelegate --//
//--------------------------------------------------------------------------------------------------------------------//

- (NSInteger) numberOfSectionsInTableView:(UITableView*)tableView
{
    return 2;
}

- (NSInteger) tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section
{
    switch (section)
    {
        case SECTION_PROPERTIES:
            return 2;
        case SECTION_WAYPOINTS:
            return [_flightRoute waypointCount];
        default:
            return 0;
    }
}

- (NSString*) tableView:(UITableView*)tableView titleForHeaderInSection:(NSInteger)section
{
    switch (section)
    {
        case SECTION_PROPERTIES:
            return nil; // Suppress properties section title.
        case SECTION_WAYPOINTS:
            return @"Waypoints";
        default:
            return nil;
    }
}

- (UITableViewCell*) tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
    switch ([indexPath section])
    {
        case SECTION_PROPERTIES:
            return [self tableView:tableView cellForProperty:indexPath];
        case SECTION_WAYPOINTS:
            return [self tableView:tableView cellForWaypoint:indexPath];
        default:
            return nil;
    }
}

- (UITableViewCell*) tableView:(UITableView*)tableView cellForProperty:(NSIndexPath*)indexPath
{
    static NSString* propertyCellId = @"propertyCellId";
    static UIColor* detailTextColor;
    UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:propertyCellId];
    if (cell == nil)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:propertyCellId];
        [cell setAccessoryType:UITableViewCellAccessoryDisclosureIndicator];
        detailTextColor = [[cell detailTextLabel] textColor];
    }

    if ([indexPath row] == ROW_COLOR)
    {
        NSDictionary* colorAttrs = [[FlightRoute flightRouteColors] objectAtIndex:[_flightRoute colorIndex]];
        [[cell textLabel] setText:@"Color"];
        [[cell detailTextLabel] setText:[colorAttrs objectForKey:@"displayName"]];
        [[cell detailTextLabel] setTextColor:[[colorAttrs objectForKey:@"color"] uiColor]];
    }
    else if ([indexPath row] == ROW_ALTITUDE)
    {
        double altitude = [_flightRoute altitude];
        [[cell textLabel] setText:@"Altitude"];
        [[cell detailTextLabel] setText:[altitudeFormatter stringFromNumber:[NSNumber numberWithDouble:altitude]]];
        [[cell detailTextLabel] setTextColor:detailTextColor]; // show altitude detail text in the default color
    }

    return cell;
}

- (UITableViewCell*) tableView:(UITableView*)tableView cellForWaypoint:(NSIndexPath*)indexPath
{
    static NSString* waypointCellId = @"waypointCellId";
    WaypointCell* cell = [tableView dequeueReusableCellWithIdentifier:waypointCellId];
    if (cell == nil)
    {
        cell = [[WaypointCell alloc] initWithReuseIdentifier:waypointCellId];
    }

    Waypoint* waypoint = [_flightRoute waypointAtIndex:(NSUInteger) [indexPath row]];
    [cell setToWaypoint:waypoint];

    return cell;
}

- (void) tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    if ([indexPath section] == SECTION_PROPERTIES && [indexPath row] == ROW_COLOR)
    {
        ColorPicker* picker = [[ColorPicker alloc] initWithFrame:CGRectMake(0, 0, 1, 1)];
        [picker addTarget:self action:@selector(didPickColor:) forControlEvents:UIControlEventValueChanged];
        [picker setColorChoices:[FlightRoute flightRouteColors]];
        [picker setSelectedColorIndex:[_flightRoute colorIndex]];

        UIViewController* viewController = [[UIViewController alloc] init];
        [viewController setView:picker];
        [viewController setTitle:@"Color"];
        [[self navigationController] pushViewController:viewController animated:YES];
    }
    else if ([indexPath section] == SECTION_PROPERTIES && [indexPath row] == ROW_ALTITUDE)
    {
        AltitudePicker* picker = [[AltitudePicker alloc] initWithFrame:CGRectMake(0, 44, 1, 216)];
        [picker addTarget:self action:@selector(didPickAltitude:) forControlEvents:UIControlEventValueChanged];
        [picker setMinimumAltitude:0];
        [picker setMaximumAltitude:30480]; // 100,000ft maximum
        [picker setAltitudeInterval:152.4]; // 500ft interval
        [picker setAltitude:[_flightRoute altitude]];
        [picker setFormatter:altitudeFormatter];

        UIViewController* viewController = [[UIViewController alloc] init];
        [viewController setView:picker];
        [viewController setTitle:@"Altitude"];
        [[self navigationController] pushViewController:viewController animated:YES];
    }
}

- (BOOL) tableView:(UITableView*)tableView canEditRowAtIndexPath:(NSIndexPath*)indexPath
{
    switch ([indexPath section])
    {
        case SECTION_PROPERTIES:
            return NO;
        case SECTION_WAYPOINTS:
            return YES;
        default:
            return NO;
    }
}

- (BOOL) tableView:(UITableView*)tableView canMoveRowAtIndexPath:(NSIndexPath*)indexPath
{
    switch ([indexPath section])
    {
        case SECTION_PROPERTIES:
            return NO;
        case SECTION_WAYPOINTS:
            return YES;
        default:
            return NO;
    }
}

- (NSIndexPath*) tableView:(UITableView*)tableView
targetIndexPathForMoveFromRowAtIndexPath:(NSIndexPath*)sourceIndexPath
                     toProposedIndexPath:(NSIndexPath*)proposedDestinationIndexPath
{
    if ([sourceIndexPath section] != [proposedDestinationIndexPath section])
    {
        // Prevent row movement outside of the row's section by limiting a rows destination index path to either the top
        // or the bottom of the section.
        NSUInteger rowInSourceSection = ([sourceIndexPath section] > [proposedDestinationIndexPath section]) ?
                0 : (NSUInteger) [tableView numberOfRowsInSection:[sourceIndexPath section]];
        return [NSIndexPath indexPathForRow:rowInSourceSection inSection:[sourceIndexPath section]];
    }

    return proposedDestinationIndexPath;
}

- (void) tableView:(UITableView*)tableView
commitEditingStyle:(UITableViewCellEditingStyle)editingStyle
 forRowAtIndexPath:(NSIndexPath*)indexPath
{
    if ([indexPath section] == SECTION_WAYPOINTS && editingStyle == UITableViewCellEditingStyleDelete)
    {
        // Modify the model before the modifying the view.
        [_flightRoute removeWaypointAtIndex:(NSUInteger) [indexPath row]];
        // Make the flight route table view match the change in the model, using UIKit animations to display the change.
        NSArray* indexPaths = [NSArray arrayWithObject:indexPath];
        [tableView deleteRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationAutomatic];
    }
}

- (void) tableView:(UITableView*)tableView
moveRowAtIndexPath:(NSIndexPath*)sourceIndexPath
       toIndexPath:(NSIndexPath*)destinationIndexPath
{
    if ([sourceIndexPath section] == SECTION_WAYPOINTS
     && [destinationIndexPath section] == SECTION_WAYPOINTS)
    {
        [_flightRoute moveWaypointAtIndex:(NSUInteger) [sourceIndexPath row]
                                 toIndex:(NSUInteger) [destinationIndexPath row]];
    }
}

- (void) didPickAltitude:(AltitudePicker*)sender
{
    [_flightRoute setAltitude:[sender altitude]];

    NSArray* indexPath = [NSArray arrayWithObject:[NSIndexPath indexPathForRow:ROW_ALTITUDE inSection:SECTION_PROPERTIES]];
    [flightRouteTable reloadRowsAtIndexPaths:indexPath withRowAnimation:UITableViewRowAnimationAutomatic];
}

- (void) didPickColor:(ColorPicker*)sender
{
    [_flightRoute setColorIndex:(NSUInteger) [sender selectedColorIndex]];

    NSArray* indexPath = [NSArray arrayWithObject:[NSIndexPath indexPathForRow:ROW_COLOR inSection:SECTION_PROPERTIES]];
    [flightRouteTable reloadRowsAtIndexPaths:indexPath withRowAnimation:UITableViewRowAnimationAutomatic];
}

- (void) didChooseWaypoint:(Waypoint*)waypoint
{
    // Modify the model before the modifying the view. Get the waypoint to insert from the waypoint table, then
    // append it to the flight route model.
    NSUInteger index = [_flightRoute waypointCount];
    [_flightRoute insertWaypoint:waypoint atIndex:index];

    // Make the flight route table view match the change in the model, using UIKit animations to display the change.
    // The index path's row indicates the row index that has been inserted.
    NSIndexPath* indexPath = [NSIndexPath indexPathForRow:index inSection:SECTION_WAYPOINTS];
    NSArray* indexPathArray = [NSArray arrayWithObject:indexPath];
    [flightRouteTable insertRowsAtIndexPaths:indexPathArray withRowAnimation:UITableViewRowAnimationFade];
    [flightRouteTable scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionNone animated:YES];
}

@end