/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.

 @version $Id$
 */

#import <Foundation/Foundation.h>

@class Waypoint;

@interface WaypointDatabase : NSObject
{
@protected
    NSMutableDictionary* waypoints;
    NSMutableSet* waypointStateKeys;
}

- (void) addWaypoint:(Waypoint*)waypoint;

- (void) addWaypointsFromTable:(NSString*)urlString completionBlock:(void(^)(void))completionBlock;

- (NSArray*) waypoints;

- (NSArray*) waypointsSortedByName;

- (NSArray*) waypointsSortedByNameMatchingText:(NSString*)text;

- (Waypoint*) waypointForKey:(NSString*)key;

@end