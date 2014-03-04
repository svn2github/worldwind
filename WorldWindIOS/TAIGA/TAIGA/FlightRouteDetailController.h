/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.

 @version $Id$
 */

#import <Foundation/Foundation.h>

@class FlightRoute;
@class WaypointFile;
@class WaypointFileControl;
@class BulkRetrieverController;
@class WorldWindView;

@interface FlightRouteDetailController : UIViewController<UITableViewDataSource, UITableViewDelegate>
{
@protected
    NSNumberFormatter* altitudeFormatter;
    UITableView* flightRouteTable;
    WaypointFileControl* waypointFileControl;
    BulkRetrieverController* bulkRetrieverController;
    NSArray* normalConstraints;
    NSArray* editingConstraints;
}

@property (nonatomic, readonly, weak) FlightRoute* flightRoute;

@property (nonatomic, readonly, weak) WaypointFile* waypointFile;

@property (nonatomic, readonly, weak) WorldWindView* wwv;

- (FlightRouteDetailController*) initWithFlightRoute:(FlightRoute*)flightRoute
                                        waypointFile:(WaypointFile*)waypointFile
                                                view:(WorldWindView*)wwv;

@end