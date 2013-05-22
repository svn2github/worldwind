/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import "WWWMSLayerExpirationRetriever.h"
#import "WWLayer.h"
#import "WWWMSCapabilities.h"
#import "WWTiledImageLayer.h"
#import "WWLog.h"
#import "WorldWindConstants.h"

@implementation WWWMSLayerExpirationRetriever

- (WWWMSLayerExpirationRetriever*) initWithLayer:(id)layer
                                       layerName:(NSString*)layerName
                                  serviceAddress:(NSString*)serviceAddress
{
    if (layer == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Layer is nil")
    }

    if (layerName == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Layer name is nil")
    }

    if (serviceAddress == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Service address is nil")
    }

    self = [super init];

    _layer = layer;
    _layerName = layerName;
    _serviceAddress = serviceAddress;

    return self;
}

- (void) main
{
    @autoreleasepool
    {
        WWWMSCapabilities* caps = [[WWWMSCapabilities alloc] initWithServerAddress:_serviceAddress];
        if (caps != nil)
        {
            NSDictionary* layerCaps = [caps namedLayer:_layerName];
            if (layerCaps != nil)
            {
                NSDate* layerLastUpdateTime = [caps layerLastUpdateTime:layerCaps];
                if (layerLastUpdateTime != nil)
                {
                    [self performSelectorOnMainThread:@selector(setExpiration:)
                                           withObject:layerLastUpdateTime
                                        waitUntilDone:NO];
                }
            }
        }
    }
}

- (void) setExpiration:(id)layerLastUpdateTime
{
    // Note that the "layer" may be a tiled image layer or an elevation model.
    [_layer setExpiration:layerLastUpdateTime];

    // Request a redraw so the layer can updated itself.
    NSNotification* redrawNotification = [NSNotification notificationWithName:WW_REQUEST_REDRAW object:self];
    [[NSNotificationCenter defaultCenter] postNotification:redrawNotification];
}

@end