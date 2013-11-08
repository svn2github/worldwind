/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.

 @version $Id$
 */

#import <Foundation/Foundation.h>

@class FlightRoute;
@class WaypointFile;
@class WaypointChooserControl;

@interface FlightRouteDetailController : UIViewController<UITableViewDataSource, UITableViewDelegate>
{
@protected
    NSNumberFormatter* altitudeFormatter;
    UITableView* flightRouteTable;
    WaypointChooserControl* waypointFileControl;
    NSArray* normalConstraints;
    NSArray* editingConstraints;
}

@property (nonatomic, readonly, weak) FlightRoute* flightRoute;

@property (nonatomic, readonly, weak) WaypointFile* waypointFile;

- (FlightRouteDetailController*) initWithFlightRoute:(FlightRoute*)flightRoute waypointFile:(WaypointFile*)waypointFile;

@end