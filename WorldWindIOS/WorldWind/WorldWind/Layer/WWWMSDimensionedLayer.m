/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import <UIKit/UIKit.h>
#import "WorldWind/Layer/WWTiledImageLayer.h"
#import "WorldWind/Layer/WWWMSDimensionedLayer.h"
#import "WorldWind/Layer/WWWMSTiledImageLayer.h"
#import "WorldWind/Shapes/WWScreenImage.h"
#import "WorldWind/Util/WWOffset.h"
#import "WorldWind/Util/WWRetriever.h"
#import "WorldWind/Util/WWUtil.h"
#import "WorldWind/Util/WWWMSCapabilities.h"
#import "WorldWind/Util/WWWMSDimension.h"
#import "WorldWind/WorldWindConstants.h"
#import "WorldWind/WorldWindView.h"
#import "WorldWind/WWLog.h"

@implementation WWWMSDimensionedLayer

- (WWWMSDimensionedLayer*) initWithWMSCapabilities:(WWWMSCapabilities*)serverCaps layerCapabilities:(NSDictionary*)layerCaps
{
    if (serverCaps == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Server capabilities is nil.")
    }

    if (layerCaps == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Layer capabilities is nil.")
    }

    NSString* layerName = [WWWMSCapabilities layerName:layerCaps];
    if (layerName == nil || [layerName length] == 0)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Layer is not a named layer.")
    }

    self = [super init];

    layerCapabilities = layerCaps;

    NSString* title = [WWWMSCapabilities layerTitle:layerCaps];
    [self setDisplayName:title != nil ? title : layerName];

    WWWMSDimension* dimension = [WWWMSCapabilities layerDimension:layerCaps];
    id <WWWMSDimensionIterator> dimensionIterator = [dimension iterator];

    while ([dimensionIterator hasNext])
    {
        NSString* dimString = [dimensionIterator next];
        WWWMSTiledImageLayer* layer = [[WWWMSTiledImageLayer alloc] initWithWMSCapabilities:serverCaps
                                                                          layerCapabilities:layerCaps];
        [layer setDimension:dimension];
        [layer setDimensionString:dimString];
        [layer setDisplayName:dimString];
        [layer setEnabled:NO];

        [self addRenderable:layer];
    }

    // Set up a cache path for the layer's legend.
    NSString* getMapURL = [serverCaps getMapURL];
    if (getMapURL == nil || [getMapURL length] == 0)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"GetMap URL is nil or empty.")
    }
    NSString* layerCacheDir = [WWUtil makeValidFilePath:getMapURL];
    layerCacheDir = [layerCacheDir stringByAppendingPathComponent:layerName];
    NSString* cacheDir = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    cachePath = [cacheDir stringByAppendingPathComponent:layerCacheDir];

    return self;
}

- (NSUInteger) dimensionCount
{
    return [[self renderables] count];
}

- (void) setEnabledDimensionNumber:(int)layerNumber
{
    if (layerNumber >= [[self renderables] count])
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Layer number exceeds number of layers.")
    }

    if (_enabledDimensionNumber >= 0)
        [[[self renderables] objectAtIndex:(NSUInteger) _enabledDimensionNumber] setEnabled:NO];

    _enabledDimensionNumber = layerNumber;

    if (_enabledDimensionNumber >= 0)
        [[[self renderables] objectAtIndex:(NSUInteger) _enabledDimensionNumber] setEnabled:YES];

}

- (WWWMSTiledImageLayer*) enabledLayer
{
    if (_enabledDimensionNumber >= 0)
        return [[self renderables] objectAtIndex:(NSUInteger) _enabledDimensionNumber];

    return nil;
}

- (void) setEnabled:(BOOL)enabled
{
    [super setEnabled:enabled];

    NSNotification* notification = [NSNotification notificationWithName:WW_WMS_DIMENSION_LAYER_ENABLE object:self];
    [[NSNotificationCenter defaultCenter] postNotification:notification];
}

- (void) setLegendEnabled:(BOOL)legendEnabled
{
    if (legendEnabled && legendOverlay == nil)
    {
        [self setupLegend];
    }

    _legendEnabled = legendEnabled;
}

- (void) doRender:(WWDrawContext*)dc
{
    [super doRender:dc];

    if ([self legendEnabled])
    {
        [self renderLegend:dc];
    }
}

- (void) renderLegend:(WWDrawContext*)dc
{
    if (legendOverlay != nil)
    {
        [legendOverlay render:dc];
    }
}

- (void) setupLegend
{
    NSDictionary* legend = [WWWMSCapabilities layerFirstLegendURL:layerCapabilities];
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
        NSError* error = nil;
        [[NSFileManager defaultManager] createDirectoryAtPath:cachePath
                                  withIntermediateDirectories:YES attributes:nil error:&error];
        if (error != nil)
        {
            WWLog("@Error creating legend path %@", [error description]);
            return;
        }

        error = nil;
        [[retriever retrievedData] writeToFile:filePath options:NSDataWritingAtomic error:&error];
        if (error != nil)
        {
            WWLog(@"Error writing legend image to file: %@", [error description]);
            return;
        }
    }

    // Create the screen overlay for the legend image. Place the legend's bottom-right corner 40 pixels to the left and
    // above the screen's bottom right corner.
    WWOffset* screenOffset = [[WWOffset alloc] initWithX:40 y:80 xUnits:WW_INSET_PIXELS yUnits:WW_PIXELS];
    WWOffset* imageOffset = [[WWOffset alloc] initWithFractionX:1 y:0];
    legendOverlay = [[WWScreenImage alloc] initWithScreenOffset:screenOffset imagePath:filePath];
    [legendOverlay setImageOffset:imageOffset];

    // Cause the WorldWindView to draw itself.
    [WorldWindView requestRedraw];
}
@end