/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.

 @version $Id$
 */

#import <Foundation/Foundation.h>

@class FlightPath;

@interface FlightPathDetailController : UIViewController<UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate>
{
@protected
    UITableView* flightPathTable;
    UISearchBar* waypointSearchBar;
    UITableView* waypointTable;
    NSArray* normalConstraints;
    NSArray* editingConstraints;
    NSArray* filteredWaypoints;
}

@property (nonatomic, readonly, weak) FlightPath* flightPath;

@property (nonatomic, readonly, weak) NSArray* waypointDatabase;

- (FlightPathDetailController*) initWithFlightPath:(FlightPath*)flightPath waypointDatabase:(NSArray*)waypointDatabase;

@end