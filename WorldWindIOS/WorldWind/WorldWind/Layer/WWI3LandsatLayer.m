/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import "WorldWind/Layer/WWI3LandsatLayer.h"
#import "WorldWind/Geometry/WWSector.h"
#import "WorldWind/Geometry/WWLocation.h"
#import "WorldWind/Util/WWWMSUrlBuilder.h"
#import "WorldWind/WorldWind.h"
#import "WorldWind/Layer/WWWMSLayerExpirationRetriever.h"

@implementation WWI3LandsatLayer
- (WWI3LandsatLayer*) init
{
    NSString* layerName = @"esat";
    NSString* serviceAddress = @"http://worldwind25.arc.nasa.gov/wms";

    NSString* cacheDir = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString* cachePath = [cacheDir stringByAppendingPathComponent:@"I3Landsat"];

    self = [super initWithSector:[[WWSector alloc] initWithFullSphere]
                  levelZeroDelta:[[WWLocation alloc] initWithDegreesLatitude:45 longitude:45]
                       numLevels:11
            retrievalImageFormat:@"image/png"
                       cachePath:cachePath];
    [self setDisplayName:@"Landsat"];
    [self setImageFile:@"Landsat"];

    WWWMSUrlBuilder* urlBuilder = [[WWWMSUrlBuilder alloc] initWithServiceAddress:serviceAddress
                                                                       layerNames:layerName
                                                                       styleNames:@""
                                                                       wmsVersion:@"1.3.0"];
    [self setUrlBuilder:urlBuilder];
    [self setMaxActiveAltitude:300e3];

    NSArray* layerNames = [[NSArray alloc] initWithObjects:layerName, nil];
    WWWMSLayerExpirationRetriever* expirationChecker =
            [[WWWMSLayerExpirationRetriever alloc] initWithLayer:self
                                                      layerNames:layerNames
                                                  serviceAddress:serviceAddress];
    [[WorldWind loadQueue] addOperation:expirationChecker];

    return self;
}

@end