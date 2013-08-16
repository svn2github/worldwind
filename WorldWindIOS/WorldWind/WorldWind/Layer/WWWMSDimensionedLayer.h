/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import <Foundation/Foundation.h>
#import "WWRenderableLayer.h"

@class WWWMSCapabilities;
@class WWWMSTiledImageLayer;

@interface WWWMSDimensionedLayer : WWRenderableLayer

@property (nonatomic) int enabledLayerNumber;

- (WWWMSDimensionedLayer*) initWithWMSCapabilities:(WWWMSCapabilities*)serverCaps layerCapabilities:(NSDictionary*)layerCaps;

- (NSUInteger) layerCount;

- (WWWMSTiledImageLayer*) enabledLayer;

@end