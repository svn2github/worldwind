/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.

 @version $Id$
 */

#import "WaypointFileControl.h"
#import "WaypointFile.h"
#import "Waypoint.h"

@implementation WaypointFileControl

//--------------------------------------------------------------------------------------------------------------------//
//-- Initializing WaypointTableViews --//
//--------------------------------------------------------------------------------------------------------------------//

- (WaypointFileControl*) initWithFrame:(CGRect)frame target:(id)target action:(SEL)action
{
    self = [super initWithFrame:frame];

    _target = target;
    _action = action;
    waypoints = nil;

    waypointSearchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(0, 0, 1, 1)];
    [waypointSearchBar setPlaceholder:@"Search or enter an FAA code"];
    [waypointSearchBar setDelegate:self];
    [self addSubview:waypointSearchBar];

    waypointTable = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, 1, 1) style:UITableViewStylePlain];
    [waypointTable setDataSource:self];
    [waypointTable setDelegate:self];
    [waypointTable setAllowsSelectionDuringEditing:YES];
    [waypointTable setEditing:YES];
    [self addSubview:waypointTable];

    // Disable automatic translation of autoresizing mask into constraints. We're using explicit layout constraints
    // below.
    [waypointSearchBar setTranslatesAutoresizingMaskIntoConstraints:NO];
    [waypointTable setTranslatesAutoresizingMaskIntoConstraints:NO];

    NSDictionary* viewsDictionary = NSDictionaryOfVariableBindings(waypointSearchBar, waypointTable);
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[waypointSearchBar]|"
                                                                 options:0 metrics:nil views:viewsDictionary]];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[waypointTable]|"
                                                                 options:0 metrics:nil views:viewsDictionary]];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[waypointSearchBar(44)]-[waypointTable]|"
                                                                 options:0 metrics:nil views:viewsDictionary]];

    return self;
}

- (void) setWaypointFile:(WaypointFile*)waypointFile
{
    _waypointFile = waypointFile;

    [self filterWaypoints];
    [waypointTable reloadData];
}

- (void) filterWaypoints
{
    NSString* searchText = [waypointSearchBar text];
    if ([searchText length] == 0)
    {
        waypoints = [_waypointFile waypoints];
    }
    else
    {
        NSString* wildSearchText = [NSString stringWithFormat:@"*%@*", searchText];
        waypoints = [_waypointFile waypointsMatchingText:wildSearchText];
    }

    [waypointTable reloadData];
}

- (void) flashScrollIndicators
{
    [waypointTable flashScrollIndicators];
}

- (void) sendActionForWaypoint:(Waypoint*)waypoint
{
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    [_target performSelector:_action withObject:waypoint];
#pragma clang diagnostic pop
}

//--------------------------------------------------------------------------------------------------------------------//
//-- UISearchBarDelegate --//
//--------------------------------------------------------------------------------------------------------------------//

- (void) searchBar:(UISearchBar*)searchBar textDidChange:(NSString*)searchText
{
    [self filterWaypoints];
}

- (void) searchBarSearchButtonClicked:(UISearchBar*)searchBar
{
    [self filterWaypoints];
}

//--------------------------------------------------------------------------------------------------------------------//
//-- UITableViewDataSource and UITableViewDelegate --//
//--------------------------------------------------------------------------------------------------------------------//

- (NSInteger) numberOfSectionsInTableView:(UITableView*)tableView
{
    return 1;
}

- (NSInteger) tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section
{
    return [waypoints count];
}

- (UITableViewCell*) tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
    static NSString* cellIdentifier = @"cell";
    UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (cell == nil)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellIdentifier];
    }

    Waypoint* waypoint = [waypoints objectAtIndex:(NSUInteger) [indexPath row]];
    [[cell textLabel] setText:[waypoint displayName]];
    [[cell detailTextLabel] setText:[waypoint displayNameLong]];

    return cell;
}

- (BOOL) tableView:(UITableView*)tableView canEditRowAtIndexPath:(NSIndexPath*)indexPath
{
    return YES;
}

- (UITableViewCellEditingStyle) tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return UITableViewCellEditingStyleInsert;
}

- (void) tableView:(UITableView*)tableView
commitEditingStyle:(UITableViewCellEditingStyle)editingStyle
 forRowAtIndexPath:(NSIndexPath*)indexPath
{
    Waypoint* waypoint = [waypoints objectAtIndex:(NSUInteger) [indexPath row]];
    [self sendActionForWaypoint:waypoint];
}

- (void) tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    if ([waypoints count] > 0)
    {
        Waypoint* waypoint = [waypoints objectAtIndex:(NSUInteger) [indexPath row]];
        [self sendActionForWaypoint:waypoint];
    }
}

@end