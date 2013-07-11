/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import "WorldWind/Util/WWTile.h"
#import "WorldWind/Navigate/WWNavigatorState.h"
#import "WorldWind/Geometry/WWBoundingBox.h"
#import "WorldWind/Geometry/WWLocation.h"
#import "WorldWind/Geometry/WWPosition.h"
#import "WorldWind/Geometry/WWSector.h"
#import "WorldWind/Geometry/WWVec4.h"
#import "WorldWind/Render/WWDrawContext.h"
#import "WorldWind/Terrain/WWGlobe.h"
#import "WorldWind/Util/WWFrameStatistics.h"
#import "WorldWind/Util/WWLevel.h"
#import "WorldWind/Util/WWMath.h"
#import "WorldWind/Util/WWMemoryCache.h"
#import "WorldWind/Util/WWTileFactory.h"
#import "WorldWind/Util/WWTileList.h"
#import "WorldWind/WWLog.h"

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

    if (level == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Tile level is nil")
    }

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

    tileWidth = [level tileWidth];
    tileHeight = [level tileHeight];
    texelSize = [level texelSize];
    tileKey = [NSString stringWithFormat:@"%d,%d,%d", [level levelNumber], _row, _column];
    nearestPoint = [[WWVec4 alloc] initWithZeroVector];

    return self;
}

- (BOOL) isEqual:(id)anObject
{
    if (anObject == nil)
        return NO;

    if (![anObject isKindOfClass:[self class]])
        return NO;

    return [tileKey isEqual:((WWTile*) anObject)->tileKey];
}

- (NSUInteger) hash
{
    return [self->tileKey hash];
}

- (long) sizeInBytes
{
    long size = 4 // child pointer
    + (4 + 32) // sector
    + (4) // level pointer (the level is common to the layer or tessellator so not included here
    + (8) // row and column
    + (8) // texel size
    + (4 + 32) // reference point
    + (4 + 676) // bounding box
    + 8 // min and max height
    + (4 + 32) // nearest point
    + 8; // extent timestamp and vertical exaggeration

    return size;
}

- (int) tileWidth
{
    return tileWidth;
}

- (int) tileHeight
{
    return tileHeight;
}

- (double) texelSize
{
    return texelSize;
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

    int row = (int) ((latitude + 90) / delta); // implicitly computes the floor of (minLat + 90) / delta.
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

    int col = (int) ((longitude + 180) / delta); // implicitly computes the floor of (longitude + 180) / delta.
    // If longitude is at the end of the grid, subtract 1 from the computed column to return the last column.
    if (longitude == 180)
    {
        col -= 1;
    }

    return col;
}

+ (int) computeLastRow:(double)delta maxLatitude:(double)maxLatitude
{
    if (delta <= 0)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Tile delta is less than or equal to 0")
    }

    if (maxLatitude < -90 || maxLatitude > 90)
    {
        NSString* msg = [NSString stringWithFormat:@"Max latitude %f is out of range", maxLatitude];
        WWLOG_AND_THROW(NSInvalidArgumentException, msg)
    }

    int row = (int) ceil((maxLatitude + 90) / delta - 1);
    // If max latitude is in the first row, set the max row to 0.
    if (maxLatitude + 90 < delta)
    {
        row = 0;
    }

    return row;
}

+ (int) computeLastColumn:(double)delta maxLongitude:(double)maxLongitude
{
    if (delta <= 0)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Tile delta is less than or equal to 0")
    }

    if (maxLongitude < -180 || maxLongitude > 180)
    {
        NSString* msg = [NSString stringWithFormat:@"Max longitude %f is out of range", maxLongitude];
        WWLOG_AND_THROW(NSInvalidArgumentException, msg)
    }

    int col = (int) ceil((maxLongitude + 180) / delta - 1);
    // If max longitude is in the first column, set the max column to 0.
    if (maxLongitude + 180 < delta)
    {
        col = 0;
    }

    return col;
}

+ (WWSector*) computeSector:(WWLevel*)level row:(int)row column:(int)column
{
    if (level == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Level is nil")
    }

    if (row < 0)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Row is less than 0")
    }

    if (column < 0)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Column is less than 0")
    }

    double deltaLat = [[level tileDelta] latitude];
    double deltaLon = [[level tileDelta] longitude];

    double minLat = -90 + row * deltaLat;
    double minLon = -180 + column * deltaLon;
    double maxLat = minLat + deltaLat;
    double maxLon = minLon + deltaLon;

    return [[WWSector alloc] initWithDegreesMinLatitude:minLat maxLatitude:maxLat
                                           minLongitude:minLon maxLongitude:maxLon];
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

