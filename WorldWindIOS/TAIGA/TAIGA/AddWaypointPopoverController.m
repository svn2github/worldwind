/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.

 @version $Id$
 */

#import "AddWaypointPopoverController.h"
#import "FlightRoute.h"
#import "Waypoint.h"
#import "MovingMapViewController.h"
#import "UITableViewCell+TAIGAAdditions.h"
#import "WorldWind/Geometry/WWLocation.h"
#import "WorldWind/Geometry/WWPosition.h"
#import "WorldWind/Pick/WWPickedObjectList.h"
#import "WorldWind/Pick/WWPickedObject.h"
#import "WorldWind/WorldWindView.h"

static NSString* AddWaypointActionAdd = @"Add to Route";

@implementation AddWaypointPopoverController

- (id) initWithWaypoint:(Waypoint*)waypoint mapViewController:(MovingMapViewController*)mapViewController
{
    _waypoint = waypoint;
    _mapViewController = mapViewController;
    [self populateAddWaypointTable];
    [self populateFlightRouteTable];

    CGSize size = CGSizeMake(240, 44 * [addWaypointTableCells count]);
    UIImage* rightButtonImage = [UIImage imageNamed:@"all-directions"];
    UIBarButtonItem* rightButtonItem = [[UIBarButtonItem alloc] initWithImage:rightButtonImage style:UIBarButtonItemStylePlain target:nil action:NULL];
    addWaypointController = [[UITableViewController alloc] initWithStyle:UITableViewStylePlain];
    [addWaypointController setPreferredContentSize:size];
    [[addWaypointController navigationItem] setTitle:@"Waypoint"];
//    [[addWaypointController navigationItem] setRightBarButtonItem:rightButtonItem];
    [[addWaypointController tableView] setDataSource:self];
    [[addWaypointController tableView] setDelegate:self];
    [[addWaypointController tableView] setBounces:NO];
    [[addWaypointController tableView] setSeparatorStyle:UITableViewCellSeparatorStyleNone];

    NSUInteger numRows = MIN(4, [flightRouteTableCells count]);
    size = CGSizeMake(320, MAX(44 * numRows, size.height));
    flightRouteChooser = [[UITableViewController alloc] initWithStyle:UITableViewStylePlain];
    [flightRouteChooser setPreferredContentSize:size];
    [[flightRouteChooser navigationItem] setTitle:AddWaypointActionAdd];
    [[flightRouteChooser tableView] setDataSource:self];
    [[flightRouteChooser tableView] setDelegate:self];

    navigationController = [[UINavigationController alloc] initWithRootViewController:addWaypointController];
    [navigationController setDelegate:self];

    self = [super initWithContentViewController:navigationController];

    return self;
}

- (id) initWithPosition:(WWPosition*)position mapViewController:(MovingMapViewController*)mapViewController
{
    Waypoint* waypoint = [[Waypoint alloc] initWithDegreesLatitude:[position latitude] longitude:[position longitude] metersAltitude:[position altitude]];

    self = [self initWithWaypoint:waypoint mapViewController:mapViewController];

    return self;
}

- (void) addSelected
{
    if ([_mapViewController presentedFlightRoute] != nil)
    {
        [self dismissPopoverAnimated:YES];
        [self addConfirmed:[_mapViewController presentedFlightRoute]];
    }
    else
    {
        [navigationController pushViewController:flightRouteChooser animated:YES];
    }
}

- (void) addConfirmed:(FlightRoute*)flightRoute
{
    Waypoint* newWaypoint = [[Waypoint alloc] initWithWaypoint:_waypoint metersAltitude:[flightRoute defaultAltitude]];
    NSUInteger index = [flightRoute waypointCount];
    [flightRoute insertWaypoint:newWaypoint atIndex:index];
}

