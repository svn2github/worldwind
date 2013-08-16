/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import <UIKit/UIKit.h>
#import "WorldWind/Layer/WWWMSDimensionedLayer.h"
#import "WorldWind/Util/WWWMSCapabilities.h"
#import "WorldWind/Util/WWWMSDimension.h"
#import "WorldWind/Layer/WWTiledImageLayer.h"
#import "WorldWind/Layer/WWWMSTiledImageLayer.h"
#import "WorldWind/WWLog.h"
#import "WorldWind/WorldWindConstants.h"

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

- (NSUInteger) layerCount
{
    return [[self renderables] count];
}

- (void) setEnabledLayerNumber:(int)layerNumber
{
    if (layerNumber >= [[self renderables] count])
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Layer number exceeds number of layers.")
    }

    if (enabledLayerNumber >= 0)
        [[[self renderables] objectAtIndex:(NSUInteger)enabledLayerNumber] setEnabled:NO];

    enabledLayerNumber = layerNumber;

    if (enabledLayerNumber >= 0)
        [[[self renderables] objectAtIndex:(NSUInteger)enabledLayerNumber] setEnabled:YES];

}

- (WWWMSTiledImageLayer*) enabledLayer
{
    if (enabledLayerNumber >= 0)
        return [[self renderables] objectAtIndex:(NSUInteger)enabledLayerNumber];

    return nil;
}

- (void) setEnabled:(BOOL)enabled
{
    [super setEnabled:enabled];

    NSNotification* notification = [NSNotification notificationWithName:WW_WMS_DIMENSION_LAYER_ENABLE object:self];
    [[NSNotificationCenter defaultCenter] postNotification:notification];
}
@end