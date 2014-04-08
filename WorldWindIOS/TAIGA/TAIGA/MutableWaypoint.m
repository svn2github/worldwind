/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.

 @version $Id$
 */

#import "MutableWaypoint.h"
#import "WorldWind/WWLog.h"

@implementation MutableWaypoint

- (id) initWithType:(WaypointType)type degreesLatitude:(double)latitude longitude:(double)longitude
{
    self = [super initWithType:type degreesLatitude:latitude longitude:longitude];

    return self;
}

- (void) setDegreesLatitude:(double)latitude longitude:(double)longitude
{
    _latitude = latitude;
    _longitude = longitude;
}

- (void) setDisplayName:(NSString*)displayName
{
    if (displayName == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Display name is nil")
    }

    _displayName = displayName;
}

@end