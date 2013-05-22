/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import "WorldWind/Layer/WWBMNGLayer.h"
#import "WorldWind/Geometry/WWSector.h"
#import "WorldWind/Geometry/WWLocation.h"
#import "WorldWind/Util/WWWmsUrlBuilder.h"
#import "WWWMSLayerExpirationRetriever.h"
#import "WorldWind/WorldWind.h"

@implementation WWBMNGLayer

- (WWBMNGLayer*) init
{
    NSString* layerName = @"BlueMarble-200405";
    NSString* serviceAddress = @"http://worldwind25.arc.nasa.gov/wms";

    NSString* cacheDir = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString* cachePath = [cacheDir stringByAppendingPathComponent:@"BMNG"];

    self = [super initWithSector:[[WWSector alloc] initWithFullSphere]
                  levelZeroDelta:[[WWLocation alloc] initWithDegreesLatitude:45 longitude:45]
                       numLevels:5
            retrievalImageFormat:@"image/jpeg"
                       cachePath:cachePath];
    [self setDisplayName:@"Blue Marble"];
    [self setImageFile:@"BlueMarble"];

    WWWmsUrlBuilder* urlBuilder = [[WWWmsUrlBuilder alloc] initWithServiceLocation:serviceAddress
                                                                        layerNames:layerName
                                                                        styleNames:@""
                                                                        wmsVersion:@"1.3.0"];
    [self setUrlBuilder:urlBuilder];

    WWWMSLayerExpirationRetriever* expirationChecker =
            [[WWWMSLayerExpirationRetriever alloc] initWithLayer:self
                                                     layerName:layerName
                                                serviceAddress:serviceAddress];
    [[WorldWind loadQueue] addOperation:expirationChecker];

    return self;
}

@end