/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import "WorldWind/Layer/WWBMNGLandsatCombinedLayer.h"
#import "WorldWind/Geometry/WWSector.h"
#import "WorldWind/Util/WWWMSUrlBuilder.h"
#import "WWWMSLayerExpirationRetriever.h"
#import "WorldWind/WorldWind.h"
#import "WorldWind/Geometry/WWPosition.h"
#import "WorldWind/Util/WWTile.h"

@interface MyURLBuilder : WWWMSUrlBuilder

- (WWWMSUrlBuilder*) initWithServiceAddress:(NSString*)serviceAddress
                                 layerNames:(NSString*)layerNames
                                 styleNames:(NSString*)styleNames
                                 wmsVersion:(NSString*)wmsVersion;
@end

@implementation MyURLBuilder

- (WWWMSUrlBuilder*) initWithServiceAddress:(NSString*)serviceAddress
                                 layerNames:(NSString*)layerNames
                                 styleNames:(NSString*)styleNames
                                 wmsVersion:(NSString*)wmsVersion
{
    if (serviceAddress == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Layer names is nil")
    }

    if (layerNames == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Layer names is nil")
    }

    return [super initWithServiceAddress:serviceAddress layerNames:layerNames styleNames:styleNames
                              wmsVersion:wmsVersion];
}

- (NSString*) layersParameter:(WWTile*)tile
{
    if (tile == nil || [[tile sector] deltaLat] / [tile tileHeight] > 0.009) // 0.009 degrees/pixel
        return [super layersParameter:tile];

    return @"esat";
}

@end

@implementation WWBMNGLandsatCombinedLayer

- (WWBMNGLandsatCombinedLayer*) init
{
    NSString* layerName = @"BlueMarble-200405";
    NSString* serviceAddress = @"http://worldwind25.arc.nasa.gov/wms";

    NSString* cacheDir = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString* cachePath = [cacheDir stringByAppendingPathComponent:@"BMNGLandsatCombined"];

    self = [super initWithSector:[[WWSector alloc] initWithFullSphere]
                  levelZeroDelta:[[WWLocation alloc] initWithDegreesLatitude:45 longitude:45]
                       numLevels:11
            retrievalImageFormat:@"image/jpeg"
                       cachePath:cachePath];
    [self setDisplayName:@"Blue Marble + Landsat"];

    WWWMSUrlBuilder* urlBuilder = [[MyURLBuilder alloc] initWithServiceAddress:serviceAddress
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