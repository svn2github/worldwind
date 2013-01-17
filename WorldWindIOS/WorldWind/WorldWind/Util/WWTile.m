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
#import "WorldWind/Render/WWDrawContext.h"
#import "WorldWind/Geometry/WWVec4.h"
#import "WorldWind/Navigate/WWNavigatorState.h"
#import "WorldWind/Terrain/WWGlobe.h"

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
//
//    _referencePoints = [[NSMutableArray alloc] initWithCapacity:5];
//    [_referencePoints addObject:[[WWVec4 alloc] initWithZeroVector]];
//    [_referencePoints addObject:[[WWVec4 alloc] initWithZeroVector]];
//    [_referencePoints addObject:[[WWVec4 alloc] initWithZeroVector]];
//    [_referencePoints addObject:[[WWVec4 alloc] initWithZeroVector]];
//    [_referencePoints addObject:[[WWVec4 alloc] initWithZeroVector]];

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

- (NSArray*) subdivide:(WWLevel*)nextLevel tileFactory:(id <WWTileFactory>)tileFactory
{
    if (nextLevel == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Next level is nil")
    }

    if (tileFactory == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Tile factory is nil")
    }

//    NSMutableArray* children = [[NSMutableArray alloc] initWithCapacity:4];
    if (self->children != nil)
        return self->children;

    self->children = [[NSMutableArray alloc] initWithCapacity:4];

    double p0 = [_sector minLatitude];
    double p2 = [_sector maxLatitude];
    double p1 = 0.5 * (p0 + p2);

    double t0 = [_sector minLongitude];
    double t2 = [_sector maxLongitude];
    double t1 = 0.5 * (t0 + t2);


    int subRow = 2 * _row;
    int subCol = 2 * _column;
    WWSector* childSector = [[WWSector alloc] initWithDegreesMinLatitude:p0 maxLatitude:p1
                                                            minLongitude:t0 maxLongitude:t1];
    [children addObject:[tileFactory createTile:childSector level:nextLevel row:subRow column:subCol]];

    subCol = 2 * _column + 1;
    childSector = [[WWSector alloc] initWithDegreesMinLatitude:p0 maxLatitude:p1
                                                  minLongitude:t1 maxLongitude:t2];
    [children addObject:[tileFactory createTile:childSector level:nextLevel row:subRow column:subCol]];

    subRow = 2 * _row + 1;
    subCol = 2 * _column;
    childSector = [[WWSector alloc] initWithDegreesMinLatitude:p1 maxLatitude:p2
                                                  minLongitude:t0 maxLongitude:t1];
    [children addObject:[tileFactory createTile:childSector level:nextLevel row:subRow column:subCol]];

    subCol = 2 * _column + 1;
    childSector = [[WWSector alloc] initWithDegreesMinLatitude:p1 maxLatitude:p2
                                                  minLongitude:t1 maxLongitude:t2];
    [children addObject:[tileFactory createTile:childSector level:nextLevel row:subRow column:subCol]];

    return self->children;
}

- (BOOL) mustSubdivide:(WWDrawContext*)dc detailFactor:(double)detailFactor
{
    WWVec4* eyePoint = [[dc navigatorState] eyePoint];

    double d1 = [eyePoint distanceSquared3:[_referencePoints objectAtIndex:0]];
    double d2 = [eyePoint distanceSquared3:[_referencePoints objectAtIndex:1]];
    double d3 = [eyePoint distanceSquared3:[_referencePoints objectAtIndex:2]];
    double d4 = [eyePoint distanceSquared3:[_referencePoints objectAtIndex:3]];
    double d5 = [eyePoint distanceSquared3:[_referencePoints objectAtIndex:4]];

    // Find the minimum distance. Compute the cell height at the corresponding point. Cell height is radius * radian
    // texel size.

    double texelSize = [_level texelSize];

    double minDistance = d1;
    double cellSize = [[_referencePoints objectAtIndex:0] length3] * texelSize;

    if (d2 < minDistance)
    {
        minDistance = d2;
        cellSize = [[_referencePoints objectAtIndex:1] length3] * texelSize;
    }
    if (d3 < minDistance)
    {
        minDistance = d3;
        cellSize = [[_referencePoints objectAtIndex:2] length3] * texelSize;
    }
    if (d4 < minDistance)
    {
        minDistance = d4;
        cellSize = [[_referencePoints objectAtIndex:3] length3] * texelSize;
    }
    if (d5 < minDistance)
    {
        minDistance = d5;
        cellSize = [[_referencePoints objectAtIndex:4] length3] * texelSize;
    }

    // Split when the cell height (length of a texel) becomes greater than the specified fraction of the eye distance.
    // The fraction is specified as a power of 10. For example, a detail factor of 3 means split when the cell height
    // becomes more than one thousandth of the eye distance. Another way to say it is, use the current tile if the cell
    // height is less than the specified fraction of the eye distance.
    //
    // Note: It's tempting to instead compare a screen pixel size to the texel size, but that calculation is window-
    // size dependent and results in selecting an excessive number of tiles when the window is large.

    return cellSize > sqrt(minDistance) * pow(10, -detailFactor);
}

- (void) updateReferencePoints:(WWGlobe*)globe verticalExaggeration:(double)verticalExaggeration
{
    if (globe == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Globe is nil")
    }

    if (_referencePoints == nil)
    {
        _referencePoints = [[NSMutableArray alloc] initWithCapacity:5];
        [_referencePoints addObject:[[WWVec4 alloc] initWithZeroVector]];
        [_referencePoints addObject:[[WWVec4 alloc] initWithZeroVector]];
        [_referencePoints addObject:[[WWVec4 alloc] initWithZeroVector]];
        [_referencePoints addObject:[[WWVec4 alloc] initWithZeroVector]];
        [_referencePoints addObject:[[WWVec4 alloc] initWithZeroVector]];
        [_sector computeReferencePoints:globe verticalExaggeration:verticalExaggeration result:_referencePoints];
    }
}

- (void) updateExtent:(WWGlobe*)globe verticalExaggeration:(double)verticalExaggeration
{
    if (globe == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Globe is nil")
    }

    if (_extent == nil)
        _extent = [_sector computeBoundingBox:globe verticalExaggeration:verticalExaggeration];
}

@end
