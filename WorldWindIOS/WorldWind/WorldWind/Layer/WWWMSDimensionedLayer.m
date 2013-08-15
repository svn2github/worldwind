/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import "WorldWind/Layer/WWWMSDimensionedLayer.h"
#import "WorldWind/Util/WWWMSCapabilities.h"
#import "WorldWind/Util/WWWMSDimension.h"
#import "WorldWind/Layer/WWTiledImageLayer.h"
#import "WorldWind/Layer/WWWMSTiledImageLayer.h"
#import "WorldWind/WWLog.h"

@implementation WWWMSDimensionedLayer

- (WWWMSDimensionedLayer*) initWithWMSCapabilities:(WWWMSCapabilities*)serverCaps layerCapabilities:(NSDictionary*)layerCaps
{
    NSString* layerName = [WWWMSCapabilities layerName:layerCaps];
    if (layerName == nil || [layerName length] == 0)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Layer is not a named layer.")
    }

    self = [super init];

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

    return self;
}
@end