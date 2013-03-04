/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.

 @version $Id$
 */

#import "WorldWind/Terrain/WWElevationImage.h"
#import "WorldWind/Geometry/WWSector.h"
#import "WorldWind/Util/WWMemoryCache.h"
#import "WorldWind/WorldWindConstants.h"
#import "WorldWind/WWLog.h"

#define LERP(a, b, t) (1 - t) * (a) + (t) * (b)
#define CLAMP(min, max, value) (value) < (min) ? (min) : ((value) > (max) ? (max) : (value));

@implementation WWElevationImage
{
    NSData* imageData; // holds elevation image bits.
}

- (WWElevationImage*) initWithImagePath:(NSString*)filePath
                                 sector:(WWSector*)sector
                             imageWidth:(int)imageWidth
                            imageHeight:(int)imageHeight
                                  cache:(WWMemoryCache*)cache
                                 object:(id)object
{
    if (filePath == nil || [filePath length] == 0)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"File path is nil or zero length")
    }

    if (sector == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Sector is nil")
    }

    if (imageWidth <= 0 || imageHeight <= 0)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"A dimension is <= 0")
    }

    if (cache == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Memory cache is nil")
    }

    self = [super init];

    if (self != nil)
    {
        _filePath = filePath;
        _sector = sector;
        _imageWidth = imageWidth;
        _imageHeight = imageHeight;
        _memoryCache = cache;
        _object = object;
    }

    return self;
}

- (void) elevationForLatitude:(double)latitude
                    longitude:(double)longitude
                       result:(double*)result
{
    double maxLat = [_sector maxLatitude];
    double minLon = [_sector minLongitude];
    double deltaLat = [_sector deltaLat];
    double deltaLon = [_sector deltaLon];

    // Texel coordinates of the specified location, given an image origin in the upper left corner.
    double x = (_imageWidth - 1) * (longitude - minLon) / deltaLon;
    double y = (_imageHeight - 1) * (maxLat - latitude) / deltaLat;

    int x0 = CLAMP(0, _imageWidth - 1, (int) x);
    int x1 = CLAMP(0, _imageWidth - 1, x0 + 1);
    int y0 = CLAMP(0, _imageHeight - 1, (int) y);
    int y1 = CLAMP(0, _imageHeight - 1, y0 + 1);

    const short* pixels = [self->imageData bytes];
    short x0y0 = pixels[x0 + y0 * _imageWidth];
    short x1y0 = pixels[x1 + y0 * _imageWidth];
    short x0y1 = pixels[x0 + y1 * _imageWidth];
    short x1y1 = pixels[x1 + y1 * _imageWidth];

    double xf = x - x0;
    double yf = y - y0;

    *result = LERP(LERP(x0y0, x1y0, xf), LERP(x0y1, x1y1, xf), yf);
}

- (void) elevationsForSector:(WWSector*)sector
                      numLat:(int)numLat
                      numLon:(int)numLon
        verticalExaggeration:(double)verticalExaggeration
                      result:(double[])result
{
    double minLatSelf = [_sector minLatitude];
    double maxLatSelf = [_sector maxLatitude];
    double minLonSelf = [_sector minLongitude];
    double maxLonSelf = [_sector maxLongitude];
    double deltaLatSelf = [_sector deltaLat];
    double deltaLonSelf = [_sector deltaLon];

    double minLatOther = [sector minLatitude];
    double maxLatOther = [sector maxLatitude];
    double minLonOther = [sector minLongitude];
    double maxLonOther = [sector maxLongitude];
    double deltaLatOther = (maxLatOther - minLatOther) / (numLat > 1 ? numLat - 1 : 1);
    double deltaLonOther = (maxLonOther - minLonOther) / (numLon > 1 ? numLon - 1 : 1);

    double lat = minLatOther;
    double lon = minLonOther;

    int index = 0;
    const short* pixels = [self->imageData bytes];

    for (int j = 0; j < numLat; j++)
    {
        // Explicitly set the first and last row to minLat and maxLat, respectively, rather than using the
        // accumulated lat value, in order to ensure that the Cartesian points of adjacent sectors match perfectly.
        if (j == 0)
            lat = minLatOther;
        else if (j == numLat - 1)
            lat = maxLatOther;
        else
            lat += deltaLatOther;

        if (lat >= minLatSelf && lat <= maxLatSelf)
        {
            // Texel coordinates of the specified location, given an image origin in the upper left corner.
            double y = (_imageHeight - 1) * (maxLatSelf - lat) / deltaLatSelf;
            int y0 = CLAMP(0, _imageHeight - 1, (int) y);
            int y1 = CLAMP(0, _imageHeight - 1, y0 + 1);
            double yf = y - y0;

            for (int i = 0; i < numLon; i++)
            {
                // Explicitly set the first and last row to minLon and maxLon, respectively, rather than using the
                // accumulated lon value, in order to ensure that the Cartesian points of adjacent sectors match perfectly.
                if (i == 0)
                    lon = minLonOther;
                else if (i == numLon - 1)
                    lon = maxLonOther;
                else
                    lon += deltaLonOther;

                if (lon >= minLonSelf && lon <= maxLonSelf)
                {
                    // Texel coordinates of the specified location, given an image origin in the upper left corner.
                    double x = (_imageWidth - 1) * (lon - minLonSelf) / deltaLonSelf;
                    int x0 = CLAMP(0, _imageWidth - 1, (int) x);
                    int x1 = CLAMP(0, _imageWidth - 1, x0 + 1);
                    double xf = x - x0;

                    short x0y0 = pixels[x0 + y0 * _imageWidth];
                    short x1y0 = pixels[x1 + y0 * _imageWidth];
                    short x0y1 = pixels[x0 + y1 * _imageWidth];
                    short x1y1 = pixels[x1 + y1 * _imageWidth];

                    result[index] = LERP(LERP(x0y0, x1y0, xf), LERP(x0y1, x1y1, xf), yf);
                    result[index] *= verticalExaggeration;
                }

                index++;
            }
        }
        else
        {
            index += numLon; // Skip this row.
        }
    }
}

- (long) sizeInBytes
{
    return self->imageData != nil ? [self->imageData length] : 0;
}

- (void) main
{
    // Read the elevation data's image from disk and add it to the memory cache. This is done in a background thread.

    @autoreleasepool
    {
        NSMutableDictionary* dict = [[NSMutableDictionary alloc] init];
        [dict setObject:_filePath forKey:WW_FILE_PATH];

        @try
        {
            if (![self isCancelled])
            {
                [self loadImage];

                [_memoryCache putValue:self forKey:_filePath];
                _memoryCache = nil; // don't need the cache anymore
                [dict setObject:WW_SUCCEEDED forKey:WW_REQUEST_STATUS];
            }
            else
            {
                [dict setObject:WW_CANCELED forKey:WW_REQUEST_STATUS];
            }
        }
        @catch (NSException* exception)
        {
            [dict setObject:WW_FAILED forKey:WW_REQUEST_STATUS];

            NSString* msg = [NSString stringWithFormat:@"Opening data grid file %@", _filePath];
            WWLogE(msg, exception);
        }
        @finally
        {
            NSNotification* notification = [NSNotification notificationWithName:WW_REQUEST_STATUS object:_object userInfo:dict];
            [[NSNotificationCenter defaultCenter] postNotification:notification];
            _object = nil; // don't need the object anymore
        }
    }
}

- (void) loadImage
{
    self->imageData = [[NSData alloc] initWithContentsOfFile:_filePath];
}

@end