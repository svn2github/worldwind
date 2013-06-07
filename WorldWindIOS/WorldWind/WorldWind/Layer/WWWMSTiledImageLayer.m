/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import <UIKit/UIKit.h>
#import "WorldWind/Layer/WWWMSTiledImageLayer.h"
#import "WorldWind/Util/WWWMSCapabilities.h"
#import "WorldWind/Geometry/WWSector.h"
#import "WorldWind/Util/WWUtil.h"
#import "WorldWind/Geometry/WWLocation.h"
#import "WorldWind/Util/WWWMSUrlBuilder.h"
#import "WorldWind/WWLog.h"
#import "WorldWind/Util/WWRetriever.h"
#import "WorldWind/WorldWindConstants.h"

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

    WWSector* boundingBox = [serverCapabilities layerGeographicBoundingBox:layerCapabilities];
    if (boundingBox == nil)
    {
        // A layer must have a bounding box according to the WMS spec, but we check just in case and provide a default
        // one.
        boundingBox = [[WWSector alloc] initWithFullSphere];
    }

    _layerCapabilities = layerCapabilities;

    // Determine a cache directory.
    NSString* layerCacheDir = [WWUtil makeValidFilePath:getMapURL];
    layerCacheDir = [layerCacheDir stringByAppendingPathComponent:layerName];
    NSString* cacheDir = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    cachePath = [cacheDir stringByAppendingPathComponent:layerCacheDir];

    NSString* imageFormat = [self determineImageFormat:serverCapabilities layerCaps:layerCapabilities];
    if (imageFormat == nil)
    {
        imageFormat = @"image/png"; // The WMS spec recommends that all servers support this format
    }

    self = [super initWithSector:boundingBox
                  levelZeroDelta:[[WWLocation alloc] initWithDegreesLatitude:45 longitude:45]
                       numLevels:16
            retrievalImageFormat:imageFormat
                       cachePath:cachePath];

    NSString* title = [WWWMSCapabilities layerTitle:layerCapabilities];
    [self setDisplayName:title != nil ? title : layerName];

    WWWMSUrlBuilder* urlBuilder = [[WWWMSUrlBuilder alloc] initWithServiceCapabilities:serverCapabilities
                                                                             layerCaps:layerCapabilities];
    [self setUrlBuilder:urlBuilder];

    return self;
}

- (NSString*) determineImageFormat:(WWWMSCapabilities*)serverCaps layerCaps:(NSDictionary*)layerCaps
{
    NSArray* formats = [serverCaps getMapFormats];
    if (formats == nil || [formats count] == 0) // this should never happen, but have a response ready anyway
        return nil;

    NSArray* desiredFormatList;
    if ([WWWMSCapabilities layerIsOpaque:layerCaps])
    {
        desiredFormatList = [[NSArray alloc] initWithObjects:
                @"image/jpeg", @"image/png", @"image/tiff", @"image/gif", nil];
    }
    else
    {
        desiredFormatList = [[NSArray alloc] initWithObjects:
                @"image/png", @"image/jpeg", @"image/tiff", @"image/gif", nil];
    }

    for (NSString* desiredFormat in desiredFormatList)
    {
        for (NSString* format in formats)
        {
            if ([format caseInsensitiveCompare:desiredFormat] == NSOrderedSame)
            {
                return format;
            }
        }
    }

    return nil;
}

- (void) setEnabled:(BOOL)enabled
{
    if (enabled && screenOverlay == nil)
    {
        [self setupLegend];
    }

    [super setEnabled:enabled];
}

- (void) setupLegend
{
    NSDictionary* legend = [WWWMSCapabilities layerFirstLegendURL:_layerCapabilities];
    if (legend == nil)
        return;

    NSString* legendUrl = [WWWMSCapabilities legendHref:legend];
    if (legendUrl == nil || [legendUrl length] == 0)
        return;

    NSURL* url = [[NSURL alloc] initWithString:legendUrl];

    WWRetriever* retriever = [[WWRetriever alloc] initWithUrl:url timeout:10 finishedBlock:^(WWRetriever* myRetriever)
    {
        [self handleLegendRetrieval:myRetriever];
    }];
    [retriever performRetrieval];
}

- (void) handleLegendRetrieval:(WWRetriever*)retriever
{
    NSString* filePath = [cachePath stringByAppendingPathComponent:@"Legend"];

    if ([retriever status] != WW_SUCCEEDED
            || [retriever retrievedData] == nil || [[retriever retrievedData] length] == 0)
    {
        WWLog(@"Legend retrieval for %@ failed", [[retriever url] absoluteString]);

        // See if it's been previously cached.
        if (![[NSFileManager defaultManager] fileExistsAtPath:filePath])
            return;
    }
    else
    {
        // See if it's a valid image.
        UIImage* image = [[UIImage alloc] initWithData:[retriever retrievedData]];
        if (image == nil)
        {
            WWLog(@"Legend image is not in a recognized format: %@", [[retriever url] absoluteString]);
            return;
        }

        // Cache it if so.
        [[retriever retrievedData] writeToFile:filePath atomically:YES];
    }

    // Create the screen overlay for the legend image.
    screenOverlay = @"";
}

@end