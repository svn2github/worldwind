/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import "WorldWind/Layer/WWWMSTiledImageLayer.h"
#import "WorldWind/Util/WWWMSCapabilities.h"
#import "WorldWind/Geometry/WWSector.h"
#import "WorldWind/Util/WWUtil.h"
#import "WorldWind/Geometry/WWLocation.h"
#import "WorldWind/Util/WWWmsUrlBuilder.h"
#import "WorldWind/WWLog.h"

@implementation WWWMSTiledImageLayer

- (WWWMSTiledImageLayer*) initWithWMSCapabilities:(WWWMSCapabilities*)serverCapabilities
                                layerCapabilities:(NSDictionary*)layerCapabilities
{
    if (serverCapabilities == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Server capabilities is nil.")
    }

    if (layerCapabilities == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Layer capabilities is nil.")
    }

    NSString* layerName = [WWWMSCapabilities layerName:layerCapabilities];
    if (layerName == nil || [layerName length] == 0)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Layer is not a named layer.")
    }

    NSString* getMapURL = [serverCapabilities getMapURL];
    if (getMapURL == nil || [getMapURL length] == 0)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"GetMap URL is nil or empty.")
    }

    WWSector* boundingBox = [serverCapabilities geographicBoundingBoxForNamedLayer:layerCapabilities];
    if (boundingBox == nil)
    {
        // A layer must have a bounding box according to the WMS spec, but we check just in case and provide a default
        // one.
        boundingBox = [[WWSector alloc] initWithFullSphere];
    }

    // Determine a cache directory.
    NSString* layerCacheDir = [WWUtil makeValidFilePath:getMapURL];
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