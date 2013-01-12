/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import "WorldWind/Util/WWTile.h"
#import "WorldWind/Util/WWLevel.h"
#import "WorldWind/Geometry/WWSector.h"
#import "WorldWind/WWLog.h"
#import "WorldWind/Geometry/WWLocation.h"
#import "WorldWind/Util/WWTileFactory.h"
#import "WorldWind/Util/WWLevelSet.h"

@implementation WWTile

- (WWTile*) initWithSector:(WWSector*)sector
                     level:(WWLevel*)level
                       row:(int)row
                    column:(int)column
{
    if (sector == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Tile sector is nil")
    }
    // TODO: Uncomment below when elevation model is implemented. Right now (1/10/13) it doesn't use levels.
//
//    if (level == nil)
//    {
//        WWLOG_AND_THROW(NSInvalidArgumentException, @"Tile level is nil")
//    }

    if (row < 0)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Tile row is less than 0")
    }

    if (column < 0)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Tile column is less than 0")
    }

    self = [super init];

    _sector = sector;
    _level = level;
    _row = row;
    _column = column;

    return self;
}

- (int) tileWidth
{
    return [[_level parent] tileWidth];
}

- (int) tileHeight
{
    return [[_level parent] tileHeight];
}

+ (int) computeRow:(double)delta latitude:(double)latitude
{
    if (delta <= 0)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Tile delta is less than or equal to 0")
    }

    if (latitude < -90 || latitude > 90)
    {
        NSString* msg = [NSString stringWithFormat:@"Latitude %f is out of range", latitude];
        WWLOG_AND_THROW(NSInvalidArgumentException, msg)
    }

    int row = (int) ((latitude + 90) / delta);
    // If latitude is at the end of the grid, subtract 1 from the computed row to return the last row.
    if (latitude == 90)
    {
        row -= 1;
    }

    return row;
}

+ (int) computeColumn:(double)delta longitude:(double)longitude
{
    if (delta <= 0)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Tile delta is less than or equal to 0")
    }

    if (longitude < -180 || longitude > 180)
    {
        NSString* msg = [NSString stringWithFormat:@"Longitude %f is out of range", longitude];
        WWLOG_AND_THROW(NSInvalidArgumentException, msg)
    }

    double gridLongitude = longitude + 180;
    if (gridLongitude < 0)
    {
        gridLongitude = 360 + gridLongitude;
    }

    int col = (int) (gridLongitude / delta);
    // If longitude is at the end of the grid, subtract 1 from the computed column to return the last column.
    if (longitude == 180)
    {
        col -= 1;
    }

    return col;
}

+ (void) createTilesForLevel:(WWLevel*)level
                 tileFactory:(id <WWTileFactory>)tileFactory
                    tilesOut:(NSMutableArray*)tilesOut
{
    if (level == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Level is nil")
    }

    if (tileFactory == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Tile factory is nil")
    }

    if (tilesOut == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Output array is nil")
    }

    double deltaLat = [[level tileDelta] latitude];
    double deltaLon = [[level tileDelta] longitude];

    WWSector* sector = [level sector];
    int firstRow = [WWTile computeRow:deltaLat latitude:[sector minLatitude]];
    int lastRow = [WWTile computeRow:deltaLat latitude:[sector maxLatitude]];

    int firstCol = [WWTile computeColumn:deltaLon longitude:[sector minLongitude]];
    int lastCol = [WWTile computeColumn:deltaLon longitude:[sector maxLongitude]];

    double firstRowLat = -90 + firstRow * deltaLat;
    double firstRowLon = -180 + firstCol * deltaLon;

    double minLat = firstRowLat;
    double minLon;
    double maxLat;
    double maxLon;

    for (int row = firstRow; row <= lastRow; row++)
    {
        maxLat = minLat + deltaLat;
        minLon = firstRowLon;

        for (int col = firstCol; col <= lastCol; col++)
        {
            maxLon = minLon + deltaLon;
            WWSector* tileSector = [[WWSector alloc] initWithDegreesMinLatitude:minLat
                                                                    maxLatitude:maxLat
                                                                   minLongitude:minLon
                                                                   maxLongitude:maxLon];
            WWTile* tile = [tileFactory createTile:tileSector level:level row:row column:col];
            [tilesOut addObject:tile];

            minLon = maxLon;
        }

        minLat = maxLat;
    }
}

@end
