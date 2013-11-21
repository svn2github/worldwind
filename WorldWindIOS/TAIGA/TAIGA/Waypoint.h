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
    WaypointTypeOther
} WaypointType;

@interface Waypoint : NSObject

@property (nonatomic, readonly) NSString* key;

@property (nonatomic, readonly) WWLocation* location;

@property (nonatomic, readonly) WaypointType type;

@property (nonatomic) NSString* displayName;

@property (nonatomic) NSString* displayNameLong;

@property (nonatomic) NSDictionary* properties;

- (Waypoint*) initWithKey:(NSString*)key location:(WWLocation*)location type:(WaypointType)type;

@end