/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.

 @version $Id$
 */

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import "WorldWind/Layer/WWRenderableLayer.h"

@class WWPosition;

@interface CurrentPositionLayer : WWRenderableLayer
{
@protected
    CLLocation* currentLocation;
    WWPosition* forecastPosition;
}

@property (nonatomic, readonly) id marker;

- (CurrentPositionLayer*) init;

@end