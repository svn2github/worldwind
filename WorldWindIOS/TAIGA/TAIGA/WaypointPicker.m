/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.

 @version $Id$
 */

#import "WaypointPicker.h"
#import "Waypoint.h"

@implementation WaypointPicker

//--------------------------------------------------------------------------------------------------------------------//
//-- Initializing WaypointTableViews --//
//--------------------------------------------------------------------------------------------------------------------//

- (id) initWithFrame:(CGRect)frame target:(id)target action:(SEL)action
{
    self = [super initWithFrame:frame];

    _target = target;
    _action = action;
    filteredWaypoints = [[NSMutableArray alloc] init];

    waypointSearchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(0, 0, 1, 1)];
    [waypointSearchBar setPlaceholder:@"Search or enter an ICAO code"];
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
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[waypointSearchBar(44)][waypointTable]|"
                                                                 options:0 metrics:nil views:viewsDictionary]];

    return self;
}

- (void) setWaypoints:(NSArray*)waypoints
{
    _waypoints = waypoints;

    [self filterWaypoints];
    [waypointTable reloadData];
}

- (void) filterWaypoints
{
    [filteredWaypoints removeAllObjects];
    [filteredWaypoints addObjectsFromArray:_waypoints];

    NSString* searchText = [waypointSearchBar text];
    if ([searchText length] > 0)
    {
        NSString* wildSearchText = [NSString stringWithFormat:@"*%@*", searchText];
        NSPredicate* predicate = [NSPredicate predicateWithFormat:@"description LIKE[cd] %@ ", wildSearchText];
        [filteredWaypoints filterUsingPredicate:predicate];
    }

    [filteredWaypoints sortUsingComparator:^(id waypointA, id waypointB)
    {
        return [[waypointA description] compare:[waypointB description]];
    }];

    [waypointTable reloadData];
}

- (void) didSelectWaypointForIndex:(NSUInteger)index
{
    Waypoint* waypoint = [filteredWaypoints objectAtIndex:index];
    [self sendActionForWaypoint:waypoint];

    [waypointSearchBar setText:nil]; // clear search field after waypoint selection
    [self filterWaypoints];
}

- (void) sendActionForWaypoint:(Waypoint*)waypoint
{
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    [_target performSelector:_action withObject:waypoint];
#pragma clang diagnostic pop
}

- (void) flashScrollIndicators
{
    [waypointTable flashScrollIndicators];
}

- (BOOL) resignFirstResponder
{
    return [waypointSearchBar resignFirstResponder];
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
    [searchBar resignFirstResponder];
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
    return [filteredWaypoints count];
}

- (UITableViewCell*) tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
    static NSString* cellIdentifier = @"cell";
    UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (cell == nil)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
        [[cell textLabel] setAdjustsFontSizeToFitWidth:YES];
    }

    Waypoint* waypoint = [filteredWaypoints objectAtIndex:(NSUInteger) [indexPath row]];
    [[cell textLabel] setText:[waypoint description]];

    return cell;
}

- (BOOL) tableView:(UITableView*)tableView canEditRowAtIndexPath:(NSIndexPath*)indexPath
{
    return YES;
}

- (UITableViewCellEditingStyle) tableView:(UITableView*)tableView editingStyleForRowAtIndexPath:(NSIndexPath*)indexPath
{
    return UITableViewCellEditingStyleInsert;
}

- (void) tableView:(UITableView*)tableView
commitEditingStyle:(UITableViewCellEditingStyle)editingStyle
 forRowAtIndexPath:(NSIndexPath*)indexPath
{
    [self didSelectWaypointForIndex:(NSUInteger) [indexPath row]];
}

- (void) tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    [self didSelectWaypointForIndex:(NSUInteger) [indexPath row]];
}

@end