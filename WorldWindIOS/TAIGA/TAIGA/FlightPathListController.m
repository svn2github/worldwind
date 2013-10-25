/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.

 @version $Id$
 */

#import "FlightPathListController.h"
#import "FlightPathDetailController.h"
#import "FlightPath.h"
#import "Waypoint.h"
#import "WorldWind/Geometry/WWLocation.h"
#import "WorldWind/Util/WWRetriever.h"
#import "WorldWind/WorldWindConstants.h"
#import "WorldWind/WWLog.h"

#define TAIGA_FLIGHT_PATH_KEYS (@"gov.nasa.worldwind.taiga.flightpathkeys")
#define TAIGA_DAFIF_AIRPORTS_URL (@"http://worldwindserver.net/taiga/dafif/ARPT2_ALASKA.TXT")
#define TAIGA_DAFIF_AIRPORTS (@"gov.nasa.worldwind.taiga.dafif.airports")

@implementation FlightPathListController

- (FlightPathListController*) init
{
    self = [super initWithStyle:UITableViewStylePlain];

    UIBarButtonItem* addButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd
                                                                                   target:self
                                                                                   action:@selector(handleAddButtonTap)];
    [[self navigationItem] setTitle:@"Flight Paths"];
    [[self navigationItem] setLeftBarButtonItem:addButtonItem];
    [[self navigationItem] setRightBarButtonItem:[self editButtonItem]];
    [self setPreferredContentSize:CGSizeMake(350, 1000)];

    flightPaths = [[NSMutableArray alloc] init];
    waypointDatabase = [[NSMutableArray alloc] init];
    [self populateWaypointDatabase];

    return self;
}

- (void) viewDidLoad
{
    [super viewDidLoad];
}

- (void) navigationController:(UINavigationController*)navigationController
       willShowViewController:(UIViewController*)viewController
                     animated:(BOOL)animated
{
    // This keeps all the nested popover controllers the same size as this top-level controller.
    viewController.preferredContentSize = navigationController.topViewController.view.frame.size;
}

- (NSInteger) numberOfSectionsInTableView:(UITableView*)tableView
{
    return 1;
}

- (NSInteger) tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section
{
    return [flightPaths count];
}

- (UITableViewCell*) tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
    static NSString* cellIdentifier = @"cell";

    UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (cell == nil)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
        [cell setAccessoryType:UITableViewCellAccessoryDetailButton];
        [[cell imageView] setImage:[UIImage imageNamed:@"431-yes.png"]];
    }

    FlightPath* path = [flightPaths objectAtIndex:(NSUInteger) [indexPath row]];
    [[cell textLabel] setText:[path displayName]];
    [[cell imageView] setHidden:![path enabled]];

    return cell;
}

- (void) tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath
{
    // Set the flight path's visibility. Modify the model before the modifying the view.
    FlightPath* path = [flightPaths objectAtIndex:(NSUInteger) [indexPath row]];
    [path setEnabled:![path enabled]];

    // Make the view match the change in the model, using UIKit animations to display the change.
    [tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:indexPath]
                     withRowAnimation:UITableViewRowAnimationAutomatic];
}

- (void) tableView:(UITableView*)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath*)indexPath
{
    FlightPath* path = [flightPaths objectAtIndex:(NSUInteger) [indexPath row]];
    UIViewController* pathController = [self viewControllerForFlightPath:path];
    [[self navigationController] pushViewController:pathController animated:YES];
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
        FlightPath* path = [flightPaths objectAtIndex:(NSUInteger) [indexPath row]];
        [flightPaths removeObject:path];
        [self saveFlightPathList];
        [path removeState];
        // Make the view match the change in the model, using UIKit animations to display the change.
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath]
                         withRowAnimation:UITableViewRowAnimationAutomatic];
    }
}

- (void) tableView:(UITableView*)tableView
moveRowAtIndexPath:(NSIndexPath*)sourceIndexPath
       toIndexPath:(NSIndexPath*)destinationIndexPath
{
    FlightPath* path = [flightPaths objectAtIndex:(NSUInteger) [sourceIndexPath row]];
    [flightPaths removeObjectAtIndex:(NSUInteger) [sourceIndexPath row]];
    [flightPaths insertObject:path atIndex:(NSUInteger) [destinationIndexPath row]];
    [self saveFlightPathList];
}

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
        FlightPath* path = [[FlightPath alloc] init];
        [path setDisplayName:[[alertView textFieldAtIndex:0] text]]; // Path name text field
        NSUInteger index = [flightPaths count]; // Append to end of flight paths list.
        [flightPaths insertObject:path atIndex:index];
        [self saveFlightPathList];

        // Make the view match the change in the model. The index path's row indicates the row index that has been
        // inserted. Suppress row animations since we pushing a new view controller below.
        NSIndexPath* indexPath = [NSIndexPath indexPathForRow:index inSection:0];
        [[self tableView] insertRowsAtIndexPaths:[NSArray arrayWithObject:indexPath]
                                withRowAnimation:UITableViewRowAnimationNone];
        [[self tableView] scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionNone
                                        animated:NO];

        // Show the flight path detail controller in its edit state. Suppress animations when transitioning to the edit
        // state since we're pushing a new view controller.
        UIViewController* pathController = [self viewControllerForFlightPath:path];
        [pathController setEditing:YES animated:NO];
        [[self navigationController] pushViewController:pathController animated:YES];
    }
}

