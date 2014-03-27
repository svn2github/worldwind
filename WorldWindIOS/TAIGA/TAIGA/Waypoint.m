/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.

 @version $Id$
 */

#import "Waypoint.h"
#import "WorldWind/Geometry/WWLocation.h"
#import "WorldWind/WWLog.h"

@implementation Waypoint

- (Waypoint*) initWithKey:(NSString*)key location:(WWLocation*)location type:(WaypointType)type
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

    switch (_type)
    {
    case WaypointTypeAirport:
        _iconPath = [[NSBundle mainBundle] pathForResource:@"38-airplane" ofType:@"png"];
        _iconImage = [[UIImage imageWithContentsOfFile:_iconPath] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        break;
    case WaypointTypeUser :
        _iconPath = [[NSBundle mainBundle] pathForResource:@"07-map-marker" ofType:@"png"];
        _iconImage = [[UIImage imageWithContentsOfFile:_iconPath] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        break;
    }

    return self;
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