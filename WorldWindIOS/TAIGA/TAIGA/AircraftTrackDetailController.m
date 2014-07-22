/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.

 @version $Id$
 */

#import "AircraftTrackDetailController.h"
#import "AircraftTrackLayer.h"
#import "TAIGA.h"
#import "UnitsFormatter.h"
#import "AltitudePicker.h"

#define MARKER_DISTANCE_CELL_ID (@"markerDistanceCellId")
#define CLEAR_ALL_CELL_ID (@"clearAllCellId")

@implementation AircraftTrackDetailController

- (id) initWithLayer:(AircraftTrackLayer*)layer
{
    self = [super initWithStyle:UITableViewStyleGrouped];

    _layer = layer;
    [self populateTableCells];

    return self;
}

- (void) markerDistanceSelected
{
    AltitudePicker* picker = [[AltitudePicker alloc] initWithFrame:CGRectMake(0, 44, 1, 216)];
    [picker addTarget:self action:@selector(didPickMarkerDistance:) forControlEvents:UIControlEventValueChanged];
    [picker setMinimumAltitude:30.48]; // 100ft
    [picker setMaximumAltitude:1524]; // 5,000ft
    [picker setAltitudeInterval:30.48]; // 100ft interval
    [picker setAltitude:[_layer markerDistance]];

    UIViewController* viewController = [[UIViewController alloc] init];
    [viewController setView:picker];
    [viewController setTitle:@"Marker Distance"];
    [[self navigationController] pushViewController:viewController animated:YES];
}

- (void) didPickMarkerDistance:(id)sender
{
    [_layer setMarkerDistance:[sender altitude]];

    NSIndexPath* indexPath = [NSIndexPath indexPathForRow:0 inSection:0];
    [[self tableView] reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
}

- (void) clearAllSelected
{
    [_layer removeAllMarkers];
}

//--------------------------------------------------------------------------------------------------------------------//
//-- UITableViewDataSource --//
//--------------------------------------------------------------------------------------------------------------------//

- (void) populateTableCells
{
    tableCells = [[NSMutableArray alloc] init];

    UITableViewCell* cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:MARKER_DISTANCE_CELL_ID];
    [[cell textLabel] setText:@"Marker Distance"];
    [cell setAccessoryType:UITableViewCellAccessoryDisclosureIndicator];
    [tableCells addObject:cell];

    cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CLEAR_ALL_CELL_ID];
    [[cell textLabel] setText:@"Clear All"];
    [[cell textLabel] setTextColor:[cell tintColor]];
    [tableCells addObject:cell];
}

- (NSInteger) tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section
{
    return [tableCells count];
}

- (UITableViewCell*) tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
    UITableViewCell* cell = [tableCells objectAtIndex:(NSUInteger) [indexPath row]];

    if ([[cell reuseIdentifier] isEqualToString:MARKER_DISTANCE_CELL_ID])
    {
        [[cell detailTextLabel] setText:[[TAIGA unitsFormatter] formatMetersAltitude:[_layer markerDistance]]];
    }

    return cell;
}

- (NSString*) tableView:(UITableView*)tableView titleForHeaderInSection:(NSInteger)section
{
    if (section == 0)
    {
        return @"Layer Controls";
    }
    else
    {
        return nil;
    }
}

//--------------------------------------------------------------------------------------------------------------------//
//-- UITableViewDelegate --//
//--------------------------------------------------------------------------------------------------------------------//

- (void) tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    UITableViewCell* cell = [tableView cellForRowAtIndexPath:indexPath];
    if ([[cell reuseIdentifier] isEqualToString:MARKER_DISTANCE_CELL_ID])
    {
        [self markerDistanceSelected];
    }
    else if ([[cell reuseIdentifier] isEqualToString:CLEAR_ALL_CELL_ID])
    {
        [self clearAllSelected];
    }
}

@end