/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.

 @version $Id$
 */

#import "WorldWind/Util/WWArcGisUrlBuilder.h"
#import "WorldWind/Util/WWTile.h"
#import "WorldWind/Geometry/WWSector.h"
#import "WorldWind/WWLog.h"

@implementation WWArcGisUrlBuilder

- (WWArcGisUrlBuilder*) initWithServiceLocation:(NSString*)serviceLocation
                                         layers:(NSString*)layers
                                  arcGisVersion:(NSString*)arcGisVersion
{
    if (serviceLocation == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Service location is nil")
    }

    if (layers == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Layers is nil")
    }

    self = [super init];

    _serviceLocation = serviceLocation;
    _layers = layers;
    _arcGisVersion = arcGisVersion != nil ? arcGisVersion : @"10.0";
    _imageSR = @"4326";
    _transparent = YES;

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

    WWSector* s = [tile sector];

    // Compose a URL string that defines an ArcGIS Export Map request.
    NSMutableString* ms = [[NSMutableString alloc] initWithCapacity:256];
    [ms appendString:[self fixExportMapString:_serviceLocation]];
    [ms appendFormat:@"v=%@", _arcGisVersion];
    [ms appendFormat:@"&layers=%@", _layers];
    [ms appendFormat:@"&bbox=%f,%f,%f,%f", [s minLongitude], [s minLatitude], [s maxLongitude], [s maxLatitude]];
    [ms appendString:@"&bboxSR=4326"]; // The bounding box is always in WGS 84 coordinates.
    [ms appendString:@"&f=image"]; // Request an image response format. The default is html.
    [ms appendFormat:@"&size=%d,%d", [tile tileWidth], [tile tileHeight]];
    [ms appendFormat:@"&format=%@", [self formatForMimeType:imageFormat]];
    [ms appendFormat:@"&imageSR=%@", _imageSR]; //
    [ms appendFormat:@"&transparent=%@", _transparent ? @"true" : @"false"];

    // Convert the URL string into a valid URL by replacing illegal characters with their equivalent encoding. The
    // result is a URL string that can be reliably used to initialize an NSURL.
    NSString* encodedUrlStr = [ms stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];

    return [[NSURL alloc] initWithString:encodedUrlStr];
}

- (NSString*) fixExportMapString:(NSString*)ems
{
    ems = [ems stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];

    NSRange r = [ems rangeOfString:@"?"];
    if (r.location == NSNotFound) // if string contains no question mark
    {
        NSRange r2 = [ems rangeOfString:@"/export" options:NSCaseInsensitiveSearch]; // if string contains no /export path
        if (r2.location == NSNotFound)
        {
            ems = [ems stringByAppendingString:@"/export"]; // add on "/export"
        }

        ems = [ems stringByAppendingString:@"?"]; // add on "?"
    }
    else if (r.location != [ems length] - 1) // else if ? is not at the end of the string ...
    {
        r = [ems rangeOfString:@"&" options:NSBackwardsSearch];
        if (r.location == NSNotFound || r.location != [ems length] - 1) // if & is not at the end of the string ...
        {
            [ems stringByAppendingString:@"&"]; // add a parameter separator
        }
    }

    return ems;
}

- (NSString*) formatForMimeType:(NSString*)mimeType
{
    if ([@"image/png" isEqualToString:mimeType])
        return @"png";

    if ([@"image/jpeg" isEqualToString:mimeType])
        return @"jpg";

    return nil;
}

@end