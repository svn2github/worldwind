/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import "WorldWind/Util/WWUrlBuilder.h"
#import "WorldWind/Util/WWWmsUrlBuilder.h"
#import "WorldWind/WWLog.h"
#import "WorldWind/Util/WWTile.h"
#import "WorldWind/Geometry/WWSector.h"
#import "WorldWind/Util/WWWMSCapabilities.h"

@implementation WWWMSUrlBuilder

- (WWWMSUrlBuilder*) initWithServiceAddress:(NSString*)serviceAddress
                                 layerNames:(NSString*)layerNames
                                 styleNames:(NSString*)styleNames
                                 wmsVersion:(NSString*)wmsVersion
{
    if (serviceAddress == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Layer names is nil")
    }

    if (layerNames == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Layer names is nil")
    }

    self = [super init];

    _serviceAddress = serviceAddress;
    _layerNames = layerNames;
    _styleNames = styleNames != nil ? styleNames : @"";
    _wmsVersion = wmsVersion != nil ? wmsVersion : @"1.3.0";
    _transparent = YES;

    isWMS13OrGreater = [_wmsVersion compare:@"1.3.0"] != NSOrderedAscending;

    NSString* maxVersion = @"1.3.0";
    if (isWMS13OrGreater)
    {
        _wmsVersion = maxVersion;
        _crs = @"crs=CRS:84";
    }
    else
    {
        _crs = @"srs=EPSG:4326";
    }

    return self;
}

- (WWWMSUrlBuilder*) initWithServiceCapabilities:(WWWMSCapabilities*)serviceCaps
                                       layerCaps:(NSDictionary*)layerCaps
{
    if (serviceCaps == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Service capabilities is nil")
    }

    if (layerCaps == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Layer capabilities is nil")
    }

    NSString* layerName = [WWWMSCapabilities layerName:layerCaps];
    if (layerName == nil || [layerName length] == 0)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Not a named layer")
    }

    self = [super init];

    _serviceAddress = [serviceCaps getMapURL];
    _layerNames = layerName;
    _styleNames = @"";
    _wmsVersion = [serviceCaps serviceWMSVersion];
    _transparent = [WWWMSCapabilities layerIsOpaque:layerCaps] ? NO : YES;

    isWMS13OrGreater = [_wmsVersion compare:@"1.3.0"] != NSOrderedAscending;

    [self findCoordinateSystem:serviceCaps layerCaps:layerCaps];

    return self;
}

- (void) findCoordinateSystem:(WWWMSCapabilities*)serviceCaps layerCaps:(NSDictionary*)layerCaps
{
    NSArray* csList = [serviceCaps layerCoordinateSystems:layerCaps];
    if (csList == nil || [csList count] == 0)
    {
        _crs = isWMS13OrGreater ? @"crs=CRS:84" : @"srs=EPSG:4326";
        return;
    }

    NSString* coordinateSystem = nil;
    for (NSString* cs in csList)
    {
        // Try for EPSG:4326 first.
        if ([cs caseInsensitiveCompare:@"EPSG:4326"] == NSOrderedSame)
        {
            coordinateSystem = cs;
            break;
        }

        // Try for CRS:84 next.
        if ([cs caseInsensitiveCompare:@"CRS:84"] == NSOrderedSame)
        {
            coordinateSystem = cs;
            break;
        }
    }

    if (coordinateSystem == nil)
    {
        _crs = isWMS13OrGreater ? @"crs=CRS:84" : @"srs=EPSG:4326";
        return;
    }

    coordinateSystem = [coordinateSystem stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];

    if (isWMS13OrGreater)
    {
        _crs = [[NSString alloc] initWithFormat:@"crs=%@", coordinateSystem];
    }
    else
    {
        _crs = [[NSString alloc] initWithFormat:@"srs=%@", coordinateSystem];
    }
}

- (NSURL*) urlForTile:(WWTile*)tile imageFormat:(NSString*)imageFormat
{
    if (tile == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Tile is nil")
    }

    if (imageFormat == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Image format is nil")
    }

    NSString* sb = self->urlTemplate;

    if (sb == nil)
    {
        sb = [WWWMSUrlBuilder fixGetMapString:_serviceAddress];

        NSRange r = [sb rangeOfString:@"service=wms" options:NSCaseInsensitiveSearch];
        if (r.location == NSNotFound)
        {
            sb = [sb stringByAppendingString:@"service=WMS"];
        }

        sb = [sb stringByAppendingString:@"&request=GetMap"];
        sb = [sb stringByAppendingFormat:@"&version=%@", _wmsVersion];
        sb = [[sb stringByAppendingString:@"&"] stringByAppendingString:_crs];
        sb = [sb stringByAppendingFormat:@"&layers=%@", _layerNames];
        sb = [sb stringByAppendingFormat:@"&styles=%@", _styleNames];
        sb = [sb stringByAppendingFormat:@"&transparent=%@", _transparent ? @"TRUE" : @"FALSE"];

        self->urlTemplate = sb;
    }

    sb = [sb stringByAppendingFormat:@"&format=%@", imageFormat];
    sb = [sb stringByAppendingFormat:@"&width=%d", [tile tileWidth]];
    sb = [sb stringByAppendingFormat:@"&height=%d", [tile tileHeight]];

    WWSector* s = [tile sector];
    if (!isWMS13OrGreater || [_crs caseInsensitiveCompare:@"crs=CRS:84"] == NSOrderedSame)
    {
        sb = [sb stringByAppendingFormat:@"&bbox=%f,%f,%f,%f",
                                         [s minLongitude], [s minLatitude], [s maxLongitude], [s maxLatitude]];
    }
    else
    {
        sb = [sb stringByAppendingFormat:@"&bbox=%f,%f,%f,%f",
                                         [s minLatitude], [s minLongitude], [s maxLatitude], [s maxLongitude]];
    }

    sb = [sb stringByReplacingOccurrencesOfString:@" " withString:@"%20"];

    return [[NSURL alloc] initWithString:sb];
}

+ (NSString*) fixGetMapString:(NSString*)gms
{
    gms = [gms stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];

    NSRange r = [gms rangeOfString:@"?"];
    if (r.location == NSNotFound) // if string contains no question mark
    {
        gms = [gms stringByAppendingString:@"?"]; // add on
    }
    else if (r.location != [gms length] - 1) // else if ? is not at the end of the string ...
    {
        r = [gms rangeOfString:@"&" options:NSBackwardsSearch];
        if (r.location == NSNotFound || r.location != [gms length] - 1) // if & is not at the end of the string ...
        {
            [gms stringByAppendingString:@"&"]; // add a parameter separator
        }
    }

    return gms;
}

@end