/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import <Foundation/Foundation.h>
#import "WWTiledImageLayer.h"

@class WWWMSCapabilities;

@interface WWWMSTiledImageLayer : WWTiledImageLayer

@property(nonatomic, readonly) WWWMSCapabilities* serverCapabilities;
@property(nonatomic, readonly) NSDictionary* layerCapabilities;

- (WWWMSTiledImageLayer*)initWithWMSCapabilities:(WWWMSCapabilities*)serverCapabilities
                               layerCapabilities:(NSDictionary*)layerCapabilities;

@end