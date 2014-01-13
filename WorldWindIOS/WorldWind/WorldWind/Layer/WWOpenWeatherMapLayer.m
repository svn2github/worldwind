/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import "WorldWind/Layer/WWRenderableLayer.h"
#import "WorldWind/Layer/WWOpenWeatherMapLayer.h"
#import "WorldWind/Util/WWWMSUrlBuilder.h"
#import "WorldWind/Geometry/WWLocation.h"
#import "WorldWind/Geometry/WWSector.h"
#import "WorldWind/WorldWindView.h"

@implementation WWOpenWeatherMapLayer

- (WWOpenWeatherMapLayer*) init
{
    self = [super init];

    [self setDisplayName:@"Open Weather Map"];

    NSDate* now = [[NSDate alloc] init]; // Cause all layers to be updated at start-up.

    WWTiledImageLayer* layer = [self makeLayerForName:@"precipitation" displayName:@"Precipitation"];
    [layer setEnabled:NO];
    [layer setExpiration:now];
    [self addRenderable:layer];

    layer = [self makeLayerForName:@"clouds" displayName:@"Clouds"];
    [layer setEnabled:NO];
    [layer setExpiration:now];
    [self addRenderable:layer];

    layer = [self makeLayerForName:@"pressure" displayName:@"Pressure"];
    [layer setEnabled:NO];
    [layer setExpiration:now];
    [self addRenderable:layer];

    layer = [self makeLayerForName:@"pressure_cntr" displayName:@"Pressure Contours"];
    [layer setEnabled:NO];
    [layer setExpiration:now];
    [self addRenderable:layer];

    layer = [self makeLayerForName:@"temp" displayName:@"Temperature"];
    [layer setEnabled:NO];
    [layer setExpiration:now];
    [self addRenderable:layer];

    layer = [self makeLayerForName:@"wind" displayName:@"Wind"];
    [layer setEnabled:NO];
    [layer setExpiration:now];
    [self addRenderable:layer];

    layer = [self makeLayerForName:@"snow" displayName:@"Snow"];
    [layer setEnabled:NO];
    [layer setExpiration:now];
    [self addRenderable:layer];

// These layers are in the capabilities document but as of 4/19/13 do not work.
//    layer = [self makeLayerForName:@"RADAR.12KM" displayName:@"Radar 12 Km"];
//    [layer setEnabled:NO];
//    [self addRenderable:layer];
//
//    layer = [self makeLayerForName:@"RADAR.2KM" displayName:@"Radar 2 Km"];
//    [layer setEnabled:NO];
//    [self addRenderable:layer];

    // Refresh the data every hour. This adds the timer to the main thread's run loop.
    timer = [NSTimer scheduledTimerWithTimeInterval:3600 target:self selector:@selector(updateExpirationTime)
                                           userInfo:nil repeats:YES];

    return self;
}

- (void) dealloc
{
    [timer invalidate]; // turn off the timer
}

- (void) updateExpirationTime
{
    NSDate* now = [[NSDate alloc] init];

    for (NSUInteger i = 0; i < [[self renderables] count]; i++)
    {
        WWTiledImageLayer* layer = (WWTiledImageLayer*) [[self renderables] objectAtIndex:i];
        [layer setExpiration:now];
    }

    [WorldWindView requestRedraw];
}

- (WWTiledImageLayer*) makeLayerForName:(NSString*)layerName displayName:(NSString*)displayName
{
    NSString* cacheDir = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString* cachePath = [cacheDir stringByAppendingPathComponent:layerName];

    WWSector* sector = [[WWSector alloc] initWithDegreesMinLatitude:-85.0511287798 maxLatitude:85.0511287798
                                                       minLongitude:-180 maxLongitude:180];

    WWTiledImageLayer* layer = [[WWTiledImageLayer alloc] initWithSector:sector
                                                          levelZeroDelta:[[WWLocation alloc]
                                                                  initWithDegreesLatitude:45 longitude:45]
                                                               numLevels:5
                                                    retrievalImageFormat:@"image/png" cachePath:cachePath];
    [layer setDisplayName:displayName];

    NSString* serviceLocation = @"http://wms.openweathermap.org/service";
    WWWMSUrlBuilder* urlBuilder = [[WWWMSUrlBuilder alloc] initWithServiceAddress:serviceLocation
                                                                       layerNames:layerName
                                                                       styleNames:@""
                                                                       wmsVersion:@"1.1.1"];
    [layer setUrlBuilder:urlBuilder];

    return layer;
}
@end