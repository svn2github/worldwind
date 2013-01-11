/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import <Foundation/Foundation.h>
#import "WorldWind/Util/WWUrlBuilder.h"
#import "WorldWind/Util/WWWmsUrlBuilder.h"
#import "WorldWind/WWLog.h"
#import "WorldWind/Util/WWTile.h"
#import "WorldWind/Geometry/WWSector.h"

@implementation WWWmsUrlBuilder

- (WWWmsUrlBuilder*) initWithServiceLocation:(NSString*)serviceLocation
                                  layerNames:(NSString*)layerNames
                                  styleNames:(NSString*)styleNames
                                  wmsVersion:(NSString*)wmsVersion
{
    if (serviceLocation == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Layer names is nil")
    }

    if (layerNames == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Layer names is nil")
    }

    self = [super init];

    _serviceLocation = serviceLocation;
    _layerNames = layerNames;
    _styleNames = styleNames != nil ? styleNames : @"";
    _wmsVersion = wmsVersion != nil ? wmsVersion : @"1.3.0";
    _transparent = YES;

    NSString* maxVersion = @"1.3.0";
    if (_wmsVersion == nil || [_wmsVersion compare:maxVersion] != NSOrderedAscending)
    {
        _wmsVersion = maxVersion;
        _crs = @"&crs=CRS:84";
    }
    else
    {
        _crs = @"&srs=EPSG:4326";
    }

    return self;
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
        sb = [WWWmsUrlBuilder fixGetMapString:_serviceLocation];

        NSRange r = [sb rangeOfString:@"service=wms" options:NSCaseInsensitiveSearch];
        if (r.location == NSNotFound)
        {
            sb = [sb stringByAppendingString:@"service=WMS"];
        }

        sb = [sb stringByAppendingString:@"&request=GetMap"];
        sb = [sb stringByAppendingFormat:@"&version=%@", _wmsVersion];
        sb = [sb stringByAppendingString:_crs];
        sb = [sb stringByAppendingFormat:@"&layers=%@", _layerNames];
        sb = [sb stringByAppendingFormat:@"&styles=%@", _styleNames];
        sb = [sb stringByAppendingFormat:@"&transparent=%@", _transparent ? @"TRUE" : @"FALSE"];

        self->urlTemplate = sb;
    }

    sb = [sb stringByAppendingFormat:@"&format=%@", imageFormat];
    sb = [sb stringByAppendingFormat:@"&width=%d", [tile tileWidth]];
    sb = [sb stringByAppendingFormat:@"&height=%d", [tile tileHeight]];

    WWSector* s = [tile sector];
    sb = [sb stringByAppendingFormat:@"&bbox=%f,%f,%f,%f",
                                     [s minLongitude], [s minLatitude], [s maxLongitude], [s maxLatitude]];

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