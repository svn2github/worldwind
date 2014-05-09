/*
 Copyright (C) 2014 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import "FAASectionalsLayer.h"
#import "WWWmsUrlBuilder.h"
#import "WWWMSLayerExpirationRetriever.h"
#import "WorldWind.h"
#import "WWLocation.h"
#import "WWSector.h"

@implementation FAASectionalsLayer

- (FAASectionalsLayer*) init
{
    NSString* layerName = @"FAAchart";
    NSString* serviceAddress = @"http://worldwind20.arc.nasa.gov/faachart";

    NSString* cacheDir = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString* cachePath = [cacheDir stringByAppendingPathComponent:@"FAASectionals"];

    // dateline, and WW doesn't have a way to specify that, or a way to specify more than one region.
    self = [super initWithSector:[[WWSector alloc] initWithDegreesMinLatitude:35 maxLatitude:71.4
                                                                 minLongitude:-180 maxLongitude:-118]
                  levelZeroDelta:[[WWLocation alloc] initWithDegreesLatitude:45 longitude:45]
                       numLevels:9
            retrievalImageFormat:@"image/png"
                       cachePath:cachePath];
    [self setDisplayName:@"FAA Sectionals"];
    [self setTextureCacheFormat:WW_TEXTURE_AS_IS]; // do not convert to 5551 on download

    WWWMSUrlBuilder* urlBuilder = [[WWWMSUrlBuilder alloc] initWithServiceAddress:serviceAddress
                                                                       layerNames:layerName
                                                                       styleNames:@""
                                                                       wmsVersion:@"1.3.0"];
    [self setUrlBuilder:urlBuilder];

    NSArray* layerNames = [[NSArray alloc] initWithObjects:layerName, nil];
    WWWMSLayerExpirationRetriever* expirationChecker =
            [[WWWMSLayerExpirationRetriever alloc] initWithLayer:self
                                                      layerNames:layerNames
                                                  serviceAddress:serviceAddress];
    [[WorldWind loadQueue] addOperation:expirationChecker];

    return self;
}
@end