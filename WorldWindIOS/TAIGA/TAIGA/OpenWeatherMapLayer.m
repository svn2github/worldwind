/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import "OpenWeatherMapLayer.h"
#import "WorldWind/Geometry/WWLocation.h"
#import "WorldWind/Geometry/WWSector.h"
#import "WorldWind/Util/WWWMSUrlBuilder.h"
#import "WorldWind/WorldWindConstants.h"
#import "WorldWind/WWLog.h"

@implementation OpenWeatherMapLayer

- (OpenWeatherMapLayer*) initWithLayerName:(NSString*)layerName displayName:(NSString*)displayName
{
    if (layerName == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Layer name is nil")
    }

    if (displayName == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Display name is nil")
    }

    NSString* cacheDir = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString* cachePath = [cacheDir stringByAppendingPathComponent:layerName];

    WWSector* sector = [[WWSector alloc] initWithDegreesMinLatitude:-85.0511287798 maxLatitude:85.0511287798
                                                       minLongitude:-180 maxLongitude:180];

    self = [super initWithSector:sector
                  levelZeroDelta:[[WWLocation alloc] initWithDegreesLatitude:45 longitude:45]
                       numLevels:5
            retrievalImageFormat:@"image/png"
                       cachePath:cachePath];
    [self setDisplayName:displayName];

    NSString* serviceLocation = @"http://wms.openweathermap.org/service";
    WWWMSUrlBuilder* urlBuilder = [[WWWMSUrlBuilder alloc] initWithServiceAddress:serviceLocation
                                                                       layerNames:layerName
                                                                       styleNames:@""
                                                                       wmsVersion:@"1.1.1"];
    [self setUrlBuilder:urlBuilder];

    NSDate* now = [[NSDate alloc] init]; // Cause the layer's cache to be updated at start-up.
    [self setExpiration:now];

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
    [self setExpiration:now];

    NSNotification* redrawNotification = [NSNotification notificationWithName:WW_REQUEST_REDRAW object:self];
    [[NSNotificationCenter defaultCenter] postNotification:redrawNotification];
}

@end