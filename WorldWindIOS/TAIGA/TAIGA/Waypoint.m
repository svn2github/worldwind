/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.

 @version $Id$
 */

#import "Waypoint.h"
#import "TAIGA.h"
#import "UnitsFormatter.h"
#import "WorldWind/Util/WWUtil.h"
#import "WorldWind/WWLog.h"

@implementation Waypoint

- (NSString*) key
{
    return _key;
}

- (WaypointType) type
{
    return _type;
}

- (double) latitude
{
    return _latitude;
}

- (double) longitude
{
    return _longitude;
}

- (NSString*) displayName
{
    return _displayName;
}

- (NSString*) iconPath
{
    return _iconPath;
}

- (UIImage*) iconImage
{
    return _iconImage;
}

- (NSDictionary*) properties
{
    return _properties;
}

- (id) initWithKey:(NSString*)key type:(WaypointType)type degreesLatitude:(double)latitude longitude:(double)longitude
{
    if (key == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Key is nil")
    }

    self = [super init];

    _key = key;
    _type  = type;
    _latitude = latitude;
    _longitude = longitude;
    _displayName = [[TAIGA unitsFormatter] formatDegreesLatitude:latitude longitude:longitude];
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

- (id) initWithType:(WaypointType)type degreesLatitude:(double)latitude longitude:(double)longitude
{
    self = [self initWithKey:[WWUtil generateUUID] type:type degreesLatitude:latitude longitude:longitude];

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

    self = [self initWithKey:id type:WaypointTypeAirport degreesLatitude:[latDegrees doubleValue] longitude:[lonDegrees doubleValue]];

    NSMutableString* displayName = [[NSMutableString alloc] init];
    [displayName appendString:icao];
    [displayName appendString:@": "];
    [displayName appendString:[name capitalizedString]];

    _displayName = displayName;
    _properties = values;

    return self;
}

- (id) initWithPropertyList:(NSDictionary*)propertyList
{
    if (propertyList == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Property list is nil")
    }

    NSString* key = [propertyList objectForKey:@"key"];
    NSNumber* type = [propertyList objectForKey:@"type"];
    NSNumber* latitude = [propertyList objectForKey:@"latitude"];
    NSNumber* longitude = [propertyList objectForKey:@"longitude"];

    self = [self initWithKey:key type:(WaypointType) [type intValue] degreesLatitude:[latitude doubleValue] longitude:[longitude doubleValue]];

    _displayName = [propertyList objectForKey:@"displayName"];
    _properties = [propertyList objectForKey:@"properties"];

    return self;
}

- (NSDictionary*) propertyList
{
    return @{
        @"key" : _key,
        @"type" : [NSNumber numberWithInt:_type],
        @"latitude" : [NSNumber numberWithDouble:_latitude],
        @"longitude" : [NSNumber numberWithDouble:_longitude],
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