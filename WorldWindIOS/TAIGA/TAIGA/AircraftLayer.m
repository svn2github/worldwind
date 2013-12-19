/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.

 @version $Id$
 */

#import "AircraftLayer.h"
#import "AircraftShape.h"
#import "AppConstants.h"
#import "FlightRoute.h"
#import "WorldWind/Geometry/WWLocation.h"
#import "WorldWind/Shapes/WWShapeAttributes.h"
#import "WorldWind/Util/WWColor.h"

@implementation AircraftLayer

- (AircraftLayer*) init
{
    self = [super init];

    [self setDisplayName:@"Aircraft"];
    [self setEnabled:NO]; // disable the aircraft shape until we have a valid aircraft position

    aircraftShape = [self createAircraftShape];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(aircraftPositionDidChange:)
                                                 name:TAIGA_CURRENT_AIRCRAFT_POSITION object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(flightRouteDidChange:)
                                                 name:TAIGA_FLIGHT_ROUTE_CHANGED object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(simulationDidBegin:)
                                                 name:TAIGA_SIMULATION_DID_BEGIN object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(simulationDidEnd:)
                                                 name:TAIGA_SIMULATION_DID_END object:nil];

    return self;
}

- (void) doRender:(WWDrawContext*)dc
{
    [aircraftShape render:dc];
}

- (id) createAircraftShape
{
    WWShapeAttributes* shapeAttrs = [[WWShapeAttributes alloc] init];
    [shapeAttrs setInteriorColor:[[WWColor alloc] initWithR:0.027 g:0.596 b:0.976 a:1]];
    [shapeAttrs setOutlineColor:[[WWColor alloc] initWithR:1 g:1 b:1 a:1]];
    [shapeAttrs setOutlineWidth:2];

    AircraftShape* shape = [[AircraftShape alloc] initWithSizeInPixels:40 minSize:10 maxSize:DBL_MAX];
    [shape setAttributes:shapeAttrs];

    return shape;
}

- (void) updateAircraftShape:(id)shape withLocation:(CLLocation*)location
{
    [shape setLocation:location];
}

- (void) aircraftPositionDidChange:(NSNotification*)notification
{
    CLLocation* location = [notification object];
    [self updateAircraftShape:aircraftShape withLocation:location];
}

- (void) flightRouteDidChange:(NSNotification*)notification
{
    if (simulatedFlightRoute == [notification object])
    {
        // Enable the aircraft layer if the flight route is not nil and has at least one waypoint.
        [self setEnabled:simulatedFlightRoute != nil && [simulatedFlightRoute waypointCount] > 0];
    }
}

- (void) simulationDidBegin:(NSNotification*)notification
{
    // Enable the aircraft layer if the flight route is not nil and has at least one waypoint.
    simulatedFlightRoute = [notification object];
    [self setEnabled:simulatedFlightRoute != nil && [simulatedFlightRoute waypointCount] > 0];
}

- (void) simulationDidEnd:(NSNotification*)notification
{
    simulatedFlightRoute = nil;
    [self setEnabled:NO];
}

@end