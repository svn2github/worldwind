/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import "WorldWind/layer/WWFAAChartAnchorage_84_North.h"
#import "WorldWind/Geometry/WWSector.h"
#import "WorldWind/Geometry/WWLocation.h"
#import "WorldWind/Util/WWWmsUrlBuilder.h"


@implementation WWFAAChartAnchorage_84_North

- (WWFAAChartAnchorage_84_North*) init
{
    NSString* cacheDir = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString* cachePath = [cacheDir stringByAppendingPathComponent:@"FAAChartsAlaska84North"];

    self = [super initWithSector:[[WWSector alloc] initWithDegreesMinLatitude:61.0694
                                                                  maxLatitude:64.813
                                                                 minLongitude:-153.775
                                                                 maxLongitude:-138.763]
                  levelZeroDelta:[[WWLocation alloc] initWithDegreesLatitude:45 longitude:45]
                       numLevels:15
            retrievalImageFormat:@"image/png"
                       cachePath:cachePath];
    [self setDisplayName:@"FAA Alaska 84 North"];
//    [self setImageFile:@"BlueMarble"];

    NSString* serviceLocation = @"http://wms.alaskamapped.org/faa_charts";
    WWWmsUrlBuilder* urlBuilder = [[WWWmsUrlBuilder alloc] initWithServiceLocation:serviceLocation
                                                                        layerNames:@"Anchorage_84_North"
                                                                        styleNames:@""
                                                                        wmsVersion:@"1.3.0"];
    [self setUrlBuilder:urlBuilder];

    return self;
}
@end