- (void) flightRouteSelected:(NSUInteger)index
{
    [self dismissPopoverAnimated:YES];

    if (index < [_mapViewController flightRouteCount])
    {
        [self addConfirmed:[_mapViewController flightRouteAtIndex:index]];
        [_mapViewController presentFlightRouteAtIndex:index editing:NO];
    }
    else
    {
        [_mapViewController newFlightRoute:^(FlightRoute* newFlightRoute)
        {
            NSUInteger newIndex = (NSUInteger) [_mapViewController flightRouteCount];
            [_mapViewController insertFlightRoute:newFlightRoute atIndex:newIndex]; // append to the end of the route list
            [_mapViewController presentFlightRouteAtIndex:newIndex editing:YES]; // create new routes in editing mode
            [self addConfirmed:newFlightRoute];
        }];
    }
}

- (BOOL) popoverPointWillChange:(CGPoint)newPoint
{
    WWPickedObjectList* pickedObjects = [[_mapViewController wwv] pickTerrain:newPoint];
    WWPickedObject* terrainObject = [pickedObjects terrainObject];
    if (terrainObject == nil)
    {
        return NO;
    }

    WWPosition* pos = [terrainObject position];
    _waypoint = [[Waypoint alloc] initWithDegreesLatitude:[pos latitude] longitude:[pos longitude] metersAltitude:[pos altitude]];

    // Make the waypoint cell match the change in the waypoint source location. Use UIKit animations to display the
    // change instantaneously.
    NSIndexPath* indexPath = [NSIndexPath indexPathForRow:0 inSection:0];
    [[[addWaypointTableCells objectAtIndex:0] textLabel] setText:[_waypoint descriptionWithAltitude]];
    [[addWaypointController tableView] reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];

    return YES;
}

//--------------------------------------------------------------------------------------------------------------------//
//-- UITableViewDataSource --//
//--------------------------------------------------------------------------------------------------------------------//

- (void) populateAddWaypointTable
{
    addWaypointTableCells = [[NSMutableArray alloc] init];

    UITableViewCell* cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
    [cell setSeparatorInset:UIEdgeInsetsZero];
    [[cell textLabel] setText:[_waypoint descriptionWithAltitude]];
    [[cell textLabel] setTextAlignment:NSTextAlignmentCenter];
    [[cell textLabel] setAdjustsFontSizeToFitWidth:YES];
    [addWaypointTableCells addObject:cell];

    cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
    [[cell textLabel] setText:AddWaypointActionAdd];
    [[cell textLabel] setTextColor:[cell tintColor]];
    [[cell textLabel] setTextAlignment:NSTextAlignmentCenter];
    [addWaypointTableCells addObject:cell];
}

- (void) populateFlightRouteTable
{
    flightRouteTableCells = [[NSMutableArray alloc] init];

    for (NSUInteger index = 0; index < [_mapViewController flightRouteCount]; index++)
    {
        FlightRoute* flightRoute = [_mapViewController flightRouteAtIndex:index];
        UITableViewCell* cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:nil];
        [cell setToFlightRoute:flightRoute];
        [[cell imageView] setImage:nil]; // suppress the flight route enabled checkmark
        [flightRouteTableCells addObject:cell];
    }

    UITableViewCell* cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
    [[cell textLabel] setText:@"New Route..."];
    [flightRouteTableCells addObject:cell];
}

- (NSInteger) tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section
{
    if (tableView == [addWaypointController tableView])
    {
        return [addWaypointTableCells count];
    }
    else // flightRouteChooser
    {
        return [flightRouteTableCells count];
    }
}

- (UITableViewCell*) tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
    if (tableView == [addWaypointController tableView])
    {
        return [addWaypointTableCells objectAtIndex:(NSUInteger) [indexPath row]];
    }
    else // flightRouteChooser
    {
        return [flightRouteTableCells objectAtIndex:(NSUInteger) [indexPath row]];
    }
}

//--------------------------------------------------------------------------------------------------------------------//
//-- UITableViewDelegate --//
//--------------------------------------------------------------------------------------------------------------------//

- (void) tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    NSString* cellText = [[[tableView cellForRowAtIndexPath:indexPath] textLabel] text];
    if ([cellText isEqualToString:AddWaypointActionAdd])
    {
        [self addSelected];
    }
    else if (tableView == [flightRouteChooser tableView])
    {
        [self flightRouteSelected:(NSUInteger) [indexPath row]];
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
    [self setDragEnabled:viewController == addWaypointController];
}

@end