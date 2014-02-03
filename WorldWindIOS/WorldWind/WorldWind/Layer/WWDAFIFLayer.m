/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import "WorldWind/Layer/WWRenderableLayer.h"
#import "WorldWind/Layer/WWDAFIFLayer.h"
#import "WorldWind/Geometry/WWSector.h"
#import "WorldWind/Geometry/WWLocation.h"
#import "WorldWind/Util/WWArcGisUrlBuilder.h"

@implementation WWDAFIFLayer

- (WWDAFIFLayer*) init
{
    self = [super init];

    [self setDisplayName:@"DAFIF"];

    WWTiledImageLayer* layer = [self makeLayerForName:@"show:0,1,21" displayName:@"Airports"];
    [layer setEnabled:YES];
    [self setMaxActiveAltitude:3000000];
    [self addRenderable:layer];

    layer = [self makeLayerForName:@"show:2,4" displayName:@"Navigation"];
    [layer setEnabled:YES];
    [self setMaxActiveAltitude:750000];
    [self addRenderable:layer];

    layer = [self makeLayerForName:@"show:13,17,24" displayName:@"Special Activity"];
    [layer setEnabled:YES];
    [self setMaxActiveAltitude:3000000];
    [self addRenderable:layer];

    return self;
}

- (WWTiledImageLayer*) makeLayerForName:(NSString*)layerName displayName:(NSString*)displayName
{
    NSString* cacheDir = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString* cachePath = [cacheDir stringByAppendingPathComponent:[[NSString alloc] initWithFormat:@"DAFIF%@", layerName]];

    WWSector* sector = [[WWSector alloc] initWithFullSphere];

    WWTiledImageLayer* layer = [[WWTiledImageLayer alloc] initWithSector:sector
                                                          levelZeroDelta:[[WWLocation alloc]
                                                                  initWithDegreesLatitude:45 longitude:45]
                                                               numLevels:10
                                                    retrievalImageFormat:@"image/png" cachePath:cachePath];
    [layer setDisplayName:displayName];

    NSString* serviceLocation = @"http://faaservices-1551414968.us-east-1.elb.amazonaws.com/ArcGIS/rest/services/201101_AirportsGIS_BH/Dafif/MapServer";
    WWArcGisUrlBuilder* urlBuilder = [[WWArcGisUrlBuilder alloc] initWithServiceLocation:serviceLocation
                                                                                  layers:layerName
                                                                           arcGisVersion:@"10.0"];

    [layer setUrlBuilder:urlBuilder];

    return layer;
}

@end