- (UIViewController*) viewControllerForFlightPath:(FlightPath*)path
{
    return [[FlightPathDetailController alloc] initWithFlightPath:path waypointDatabase:waypointDatabase];
}

- (void) populateWaypointDatabase
{
    NSURL* url = [NSURL URLWithString:TAIGA_DAFIF_AIRPORTS_URL];
    WWRetriever* retriever = [[WWRetriever alloc] initWithUrl:url timeout:5
                                                finishedBlock:^(WWRetriever* myRetriever)
                                                {
                                                    [self finishRetrievingDAFIFFile:myRetriever];
                                                    [self didPopulateWaypointsDatabase];
                                                }];
    [retriever setUserData:TAIGA_DAFIF_AIRPORTS];
    [retriever performRetrieval];
}

- (void) didPopulateWaypointsDatabase
{
    [self restoreFlightPathList];
}

- (void) finishRetrievingDAFIFFile:(WWRetriever*)retriever
{
    NSString* cacheDir = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString* cachePath = [cacheDir stringByAppendingPathComponent:[[retriever url] path]];

    if ([[retriever status] isEqualToString:WW_SUCCEEDED] && [[retriever retrievedData] length] > 0)
    {
        // If the retrieval was successful, cache the retrieved TOC and parse its contents directly from the retriever.
        [[retriever retrievedData] writeToFile:cachePath atomically:YES];
        [self parseDAFIFTable:[retriever retrievedData] encoding:NSWindowsCP1252StringEncoding dafifType:[retriever userData]];
    }
    else
    {
        // Otherwise, attempt to use a previously cached version.
        NSData* data = [NSData dataWithContentsOfFile:cachePath];
        if (data != nil)
        {
            [self parseDAFIFTable:data encoding:NSWindowsCP1252StringEncoding dafifType:[retriever userData]];
        }
        else
        {
            WWLog(@"Unable to retrieve or use local cache of DAFIF file %@", [[retriever url] absoluteString]);
        }
    }
}

- (void) parseDAFIFTable:(NSData*)data encoding:(NSStringEncoding)encoding dafifType:(id)type
{
    NSString* string = [[NSString alloc] initWithData:data encoding:encoding];
    NSMutableArray* fieldNames = [[NSMutableArray alloc] initWithCapacity:8];
    NSMutableArray* tableRows = [[NSMutableArray alloc] initWithCapacity:8];

    [string enumerateLinesUsingBlock:^(NSString* line, BOOL* stop)
    {
        NSArray* lineComponents = [line componentsSeparatedByString:@"\t"];

        if ([fieldNames count] == 0) // first line indicates DAFIF table field names
        {
            [fieldNames addObjectsFromArray:lineComponents];
        }
        else // subsequent lines indicate DAFIF table row values
        {
            NSMutableDictionary* rowValues = [[NSMutableDictionary alloc] init];
            for (NSUInteger i = 0; i < [lineComponents count] && i < [fieldNames count]; i++)
            {
                [rowValues setObject:[lineComponents objectAtIndex:i] forKey:[fieldNames objectAtIndex:i]];
            }

            [tableRows addObject:rowValues];
        }
    }];

    [self parseDAFIFTableRows:tableRows dafifType:type];
}

- (void) parseDAFIFTableRows:(NSArray*)tableRows dafifType:(id)type
{
    if ([type isEqual:TAIGA_DAFIF_AIRPORTS])
    {
        for (NSDictionary* row in tableRows)
        {
            NSString* key = [row objectForKey:@"ARPT_IDENT"];
            double latDegrees = [[row objectForKey:@"WGS_DLAT"] doubleValue];
            double lonDegrees = [[row objectForKey:@"WGS_DLON"] doubleValue];
            WWLocation* location = [[WWLocation alloc] initWithDegreesLatitude:latDegrees longitude:lonDegrees];

            Waypoint* waypoint = [[Waypoint alloc] initWithKey:key location:location];
            [waypoint setProperties:row];
            [waypoint setDisplayName:[row objectForKey:@"FAA_HOST_ID"]];
            [waypoint setDisplayNameLong:[row objectForKey:@"NAME"]];
            [waypointDatabase addObject:waypoint];
        }
    }
    else
    {
        WWLog(@"Unrecognized DAFIF table type");
    }

    [waypointDatabase sortUsingComparator:^(id obj1, id obj2)
    {
        return [[obj1 displayName] compare:[obj2 displayName]];
    }];
}

- (void) saveFlightPathList
{
    NSMutableArray* flightPathKeys = [NSMutableArray arrayWithCapacity:[flightPaths count]];

    for (FlightPath* path in flightPaths)
    {
        [flightPathKeys addObject:[path stateKey]];
    }

    [[NSUserDefaults standardUserDefaults] setObject:flightPathKeys forKey:TAIGA_FLIGHT_PATH_KEYS];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void) restoreFlightPathList
{
    NSArray* flightPathKeys = [[NSUserDefaults standardUserDefaults] objectForKey:TAIGA_FLIGHT_PATH_KEYS];

    for (NSString* key in flightPathKeys)
    {
        FlightPath* path = [[FlightPath alloc] initWithStateKey:key waypointDatabase:waypointDatabase];
        [flightPaths addObject:path];
    }
}

@end