/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.

 @version $Id$
 */

#import "Waypoint.h"
#import "TAIGA.h"
#import "UnitsFormatter.h"
#import "WorldWind/Geometry/WWLocation.h"
#import "WorldWind/Util/WWUtil.h"
#import "WorldWind/WWLog.h"

@implementation Waypoint

- (id) initWithKey:(NSString*)key location:(WWLocation*)location type:(WaypointType)type
{
    if (key == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Key is nil")
    }

    if (location == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Location is nil")
    }

    self = [super init];

    _key = key;
    _location = location;
    _type  = type;
    _displayName = @"";
    _properties = [NSDictionary dictionary];

    switch (_type)
    {
    case WaypointTypeAirport:
        _iconPath = [[NSBundle mainBundle] pathForResource:@"38-airplane" ofType:@"png"];
        _iconImage = [[UIImage imageWithContentsOfFile:_iconPath] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        break;
    case WaypointTypeMarker :
        _iconPath = [[NSBundle mainBundle] pathForResource:@"07-map-marker" ofType:@"png"];
        _iconImage = [[UIImage imageWithContentsOfFile:_iconPath] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        break;
    }

    return self;
}

- (id) initWithWaypointTableRow:(NSDictionary*)values
{
    if (values == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Values is nil")
    }

    NSString* id = [values objectForKey:@"ARPT_IDENT"];
    NSNumber* latDegrees = [values objectForKey:@"WGS_DLAT"];
    NSNumber* lonDegrees = [values objectForKey:@"WGS_DLONG"];
    NSString* icao = [values objectForKey:@"ICAO"];
    NSString* name = [values objectForKey:@"NAME"];
    WWLocation* location = [[WWLocation alloc] initWithDegreesLatitude:[latDegrees doubleValue]
                                                             longitude:[lonDegrees doubleValue]];

    self = [self initWithKey:id location:location type:WaypointTypeAirport];

    NSMutableString* displayName = [[NSMutableString alloc] init];
    [displayName appendString:icao];
    [displayName appendString:@": "];
    [displayName appendString:[name capitalizedString]];

    _displayName = displayName;
    _properties = values;

    return self;
}

- (id) initWithDegreesLatitude:(double)latitude longitude:(double)longitude
{
    NSString* id = [WWUtil generateUUID];
    WWLocation* location = [[WWLocation alloc] initWithDegreesLatitude:latitude longitude:longitude];

    self = [self initWithKey:id location:location type:WaypointTypeMarker];

    _displayName = [[TAIGA unitsFormatter] formatDegreesLatitude:latitude longitude:longitude];

    return self;
}

- (id) initWithPropertyList:(NSDictionary*)propertyList
{
    if (propertyList == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Property list is nil")
    }

    NSString* key = [propertyList objectForKey:@"key"];
    NSNumber* lat = [propertyList objectForKey:@"latitude"];
    NSNumber* lon = [propertyList objectForKey:@"longitude"];
    NSNumber* type = [propertyList objectForKey:@"type"];
    WWLocation* location = [[WWLocation alloc] initWithDegreesLatitude:[lat doubleValue] longitude:[lon doubleValue]];

    self = [self initWithKey:key location:location type:(WaypointType) [type intValue]];

    _displayName = [propertyList objectForKey:@"displayName"];
    _properties = [propertyList objectForKey:@"properties"];

    return self;
}

- (NSDictionary*) propertyList
{
    return @{
        @"key" : _key,
        @"latitude" : [NSNumber numberWithDouble:[_location latitude]],
        @"longitude" : [NSNumber numberWithDouble:[_location longitude]],
        @"type" : [NSNumber numberWithInt:_type],
        @"displayName" : _displayName,
        @"properties" : _properties
    };
}

- (BOOL) isEqual:(id __unsafe_unretained)anObject // Suppress unnecessary ARC retain/release calls.
{
    if (anObject == nil || [anObject class] != [Waypoint class])
    {
        return NO;
    }

    Waypoint* __unsafe_unretained other = (Waypoint*) anObject; // Suppress unnecessary ARC retain/release calls.
    return [_key isEqualToString:other->_key];
}

- (NSUInteger) hash
{
    return [_key hash];
}

@end