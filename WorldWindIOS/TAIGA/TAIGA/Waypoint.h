/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.

 @version $Id$
 */

#import <Foundation/Foundation.h>

@interface Waypoint : NSObject
{
@protected
    NSString* description;
    NSString* descriptionWithAltitude;
}

@property (nonatomic, readonly) double latitude;

@property (nonatomic, readonly) double longitude;

@property (nonatomic, readonly) double altitude;

@property (nonatomic, readonly) NSDictionary* properties;

- (id) initWithDegreesLatitude:(double)latitude longitude:(double)longitude metersAltitude:(double)altitude;

- (id) initWithWaypoint:(Waypoint*)waypoint metersAltitude:(double)altitude;

- (id) initWithWaypointTableRow:(NSDictionary*)values;

- (id) initWithPropertyList:(NSDictionary*)propertyList;

- (NSDictionary*) asPropertyList;

- (NSString*) description;

- (NSString*) descriptionWithAltitude;

@end