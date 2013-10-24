/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.

 @version $Id$
 */

#import "Waypoint.h"
#import "WorldWind/Geometry/WWLocation.h"
#import "WorldWind/WWLog.h"

@implementation Waypoint

- (Waypoint*) initWithKey:(NSString*)key location:(WWLocation*)location
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

    return self;
}

@end