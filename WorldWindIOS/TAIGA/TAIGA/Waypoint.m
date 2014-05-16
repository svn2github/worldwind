/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.

 @version $Id$
 */

#import "Waypoint.h"
#import "TAIGA.h"
#import "UnitsFormatter.h"
#import "WorldWind/WWLog.h"

static NSString* IconTypeAirport = @"taiga.IconTypeAirport";
static NSString* IconTypeMarker = @"taiga.IconTypeMarker";

@implementation Waypoint

- (id) initWithDegreesLatitude:(double)latitude longitude:(double)longitude metersAltitude:(double)altitude
{
    self = [super init];

    _latitude = latitude;
    _longitude = longitude;
    _altitude = altitude;
    _displayName = [[TAIGA unitsFormatter] formatDegreesLatitude:latitude longitude:longitude];
    _properties = [NSDictionary dictionary];
    iconType = IconTypeMarker;
    _iconImage = [Waypoint iconForType:iconType];

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
    _displayName = waypoint->_displayName;
    _properties = waypoint->_properties;
    iconType = waypoint->iconType;
    _iconImage = waypoint->_iconImage;

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
    _altitude = [[values objectForKey:@"ELEV"] doubleValue];
    _displayName = [NSString stringWithFormat:@"%@: %@", [values objectForKey:@"ICAO"], [[values objectForKey:@"NAME"] capitalizedString]];
    _properties = values;
    iconType = IconTypeAirport;
    _iconImage = [Waypoint iconForType:iconType];

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
    _displayName = [propertyList objectForKey:@"displayName"];
    _properties = [propertyList objectForKey:@"properties"];
    iconType = [propertyList objectForKey:@"iconType"];
    _iconImage = [Waypoint iconForType:iconType];

    return self;
}

- (NSDictionary*) asPropertyList
{
    return @{
        @"latitude" : [NSNumber numberWithDouble:_latitude],
        @"longitude" : [NSNumber numberWithDouble:_longitude],
        @"altitude" : [NSNumber numberWithDouble:_altitude],
        @"displayName" : _displayName,
        @"properties" : _properties,
        @"iconType" : iconType,
    };
}

+ (UIImage*) iconForType:(NSString*)type
{
    if ([IconTypeAirport isEqualToString:type])
    {
        return [[UIImage imageNamed:@"38-airplane"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    }
    else if ([IconTypeMarker isEqualToString:type])
    {
        return [[UIImage imageNamed:@"07-map-marker"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    }
    else
    {
        return nil;
    }
}

@end