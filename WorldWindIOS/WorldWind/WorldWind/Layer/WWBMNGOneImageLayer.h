/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import <Foundation/Foundation.h>
#import "WorldWind/Layer/WWLayer.h"

@class WWSurfaceImage;

@interface WWBMNGOneImageLayer : WWLayer

@property (readonly, nonatomic) WWSurfaceImage* surfaceImage;

@end