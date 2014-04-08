/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.

 @version $Id$
 */

#import <Foundation/Foundation.h>

@class WWLocation;

typedef enum
{
    WaypointTypeAirport,
    WaypointTypeMarker
} WaypointType;

@interface Waypoint : NSObject
{
@protected
    NSString* _key;
    WaypointType _type;
    double _latitude;
    double _longitude;
    NSString* _displayName;
    NSString* _iconPath;
    UIImage* _iconImage;
    NSDictionary* _properties;
}

- (NSString*) key;

- (WaypointType) type;

- (double) latitude;

- (double) longitude;

- (NSString*) displayName;

- (NSString*) iconPath;

- (UIImage*) iconImage;

- (NSDictionary*) properties;

- (id) initWithKey:(NSString*)key type:(WaypointType)type degreesLatitude:(double)latitude longitude:(double)longitude;

- (id) initWithType:(WaypointType)type degreesLatitude:(double)latitude longitude:(double)longitude;

- (id) initWithWaypointTableRow:(NSDictionary*)values;

- (id) initWithPropertyList:(NSDictionary*)propertyList;

- (NSDictionary*) propertyList;

@end