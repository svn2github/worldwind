/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import "WorldWind/Geometry/WWSector.h"
#import "WorldWind/WWLog.h"

WWSector* WWSECTOR_ZERO;
WWSector* WWSECTOR_FULL_SPHERE;

@implementation WWSector

+(void)initialize
{
    // Create the class constants.
    
    WWSECTOR_ZERO = [[WWSector alloc] initWithDegreesMinLatitude:0 maxLatitude:0 minLongitude:0 maxLongitude:0];
    WWSECTOR_FULL_SPHERE = [[WWSector alloc] initWithDegreesMinLatitude:-90 maxLatitude:90 minLongitude:-180 maxLongitude:180];
}

- (WWSector*) initWithDegreesMinLatitude:(double)minLatitude
                             maxLatitude:(double)maxLatitude
                            minLongitude:(double)minLongitude
                            maxLongitude:(double)maxLongitude
{
    self = [super init];
    
    _minLatitude = minLatitude;
    _maxLatitude = maxLatitude;
    _minLongitude = minLongitude;
    _maxLongitude = maxLongitude;
    
    return self;
}

- (id) copyWithZone:(NSZone *)zone
{
    return [[[self class] alloc] initWithDegreesMinLatitude:_minLatitude maxLatitude:_maxLatitude minLongitude:_minLongitude maxLongitude:_maxLongitude];
}

@end
