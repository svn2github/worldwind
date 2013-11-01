/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.

 @version $Id$
 */

#import <Foundation/Foundation.h>

@class FlightPath;
@class WaypointFile;
@class WaypointChooserControl;

@interface FlightPathDetailController : UIViewController<UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate>
{
@protected
    UITableView* flightPathTable;
    WaypointChooserControl * waypointChooser;
    NSArray* normalConstraints;
    NSArray* editingConstraints;
}

@property (nonatomic, readonly, weak) FlightPath* flightPath;

@property (nonatomic, readonly, weak) WaypointFile* waypointFile;

- (FlightPathDetailController*) initWithFlightPath:(FlightPath*)flightPath waypointFile:(WaypointFile*)waypointFile;

@end