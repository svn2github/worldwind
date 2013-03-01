/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import "WorldWind/Layer/WWOpenStreetMapLayer.h"
#import "WorldWind/Geometry/WWSector.h"
#import "WorldWind/Geometry/WWLocation.h"
#import "WorldWind/Util/WWWmsUrlBuilder.h"

@implementation WWOpenStreetMapLayer

- (WWOpenStreetMapLayer*) init
{
    NSString* cacheDir = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString* cachePath = [cacheDir stringByAppendingPathComponent:@"OpenStreetMap"];

    self = [super initWithSector:[[WWSector alloc] initWithFullSphere]
                  levelZeroDelta:[[WWLocation alloc] initWithDegreesLatitude:45 longitude:45]
                       numLevels:16
            retrievalImageFormat:@"image/png"
                       cachePath:cachePath];
    [self setDisplayName:@"Open Street Map"];
//    [self setImageFile:@"Bing"];

    NSString* serviceLocation = @"http://worldwind20.arc.nasa.gov/mapcache";
    WWWmsUrlBuilder* urlBuilder = [[WWWmsUrlBuilder alloc] initWithServiceLocation:serviceLocation
                                                                        layerNames:@"osm"
                                                                        styleNames:@""
                                                                        wmsVersion:@"1.1.1"];
    [self setUrlBuilder:urlBuilder];
    [self setMaxActiveAltitude:100e3];

    return self;
}
@end