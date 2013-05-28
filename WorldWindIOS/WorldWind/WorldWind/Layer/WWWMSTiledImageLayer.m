/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import "WWWMSTiledImageLayer.h"
#import "WWWMSCapabilities.h"
#import "WWSector.h"
#import "WorldWind/Util/WWUtil.h"
#import "WWLocation.h"
#import "WWWmsUrlBuilder.h"

@implementation WWWMSTiledImageLayer

- (WWWMSTiledImageLayer*) initWithWMSCapabilities:(WWWMSCapabilities*)serverCapabilities
                                layerCapabilities:(NSDictionary*)layerCapabilities
{
    WWSector* boundingBox = [serverCapabilities geographicBoundingBoxForNamedLayer:layerCapabilities];
    if (boundingBox == nil)
        return nil;

    NSString* getMapURL = [serverCapabilities getMapURL];
    if (getMapURL == nil)
        return nil;

    NSString* layerCacheDir = [WWUtil makeValidFilePath:getMapURL];

    NSString* layerName = [WWWMSCapabilities layerName:layerCapabilities];
    if (layerName == nil)
        return nil;

    layerCacheDir = [layerCacheDir stringByAppendingPathComponent:layerName];

    NSString* cacheDir = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString* cachePath = [cacheDir stringByAppendingPathComponent:layerCacheDir];

    self = [super initWithSector:boundingBox
                  levelZeroDelta:[[WWLocation alloc] initWithDegreesLatitude:45 longitude:45]
                       numLevels:16
            retrievalImageFormat:@"image/png" // TODO: determine available formats from layer caps
                       cachePath:cachePath];

    NSString* title = [WWWMSCapabilities layerTitle:layerCapabilities];
    [self setDisplayName:title != nil ? title : layerName];

    NSString* version = [serverCapabilities serverWMSVersion];
    if (version == nil)
    {
        version = @"1.1.1";
    }

    WWWmsUrlBuilder* urlBuilder = [[WWWmsUrlBuilder alloc] initWithServiceLocation:getMapURL
                                                                        layerNames:layerName
                                                                        styleNames:@""
                                                                        wmsVersion:version];
    [self setUrlBuilder:urlBuilder];

    return self;
}

@end