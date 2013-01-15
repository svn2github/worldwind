/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import "WorldWind/Layer/WWDAFIFLayer.h"
#import "WorldWind/Geometry/WWSector.h"
#import "WorldWind/Geometry/WWLocation.h"
#import "WorldWind/Util/WWArcGisUrlBuilder.h"
#import "WorldWind/WWLog.h"

@implementation WWDAFIFLayer

- (WWDAFIFLayer*) initWithLayers:(NSString*)layers cacheName:(NSString*)cacheName
{
    if (layers == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Layer names is nil");
    }

    if (cacheName == nil || [cacheName length] == 0)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Cache name is nil or empty");
    }

    NSString* cacheDir = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString* cachePath = [cacheDir stringByAppendingPathComponent:cacheName];

    self = [super initWithSector:[[WWSector alloc] initWithFullSphere]
                  levelZeroDelta:[[WWLocation alloc] initWithDegreesLatitude:90 longitude:90]
                       numLevels:14
                     imageFormat:@"image/png"
                       cachePath:cachePath];

    NSString* serviceLocation = @"http://faaservices-1551414968.us-east-1.elb.amazonaws.com/ArcGIS/rest/services/201101_AirportsGIS_BH/Dafif/MapServer";
    WWArcGisUrlBuilder* urlBuilder = [[WWArcGisUrlBuilder alloc] initWithServiceLocation:serviceLocation
                                                                                  layers:layers
                                                                           arcGisVersion:@"10.0"];
    [self setUrlBuilder:urlBuilder];

    return self;
}

+ (WWDAFIFLayer*) dafifAll
{
    WWDAFIFLayer* layer = [[WWDAFIFLayer alloc] initWithLayers:@"" cacheName:@"DafifAll"];
    [layer setMaxActiveAltitude:3000000];

    return layer;
}

+ (WWDAFIFLayer*) dafifAirports
{
    WWDAFIFLayer* layer = [[WWDAFIFLayer alloc] initWithLayers:@"show:0,1,21" cacheName:@"DAFIFAirports"];
    [layer setMaxActiveAltitude:3000000];

    return layer;
}

+ (WWDAFIFLayer*) dafifNavigation
{
    WWDAFIFLayer* layer = [[WWDAFIFLayer alloc] initWithLayers:@"show:2,4" cacheName:@"DAFIFNavigation"];
    [layer setMaxActiveAltitude:750000];

    return layer;
}

+ (WWDAFIFLayer*) dafifObstacles
{
    WWDAFIFLayer* layer = [[WWDAFIFLayer alloc] initWithLayers:@"show:13,17,24" cacheName:@"DAFIFObstacles"];
    [layer setMaxActiveAltitude:3000000];

    return layer;
}

@end