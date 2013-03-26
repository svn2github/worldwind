/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import "WorldWind/Layer/WWOpenWeatherMapLayer.h"
#import "WorldWind/Util/WWWmsUrlBuilder.h"
#import "WorldWind/Geometry/WWLocation.h"
#import "WorldWind/Geometry/WWSector.h"

@implementation WWOpenWeatherMapLayer

- (WWOpenWeatherMapLayer*) init
{
    NSString* cacheDir = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString* cachePath = [cacheDir stringByAppendingPathComponent:@"OpenWeatherMapPrecipitation"];

    self = [super initWithSector:[[WWSector alloc] initWithFullSphere]
                  levelZeroDelta:[[WWLocation alloc] initWithDegreesLatitude:45 longitude:45]
                       numLevels:4
            retrievalImageFormat:@"image/png"
                       cachePath:cachePath];
    [self setDisplayName:@"Open Weather Map Precipitation"];
//    [self setImageFile:@"BlueMarble"];

    NSString* serviceLocation = @"http://wms.openweathermap.org/service";
    WWWmsUrlBuilder* urlBuilder = [[WWWmsUrlBuilder alloc] initWithServiceLocation:serviceLocation
                                                                        layerNames:@"precipitation"
                                                                        styleNames:@""
                                                                        wmsVersion:@"1.1.1"];
    [self setUrlBuilder:urlBuilder];

    return self;
}
@end