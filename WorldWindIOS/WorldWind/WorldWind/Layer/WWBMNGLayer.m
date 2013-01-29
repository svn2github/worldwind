/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import "WorldWind/Layer/WWBMNGLayer.h"
#import "WorldWind/Geometry/WWSector.h"
#import "WorldWind/Geometry/WWLocation.h"
#import "WorldWind/Util/WWWmsUrlBuilder.h"

@implementation WWBMNGLayer

- (WWBMNGLayer*) init
{
    NSString* cacheDir = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString* cachePath = [cacheDir stringByAppendingPathComponent:@"BMNG"];

    self = [super initWithSector:[[WWSector alloc] initWithFullSphere]
                  levelZeroDelta:[[WWLocation alloc] initWithDegreesLatitude:45 longitude:45]
                       numLevels:5
                     imageFormat:@"image/jpeg"
                       cachePath:cachePath];
    [self setDisplayName:@"Blue Marble"];

    NSString* serviceLocation = @"http://data.worldwind.arc.nasa.gov/wms";
    WWWmsUrlBuilder* urlBuilder = [[WWWmsUrlBuilder alloc] initWithServiceLocation:serviceLocation
                                                                        layerNames:@"bmng200405"
                                                                        styleNames:@""
                                                                        wmsVersion:@"1.3.0"];
    [self setUrlBuilder:urlBuilder];

    return self;
}

@end