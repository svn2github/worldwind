/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import <Foundation/Foundation.h>
#import "DDLog.h"

static const int ddLogLevel = LOG_LEVEL_INFO;

#define TAIGA_VERSION (@"1.003")
#define TAIGA_VERSION_DATE (@"10/3/14")

#define TAIGA_DATA_HOST @"worldwindserver.net"

#define TAIGA_CURRENT_AIRCRAFT_POSITION (@"gov.nasa.worldwind.taiga.currentaircraftposition")
#define TAIGA_DATA_FILE_ID (@"gov.nasa.worldwind.taiga.data.file.id")
#define TAIGA_DATA_FILE_NUM_FILES_EXTRACTED (@"gov.nasa.worldwind.taiga.data.file.num.files.extracted")
#define TAIGA_DATA_FILE_INSTALLATION_PROGRESS (@"gov.nasa.worldwind.taiga.data.file.installation.progress")
#define TAIGA_DEFAULT_LOCATION_TRACKING_MODE (TAIGA_LOCATION_TRACKING_MODE_NORTH_UP)
#define TAIGA_EARTH_RADIUS (6378137.0)
#define TAIGA_FLIGHT_ROUTE_REMOVED (@"gov.nasa.worldwind.taiga.flightroute.removed")
#define TAIGA_FLIGHT_ROUTE_ALL_WAYPOINTS_CHANGED (@"gov.nasa.worldwind.taiga.flightroute.allwaypoints.changed")
#define TAIGA_FLIGHT_ROUTE_ATTRIBUTE_CHANGED (@"gov.nasa.worldwind.taiga.flightroute.attribute.changed")
#define TAIGA_FLIGHT_ROUTE_WAYPOINT_INDEX (@"gov.nasa.worldwind.taiga.flightroute.waypoint.index")
#define TAIGA_FLIGHT_ROUTE_WAYPOINT_INSERTED (@"gov.nasa.worldwind.taiga.flightroute.waypoint.inserted")
#define TAIGA_FLIGHT_ROUTE_WAYPOINT_REMOVED (@"gov.nasa.worldwind.taiga.flightroute.waypoint.removed")
#define TAIGA_FLIGHT_ROUTE_WAYPOINT_REPLACED (@"gov.nasa.worldwind.taiga.flightroute.waypoint.replaced")
#define TAIGA_FLIGHT_ROUTE_WAYPOINT_MOVED (@"gov.nasa.worldwind.taiga.flightroute.waypoint.moved")
#define TAIGA_GDB_DEVICE_ADDRESS (@"gov.nasa.worldwind.taiga.gdb.device.address")
#define TAIGA_GDB_DEVICE_UPDATE_FREQUENCY (@"gov.nasa.worldwind.taiga.gdb.device.update.frequency")
#define TAIGA_GDB_MESSAGE (@"gov.nasa.worldwind.taiga.gdb.message")
#define TAIGA_GPS_DEVICE_ADDRESS (@"gov.nasa.worldwind.taiga.gpsaddress")
#define TAIGA_GPS_DEVICE_UPDATE_FREQUENCY (@"gov.nasa.worldwind.taiga.gps.device.update.frequency")
#define TAIGA_GPS_QUALITY (@"gov.nasa.worldwind.taiga.gpsfixquality")
#define TAIGA_GPS_SOURCE (@"gov.nasa.worldwind.taiga.gpssource")
#define TAIGA_HIDDEN_LAYER (@"gov.nasa.worldwind.taiga.hiddenlayer")
#define TAIGA_KNOTS_TO_METERS_PER_SECOND (0.51444444444)
#define TAIGA_LOCATION_TRACKING_ENABLED (@"gov.nasa.worldwind.taiga.navigation.enabled")
#define TAIGA_LOCATION_TRACKING_MODE (@"gov.nasa.worldwind.taiga.navigation.mode")
#define TAIGA_LOCATION_TRACKING_MODE_COCKPIT (@"gov.nasa.worldwind.taiga.location.tracking.mode.cockpit")
#define TAIGA_LOCATION_TRACKING_MODE_NORTH_UP (@"gov.nasa.worldwind.taiga.location.tracking.mode.northup")
#define TAIGA_LOCATION_TRACKING_MODE_TRACK_UP (@"gov.nasa.worldwind.taiga.location.tracking.mode.trackup")
#define TAIGA_METERS_TO_FEET (3.28083989501)
#define TAIGA_METERS_TO_NAUTICAL_MILES (0.000539957)
#define TAIGA_NAUTICAL_MILES_TO_METERS (1852)
#define TAIGA_NAME (@"gov.nasa.worldwind.taiga.name")
#define TAIGA_PATH (@"gov.nasa.worldwind.taiga.path")
#define TAIGA_REFRESH (@"gov.nasa.worldwind.taiga.refresh")
#define TAIGA_REFRESH_COMPLETE (@"gov.nasa.worldwind.taiga.refresh.complete")
#define TAIGA_REFRESH_CHART (@"gov.nasa.worldwind.taiga.refresh.chart")
#define TAIGA_SETTING_CHANGED (@"gov.nasa.worldwind.taiga.setting.changed")
#define TAIGA_SHADED_ELEVATION_OFFSET (@"gov.nasa.worldwind.taiga.shadedelevation.offset")
#define TAIGA_SHADED_ELEVATION_OPACITY (@"gov.nasa.worldwind.taiga.shadedelevation.opacity")
#define TAIGA_SHADED_ELEVATION_THRESHOLD_RED (@"gov.nasa.worldwind.taiga.shadedelevation.threshold.red")
#define TAIGA_SHOW_TERRAIN_PROFILE (@"gov.nasa.worldwind.taiga.terrainprofile.show")
#define TAIGA_SIMULATION_WILL_BEGIN (@"gov.nasa.worldwind.taiga.simulationwillbegin")
#define TAIGA_SIMULATION_WILL_END (@"gov.nasa.worldwind.taiga.simulationwillend")
#define TAIGA_TOOLBAR_HEIGHT (80)

@interface AppConstants : NSObject
@end