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
    NSString* layerName = @"NASA_SRTM30_900m_Tiled,aster_v2,USGS-NED";
    NSString* serviceAddress = @"http://worldwind26.arc.nasa.gov/wms";

    NSString* cacheDir = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString* cachePath = [cacheDir stringByAppendingPathComponent:@"EarthElevations256"];

    self = [super initWithSector:[[WWSector alloc] initWithFullSphere]
                  levelZeroDelta:[[WWLocation alloc] initWithDegreesLatitude:45 longitude:45]
                       numLevels:10 // Approximately 38.4 meter resolution with 45x45 degree and 256x256 px tiles.
            retrievalImageFormat:@"application/bil16"
                       cachePath:cachePath];
    [self setDisplayName:@"Earth Elevations"];
    [self setMinElevation:-11000]; // Depth of Marianas Trench, in meters.
    [self setMaxElevation:+8850]; // Height of Mt. Everest, in meters.

    // On 1/16/14 we repaired the configuration to request the Aster layer, so invalidate prior cache.
    NSDateFormatter* formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ssZ"];
    [self setExpiration:[formatter dateFromString:@"2014-01-16T13:40:00-0800"]];

    WWWMSUrlBuilder* urlBuilder = [[WWWMSUrlBuilder alloc] initWithServiceAddress:serviceAddress
                                                                       layerNames:layerName
                                                                       styleNames:@""
                                                                       wmsVersion:@"1.3.0"];
    [self setUrlBuilder:urlBuilder];

    NSArray* layerNames = [layerName componentsSeparatedByString:@","];
    WWWMSLayerExpirationRetriever* expirationChecker =
            [[WWWMSLayerExpirationRetriever alloc] initWithLayer:self
                                                       layerNames:layerNames
                                                  serviceAddress:serviceAddress];
    [[WorldWind loadQueue] addOperation:expirationChecker];

    return self;
}

@end