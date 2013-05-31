/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import <WorldWind/WWTiledImageLayer.h>
#import "WorldWind/Util/WWWMSUrlBuilder.h"
#import "WorldWind/Geometry/WWSector.h"
#import "WorldWind/Geometry/WWLocation.h"
#import "FAAChartsAlaskaLayer.h"

@implementation FAAChartsAlaskaLayer

- (FAAChartsAlaskaLayer*) init
{
    self = [super init];

    [self setDisplayName:@"Alaska FAA Charts"];

    WWSector* sector = [[WWSector alloc] initWithDegreesMinLatitude:61.0694 maxLatitude:64.813
                                                       minLongitude:-153.775 maxLongitude:-138.763];
    WWTiledImageLayer* layer = [self makeLayerForName:@"Anchorage_84_North" displayName:@"Anchorage 84 North" sector:sector];
    [layer setEnabled:NO];
    [self addRenderable:layer];

    sector = [[WWSector alloc] initWithDegreesMinLatitude:58.7672 maxLatitude:62.5095
                                             minLongitude:-153.297 maxLongitude:-139.304];
    layer = [self makeLayerForName:@"Anchorage_84_South" displayName:@"Anchorage 84 South" sector:sector];
    [layer setEnabled:NO];
    [self addRenderable:layer];

    sector = [[WWSector alloc] initWithDegreesMinLatitude:60.5675 maxLatitude:65.3683
                                             minLongitude:-175.762 maxLongitude:-159.86];
    layer = [self makeLayerForName:@"Bethel_51_North" displayName:@"Bethel 51 North" sector:sector];
    [layer setEnabled:NO];
    [self addRenderable:layer];

    sector = [[WWSector alloc] initWithDegreesMinLatitude:58.2564 maxLatitude:63.0629
                                             minLongitude:-175.159 maxLongitude:-60.364];
    layer = [self makeLayerForName:@"Bethel_51_South" displayName:@"Bethel 51 South" sector:sector];
    [layer setEnabled:NO];
    [self addRenderable:layer];

    sector = [[WWSector alloc] initWithDegreesMinLatitude:68.6962 maxLatitude:73.139
                                             minLongitude:-176.372 maxLongitude:-154.861];
    layer = [self makeLayerForName:@"Cape_Lisburne_42_North" displayName:@"Cape Lisburne 42 North" sector:sector];
    [layer setEnabled:NO];
    [self addRenderable:layer];

    sector = [[WWSector alloc] initWithDegreesMinLatitude:66.4313 maxLatitude:70.8116
                                             minLongitude:-175.089 maxLongitude:-155.764];
    layer = [self makeLayerForName:@"Cape_Lisburne_42_South" displayName:@"Cape Lisburne 42 South" sector:sector];
    [layer setEnabled:NO];
    [self addRenderable:layer];

    sector = [[WWSector alloc] initWithDegreesMinLatitude:53.243 maxLatitude:56.6644
                                             minLongitude:-165.736 maxLongitude:-154.082];
    layer = [self makeLayerForName:@"Cold_Bay_42" displayName:@"Cold Bay 42" sector:sector];
    [layer setEnabled:NO];
    [self addRenderable:layer];

    sector = [[WWSector alloc] initWithDegreesMinLatitude:64.4113 maxLatitude:69.5388
                                             minLongitude:-148.155 maxLongitude:-129.446];
    layer = [self makeLayerForName:@"Dawson_42_North" displayName:@"Dawson 42 North" sector:sector];
    [layer setEnabled:NO];
    [self addRenderable:layer];

    sector = [[WWSector alloc] initWithDegreesMinLatitude:64.4113 maxLatitude:69.5388
                                             minLongitude:-148.155 maxLongitude:-129.446];
    layer = [self makeLayerForName:@"Dawson_42_South" displayName:@"Dawson 42 South" sector:sector];
    [layer setEnabled:NO];
    [self addRenderable:layer];

    sector = [[WWSector alloc] initWithDegreesMinLatitude:62.1314 maxLatitude:67.2139
                                             minLongitude:-147.27 maxLongitude:-130.248];
    layer = [self makeLayerForName:@"Dutch_Harbor_42_South" displayName:@"Dutch Harbor 42 South" sector:sector];
    [layer setEnabled:NO];
    [self addRenderable:layer];

    sector = [[WWSector alloc] initWithDegreesMinLatitude:52.4638 maxLatitude:57.4899
                                             minLongitude:-175.261 maxLongitude:-162.558];
    layer = [self makeLayerForName:@"Dutch_Harbor_42_North" displayName:@"Dutch Harbor 42 North" sector:sector];
    [layer setEnabled:NO];
    [self addRenderable:layer];

    sector = [[WWSector alloc] initWithDegreesMinLatitude:65.5512 maxLatitude:68.4307
                                             minLongitude:-160.748 maxLongitude:-143.524];
    layer = [self makeLayerForName:@"Fairbanks_84_North" displayName:@"Fairbanks 84 North" sector:sector];
    [layer setEnabled:NO];
    [self addRenderable:layer];

    sector = [[WWSector alloc] initWithDegreesMinLatitude:63.2624 maxLatitude:766.1052
                                             minLongitude:-159.865 maxLongitude:-144.268];
    layer = [self makeLayerForName:@"Fairbanks_84_South" displayName:@"Fairbanks 84 South" sector:sector];
    [layer setEnabled:NO];
    [self addRenderable:layer];

    sector = [[WWSector alloc] initWithDegreesMinLatitude:56.1905 maxLatitude:61.8141
                                             minLongitude:-143.099 maxLongitude:-128.489];
    layer = [self makeLayerForName:@"Juneau_49_North" displayName:@"Juneau 49 North" sector:sector];
    [layer setEnabled:NO];
    [self addRenderable:layer];

    sector = [[WWSector alloc] initWithDegreesMinLatitude:53.8676 maxLatitude:59.4819
                                             minLongitude:-142.594 maxLongitude:-128.957];
    layer = [self makeLayerForName:@"Juneau_49_South" displayName:@"Juneau 49 South" sector:sector];
    [layer setEnabled:NO];
    [self addRenderable:layer];

    sector = [[WWSector alloc] initWithDegreesMinLatitude:52.0888 maxLatitude:57.8961
                                             minLongitude:-141.33 maxLongitude:-128.096];
    layer = [self makeLayerForName:@"Kethcikan_49_North" displayName:@"Ketchikan 49 North" sector:sector];
    [layer setEnabled:NO];
    [self addRenderable:layer];

    sector = [[WWSector alloc] initWithDegreesMinLatitude:49.7695 maxLatitude:55.5859
                                             minLongitude:-140.921 maxLongitude:-128.455];
    layer = [self makeLayerForName:@"Kethcikan_49_South" displayName:@"Ketchikan 49 South" sector:sector];
    [layer setEnabled:NO];
    [self addRenderable:layer];

    sector = [[WWSector alloc] initWithDegreesMinLatitude:57.511 maxLatitude:60.453
                                             minLongitude:-163.614 maxLongitude:-150.666];
    layer = [self makeLayerForName:@"Kodiak_49_North" displayName:@"Kodiak 49 North" sector:sector];
    [layer setEnabled:NO];
    [self addRenderable:layer];

    sector = [[WWSector alloc] initWithDegreesMinLatitude:55.1933 maxLatitude:58.1216
                                             minLongitude:-163.118 maxLongitude:-151.073];
    layer = [self makeLayerForName:@"Kodiak_49_South" displayName:@"Kodiak 49 South" sector:sector];
    [layer setEnabled:NO];
    [self addRenderable:layer];

    sector = [[WWSector alloc] initWithDegreesMinLatitude:59.1939 maxLatitude:62.105
                                             minLongitude:-163.66 maxLongitude:-150.388];
    layer = [self makeLayerForName:@"McGrath_51_North" displayName:@"McGrath 51 North" sector:sector];
    [layer setEnabled:NO];
    [self addRenderable:layer];

    sector = [[WWSector alloc] initWithDegreesMinLatitude:61.4974 maxLatitude:64.4298
                                             minLongitude:-164.495 maxLongitude:-149.879];
    layer = [self makeLayerForName:@"McGrath_51_South" displayName:@"McGrath 51 South" sector:sector];
    [layer setEnabled:NO];
    [self addRenderable:layer];

    sector = [[WWSector alloc] initWithDegreesMinLatitude:64.765 maxLatitude:69.1637
                                             minLongitude:-174.493 maxLongitude:-156.434];
    layer = [self makeLayerForName:@"Nome_50_North" displayName:@"Nome 50 North" sector:sector];
    [layer setEnabled:NO];
    [self addRenderable:layer];

    sector = [[WWSector alloc] initWithDegreesMinLatitude:62.4679 maxLatitude:66.8511
                                             minLongitude:-173.693 maxLongitude:-157.113];
    layer = [self makeLayerForName:@"Nome_50_South" displayName:@"Nome 50 South" sector:sector];
    [layer setEnabled:NO];
    [self addRenderable:layer];

    sector = [[WWSector alloc] initWithDegreesMinLatitude:69.3007 maxLatitude:72.6404
                                             minLongitude:-159.762 maxLongitude:-138.728];
    layer = [self makeLayerForName:@"Point_Barrow_71_North" displayName:@"Point Barrow 71 North" sector:sector];
    [layer setEnabled:NO];
    [self addRenderable:layer];

    sector = [[WWSector alloc] initWithDegreesMinLatitude:67.0061 maxLatitude:70.3149
                                             minLongitude:-158.53 maxLongitude:-139.805];
    layer = [self makeLayerForName:@"Point_Barrow_71_South" displayName:@"Point Barrow 71 South" sector:sector];
    [layer setEnabled:NO];
    [self addRenderable:layer];

    sector = [[WWSector alloc] initWithDegreesMinLatitude:58.3431 maxLatitude:62.1337
                                             minLongitude:-154.208 maxLongitude:-139.427];
    layer = [self makeLayerForName:@"Seward_84" displayName:@"Seward 84" sector:sector];
    [layer setEnabled:NO];
    [self addRenderable:layer];

    sector = [[WWSector alloc] initWithDegreesMinLatitude:48.7459 maxLatitude:55.2439
                                             minLongitude:175.975 maxLongitude:180];
    layer = [self makeLayerForName:@"Western_Aleutian_Islands_42_East" displayName:@"Western Aleutian Islands 42 East"
            " A"
                            sector:sector];
    [layer setEnabled:NO];
    [self addRenderable:layer];

    sector = [[WWSector alloc] initWithDegreesMinLatitude:48.7459 maxLatitude:55.2439
                                             minLongitude:-180 maxLongitude:-171.37];
    layer = [self makeLayerForName:@"Western_Aleutian_Islands_42_East" displayName:@"Western Aleutian Islands 42 East"
            " B"
                            sector:sector];
    [layer setEnabled:NO];
    [self addRenderable:layer];

    sector = [[WWSector alloc] initWithDegreesMinLatitude:48.172 maxLatitude:55.8542
                                             minLongitude:166.609 maxLongitude:179.993];
    layer = [self makeLayerForName:@"Western_Aleutian_Islands_42_West" displayName:@"Western Aleutian Islands 42 West"
                            sector:sector];
    [layer setEnabled:NO];
    [self addRenderable:layer];

    sector = [[WWSector alloc] initWithDegreesMinLatitude:60.1973 maxLatitude:65.7527
                                             minLongitude:-144.047 maxLongitude:-127.558];
    layer = [self makeLayerForName:@"Whitehorse_49_North" displayName:@"Whitehorse 49 North" sector:sector];
    [layer setEnabled:NO];
    [self addRenderable:layer];

    sector = [[WWSector alloc] initWithDegreesMinLatitude:57.9222 maxLatitude:63.4365
                                             minLongitude:-143.398 maxLongitude:-128.167];
    layer = [self makeLayerForName:@"Whitehorse_49_South" displayName:@"Whitehorse 49 South" sector:sector];
    [layer setEnabled:NO];
    [self addRenderable:layer];

    return self;
}

- (WWTiledImageLayer*) makeLayerForName:(NSString*)layerName displayName:(NSString*)displayName sector:(WWSector*)sector
{
    NSString* cacheDir = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString* cachePath = [cacheDir stringByAppendingPathComponent:layerName];

    WWTiledImageLayer* layer = [[WWTiledImageLayer alloc] initWithSector:sector
                                                          levelZeroDelta:[[WWLocation alloc]
                                                                  initWithDegreesLatitude:45 longitude:45]
                                                               numLevels:15
                                                    retrievalImageFormat:@"image/png" cachePath:cachePath];
    [layer setDisplayName:displayName];

    NSString* serviceLocation = @"http://wms.alaskamapped.org/faa_charts";
    WWWMSUrlBuilder* urlBuilder = [[WWWMSUrlBuilder alloc] initWithServiceAddress:serviceLocation
                                                                       layerNames:layerName
                                                                       styleNames:@""
                                                                       wmsVersion:@"1.3.0"];
    [layer setUrlBuilder:urlBuilder];

    return layer;
}

@end