/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.

 @version $Id$
 */

#import "Waypoint.h"
#import "UnitsFormatter.h"
#import "TAIGA.h"
#import "AppConstants.h"
#import "WorldWind/WWLog.h"

@implementation Waypoint

- (id) initWithDegreesLatitude:(double)latitude longitude:(double)longitude metersAltitude:(double)altitude
{
    self = [super init];

    _latitude = latitude;
    _longitude = longitude;
    _altitude = altitude;
    _properties = [NSDictionary dictionary];

    return self;
}

- (id) initWithWaypoint:(Waypoint*)waypoint metersAltitude:(double)altitude
{
    if (waypoint == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Waypoint is nil")
    }

    self = [super init];

    _latitude = waypoint->_latitude;
    _longitude = waypoint->_longitude;
    _altitude = altitude;
    _properties = waypoint->_properties;

    return self;
}

- (id) initWithWaypointTableRow:(NSDictionary*)values
{
    if (values == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Values is nil")
    }

    self = [super init];

    _latitude = [[values objectForKey:@"WGS_DLAT"] doubleValue];
    _longitude = [[values objectForKey:@"WGS_DLONG"] doubleValue];
    _altitude = [[values objectForKey:@"ELEV"] doubleValue] / TAIGA_METERS_TO_FEET;
    _properties = values;

    return self;
}

- (id) initWithPropertyList:(NSDictionary*)propertyList
{
    if (propertyList == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Property list is nil")
    }

    _latitude = [[propertyList objectForKey:@"latitude"] doubleValue];
    _longitude = [[propertyList objectForKey:@"longitude"] doubleValue];
    _altitude = [[propertyList objectForKey:@"altitude"] doubleValue];
    _properties = [propertyList objectForKey:@"properties"];

    return self;
}

- (NSDictionary*) asPropertyList
{
    return @{
        @"latitude" : [NSNumber numberWithDouble:_latitude],
        @"longitude" : [NSNumber numberWithDouble:_longitude],
        @"altitude" : [NSNumber numberWithDouble:_altitude],
        @"properties" : _properties,
    };
}

- (NSString*) description
{
    if ([_properties count] > 0)
    {
        NSMutableString* ms = [[NSMutableString alloc] init];
        [ms appendString:[_properties objectForKey:@"ICAO"]];
        [ms appendString:@": "];
        [ms appendString:[[_properties objectForKey:@"NAME"] capitalizedString]];
        return ms;
    }
    else
    {
        return [[TAIGA unitsFormatter] formatDegreesLatitude:_latitude longitude:_longitude];
    }
}

- (NSString*) descriptionWithAltitude
{
    if ([_properties count] > 0)
    {
        NSMutableString* ms = [[NSMutableString alloc] init];
        [ms appendString:[_properties objectForKey:@"ICAO"]];
        [ms appendString:@": "];
        [ms appendString:[[_properties objectForKey:@"NAME"] capitalizedString]];
        [ms appendString:@"  "];
        [ms appendString:[[TAIGA unitsFormatter] formatMetersAltitude:_altitude] ];
        return ms;
    }
    else
    {
        return [[TAIGA unitsFormatter] formatDegreesLatitude:_latitude longitude:_longitude metersAltitude:_altitude];
    }
}

@end