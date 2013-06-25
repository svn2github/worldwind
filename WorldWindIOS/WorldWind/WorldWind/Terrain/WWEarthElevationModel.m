/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.

@version $Id $
 */

#import "WorldWind/Terrain/WWEarthElevationModel.h"
#import "WorldWind/Geometry/WWLocation.h"
#import "WorldWind/Geometry/WWSector.h"
#import "WorldWind/Util/WWWMSUrlBuilder.h"
#import "WorldWind/Layer/WWWMSLayerExpirationRetriever.h"
#import "WorldWind/WorldWind.h"

@implementation WWEarthElevationModel

- (WWEarthElevationModel*) init
{
    NSString* layerName = @"continents,NASA_SRTM30_900m_Tiled,USGS-NED";
    NSString* serviceAddress = @"http://worldwind26.arc.nasa.gov/wms";

    NSString* cacheDir = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString* cachePath = [cacheDir stringByAppendingPathComponent:@"EarthElevation"];

    self = [super initWithSector:[[WWSector alloc] initWithFullSphere]
                  levelZeroDelta:[[WWLocation alloc] initWithDegreesLatitude:45 longitude:45]
                       numLevels:12 // Approximately 9.6 meter resolution with 45x45 degree and 256x256 px tiles.
            retrievalImageFormat:@"application/bil16"
                       cachePath:cachePath];
    [self setDisplayName:@"Earth Elevations"];
    [self setMinElevation:-11000]; // Depth of Marianas Trench, in meters.
    [self setMaxElevation:+8850]; // Height of Mt. Everest, in meters.

    WWWMSUrlBuilder* urlBuilder = [[WWWMSUrlBuilder alloc] initWithServiceAddress:serviceAddress
                                                                       layerNames:layerName
                                                                       styleNames:@""
                                                                       wmsVersion:@"1.3.0"];
    [self setUrlBuilder:urlBuilder];

    WWWMSLayerExpirationRetriever* expirationChecker =
            [[WWWMSLayerExpirationRetriever alloc] initWithLayer:self
                                                       layerName:layerName
                                                  serviceAddress:serviceAddress];
    [[WorldWind loadQueue] addOperation:expirationChecker];

    return self;
}

@end