- (NSArray*) subdivide:(WWLevel*)nextLevel cache:(WWMemoryCache*)cache tileFactory:(id <WWTileFactory>)tileFactory
{
    if (nextLevel == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Next level is nil")
    }

    if (tileFactory == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Tile factory is nil")
    }

    WWTileList* childList = [cache getValueForKey:self->tileKey];
    if (childList != nil)
    {
        return [childList tiles];
    }
    else
    {
        NSArray* childTiles = [self subdivide:nextLevel tileFactory:tileFactory];
        childList = [[WWTileList alloc] initWithTiles:childTiles];
        [cache putValue:childList forKey:self->tileKey];
        return childTiles;
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

    NSMutableArray* children = [[NSMutableArray alloc] initWithCapacity:4];

    double p0 = [_sector minLatitude];
    double p2 = [_sector maxLatitude];
    double p1 = [_sector centroidLat];

    double t0 = [_sector minLongitude];
    double t2 = [_sector maxLongitude];
    double t1 = [_sector centroidLon];

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

    return children;
}

- (BOOL) mustSubdivide:(WWDrawContext* __unsafe_unretained)dc detailFactor:(double)detailFactor
{
    WWGlobe* __unsafe_unretained globe = [dc globe];
    WWPosition* __unsafe_unretained eyePos = [dc eyePosition];

    // Compute the point on the tile that is nearest to the eye point. Use the minimum elevation because it provides a
    // reasonable estimate for distance, and the eye point always gets closer to the point as it moves closer to the
    // terrain surface.
    double nearestLat = WWCLAMP([eyePos latitude], [_sector minLatitude], [_sector maxLatitude]);
    double nearestLon = WWCLAMP([eyePos longitude], [_sector minLongitude], [_sector maxLongitude]);
    [globe computePointFromPosition:nearestLat longitude:nearestLon altitude:minHeight outputPoint:nearestPoint];

    // Compute the cell size and distance to the nearest point on the tile. Cell size is radius * radian texel size.
    double cellSize = MAX([globe equatorialRadius], [globe polarRadius]) * texelSize;
    double distance = [nearestPoint distanceTo3:[[dc navigatorState] eyePoint]];

    // Split when the cell height (length of a texel) becomes greater than the specified fraction of the eye distance.
    // The fraction is specified as a power of 10. For example, a detail factor of 3 means split when the cell height
    // becomes more than one thousandth of the eye distance. Another way to say it is, use the current tile if the cell
    // height is less than the specified fraction of the eye distance.
    //
    // Note: It's tempting to instead compare a screen pixel size to the texel size, but that calculation is window-
    // size dependent and results in selecting an excessive number of tiles when the window is large.

    return cellSize > distance * pow(10, -detailFactor);
}

- (void) update:(WWDrawContext* __unsafe_unretained)dc;
{
    if (dc == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Draw context is nil")
    }

    WWGlobe* __unsafe_unretained globe = [dc globe];
    NSTimeInterval elevationTimestamp = [globe elevationTimestamp];
    double verticalExaggeration = [dc verticalExaggeration];

    if (extentTimestamp != elevationTimestamp || extentVerticalExaggeration != verticalExaggeration)
    {
        // Compute the minimum and maximum elevations for this tile's sector, or use zero if the globe has no elevations
        // in this tile's coverage area. In the latter case the globe does not modify the result parameter.
        double extremes[2] = {0, 0};
        [globe minAndMaxElevationsForSector:_sector result:extremes];

        // Multiply the minimum and maximum elevations by the scene's vertical exaggeration. This ensures that the
        // elevations to used build the terrain are contained by this tile's extent.
        minHeight = extremes[0] * verticalExaggeration;
        maxHeight = extremes[1] * verticalExaggeration;
        if (minHeight == maxHeight)
            minHeight = maxHeight + 10; // TODO: Determine if this is necessary.

        // Compute a bounding box for this tile that contains the terrain surface in the tile's coverage area.
        if (_extent == nil)
            _extent = [[WWBoundingBox alloc] initWithUnitBox];
        [_extent setToSector:_sector onGlobe:globe minElevation:minHeight maxElevation:maxHeight];

        // Compute the reference point used as a local coordinate origin for the tile.
        if (_referencePoint == nil)
            _referencePoint = [[WWVec4 alloc] initWithZeroVector];
        [globe computePointFromPosition:[_sector centroidLat] longitude:[_sector centroidLon] altitude:minHeight
                            outputPoint:_referencePoint];

        // Set the geometry extent to the globe's elevation timestamp on which the geometry is based. This ensures that
        // the geometry timestamp can be reliably compared to the elevation timestamp in subsequent frames.
        extentTimestamp = elevationTimestamp;
        extentVerticalExaggeration = verticalExaggeration;
        [[dc frameStatistics] incrementTileUpdateCount:1];
    }
}

@end