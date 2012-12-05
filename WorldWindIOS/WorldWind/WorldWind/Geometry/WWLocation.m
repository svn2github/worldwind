/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import "WorldWind/Geometry/WWLocation.h"
#import "WorldWind/WWLog.h"

@implementation WWLocation

- (WWLocation*) initWithDegreesLatitude:(double)latitude longitude:(double)longitude
{
    self = [super init];
    
    _latitude = latitude;
    _longitude = latitude;
    
    return self;
}

- (id) copyWithZone:(NSZone *)zone
{
    return [[[self class] alloc] initWithDegreesLatitude:_latitude longitude:_longitude];
}

-(WWLocation*) add:(WWLocation *)location
{
    if (location == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Location is nil")
    }

    _latitude += location.latitude;
    _longitude += location.longitude;
    
    return self;
}

-(WWLocation*) subtract:(WWLocation *)location
{
    if (location == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Location is nil")
    }
    
    _latitude -= location.latitude;
    _longitude -= location.longitude;
    
    return self;
}

@end
