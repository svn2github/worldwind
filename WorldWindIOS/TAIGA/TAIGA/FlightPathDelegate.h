/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.

 @version $Id$
 */

#import <Foundation/Foundation.h>

@class FlightPath;
@class Waypoint;

@protocol FlightPathDelegate <NSObject>

- (void) flightPathDidChange:(FlightPath*)flightPath;

- (void) flightPath:(FlightPath*)flightPath didInsertWaypoint:(Waypoint*)waypoint atIndex:(NSUInteger)index;

- (void) flightPath:(FlightPath*)flightPath didRemoveWaypoint:(Waypoint*)waypoint atIndex:(NSUInteger)index;

- (void) flightPath:(FlightPath*)flightPath didMoveWaypoint:(Waypoint*)waypoint fromIndex:(NSUInteger)fromIndex toIndex:(NSUInteger)toIndex;

@end