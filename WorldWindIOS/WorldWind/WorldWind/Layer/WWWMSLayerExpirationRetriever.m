/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import "WorldWind/Layer/WWWMSLayerExpirationRetriever.h"
#import "WorldWind/Layer/WWLayer.h"
#import "WorldWind/Util/WWWMSCapabilities.h"
#import "WorldWind/Layer/WWTiledImageLayer.h"
#import "WorldWind/WWLog.h"
#import "WorldWind/WorldWindConstants.h"

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
    WWWMSCapabilities __unused * caps =
            [[WWWMSCapabilities alloc] initWithServiceAddress:_serviceAddress
                                                finishedBlock:^(WWWMSCapabilities* capabilities)
                                                {
                                                    [self performSelectorOnMainThread:@selector(setExpiration:)
                                                                           withObject:capabilities
                                                                        waitUntilDone:NO];
                                                }];
}

- (void) setExpiration:(id)capabilities
{
    if (capabilities != nil)
    {
        NSDictionary* layerCaps = [capabilities namedLayer:_layerName];
        if (layerCaps != nil)
        {
            NSDate* layerLastUpdateTime = [WWWMSCapabilities layerLastUpdateTime:layerCaps];
            if (layerLastUpdateTime != nil)
            {
                // Note that the "layer" may be a tiled image layer or an elevation model.
                [_layer setExpiration:layerLastUpdateTime];

                // Request a redraw so the layer can updated itself.
                NSNotification* redrawNotification = [NSNotification notificationWithName:WW_REQUEST_REDRAW object:self];
                [[NSNotificationCenter defaultCenter] postNotification:redrawNotification];
            }
        }
    }
}

@end