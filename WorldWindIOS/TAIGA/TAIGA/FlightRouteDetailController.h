/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.

 @version $Id$
 */

#import <Foundation/Foundation.h>

@class FlightRoute;
@class WaypointDatabase;
@class WaypointFileControl;
@class BulkRetrieverController;
@class WorldWindView;

@interface FlightRouteDetailController : UIViewController<UITableViewDataSource, UITableViewDelegate>
{
@protected
    UITableView* flightRouteTable;
    WaypointFileControl* waypointFileControl;
    BulkRetrieverController* bulkRetrieverController;
    NSArray* normalConstraints;
    NSArray* editingConstraints;
}

@property (nonatomic, readonly, weak) FlightRoute* flightRoute;

@property (nonatomic, readonly, weak) WaypointDatabase* waypointDatabase;

@property (nonatomic, readonly, weak) WorldWindView* wwv;

- (FlightRouteDetailController*) initWithFlightRoute:(FlightRoute*)flightRoute
                                    waypointDatabase:(WaypointDatabase*)waypointDatabase
                                                view:(WorldWindView*)wwv;

@end