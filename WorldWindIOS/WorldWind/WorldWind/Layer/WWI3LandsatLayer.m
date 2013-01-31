/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import "WorldWind/Layer/WWI3LandsatLayer.h"
#import "WorldWind/Geometry/WWSector.h"
#import "WorldWind/Geometry/WWLocation.h"
#import "WorldWind/Util/WWWmsUrlBuilder.h"

@implementation WWI3LandsatLayer
- (WWI3LandsatLayer*) init
{
    NSString* cacheDir = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString* cachePath = [cacheDir stringByAppendingPathComponent:@"I3Landsat"];

    self = [super initWithSector:[[WWSector alloc] initWithFullSphere]
                  levelZeroDelta:[[WWLocation alloc] initWithDegreesLatitude:45 longitude:45]
                       numLevels:11
                     imageFormat:@"image/png"
                       cachePath:cachePath];
    [self setDisplayName:@"Landsat"];
    [self setImageFile:@"Landsat"];

    NSString* serviceLocation = @"http://data.worldwind.arc.nasa.gov/wms";
    WWWmsUrlBuilder* urlBuilder = [[WWWmsUrlBuilder alloc] initWithServiceLocation:serviceLocation
                                                                        layerNames:@"esat"
                                                                        styleNames:@""
                                                                        wmsVersion:@"1.3.0"];
    [self setUrlBuilder:urlBuilder];
    [self setMaxActiveAltitude:300e3];
//    [self setMinActiveAltitude:10e3];

    return self;
}

@end