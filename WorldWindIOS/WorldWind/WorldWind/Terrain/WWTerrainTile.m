/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import "WorldWind/Terrain/WWTerrainTile.h"
#import "WorldWind/Terrain/WWTessellator.h"
#import "WorldWind/WWLog.h"
#import "WorldWind/Geometry/WWVec4.h"
#import "WorldWind/Terrain/WWGlobe.h"
#import "WorldWind/Geometry/WWSector.h"
#import "WorldWind/Terrain/WWTerrainGeometry.h"
#import "WWDrawContext.h"

@implementation WWTerrainTile

- (WWTerrainTile*) initWithSector:(WWSector*)sector
                            level:(WWLevel*)level
                              row:(int)row
                           column:(int)column
                      tessellator:(WWTessellator*)tessellator
{
    // superclass checks sector, level, row and column arguments.

    if (tessellator == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Tessellator is nil")
    }

    self = [super initWithSector:sector level:level row:row column:column];

    _tessellator = tessellator;

    _numLonCells = 5;
    _numLatCells = 5;

    //TODO: set the resolution (if that property is still necessary).

    return self;
}

- (long) sizeInBytes
{
    long terrainGeometrySize = (4 + 32) // reference center
            + (4 + 128) // transformation matrix
            + (4) // numPoints
            + (4 + (_numLatCells + 3) * (_numLonCells + 3) * 3 * 4); // points

    long size = terrainGeometrySize
            + 4 // tessellator pointer
            + (8) // numlat + numlon fields
            + (4); // terrain geometry pointer

    return size + [super sizeInBytes];
}

- (void) beginRendering:(WWDrawContext*)dc
{
    [_tessellator beginRendering:dc tile:self];
}

- (void) endRendering:(WWDrawContext*)dc
{
    [_tessellator endRendering:dc tile:self];
}

- (void) render:(WWDrawContext*)dc
{
    [_tessellator render:dc tile:self];
}

- (void) renderWireframe:(WWDrawContext*)dc
{
    [_tessellator renderWireFrame:dc tile:self];
}

- (void) renderOutline:(WWDrawContext*)dc
{
    [_tessellator renderOutline:dc tile:self];
}

- (void) surfacePoint:(double)latitude longitude:(double)longitude offset:(double)offset result:(WWVec4*)result
{
    if (result == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Result is nil")
    }

    WWSector* tileSector = [self sector];
    int tileWidth = [self tileWidth];
    int tileHeight = [self tileHeight];

    double minLat = [tileSector minLatitude];
    double maxLat = [tileSector maxLatitude];
    double minLon = [tileSector minLongitude];
    double maxLon = [tileSector maxLongitude];

    // Compute the location's horizontal (s) and vertical (t) parameterized coordinates within the tiles 2D grid of
    // points as a floating-point value in the range [0, tileWidth] and [0, tileHeight]. These coordinates indicate
    // which cell contains the location, as well as the location's placement within the cell. Note that this method
    // assumes that the caller has tested whether the location is contained within the tile's sector.
    double s = (longitude - minLon) / (maxLon - minLon) * tileWidth;
    double t = (latitude - minLat) / (maxLat - minLat) * tileHeight;

    // Get the coordinates for the four vertices defining the cell this point is in. Tile vertices start in the lower
    // left corner and proceed in row major order across the tile. The tile contains three more vertices per row or
    // column than the tile width or height: one to convert between cell count and vertex count,
    // and two for the skirt surrounding the tile. We convert from parameterized coordinates to the vertex position
    // by adding an offset of 1 to the s and t indices for the extra skirt vertices,
    // multiplying the t index by the row stride, and adding the s index. We then convert from vertex position to
    // coordinate position by multiplying the vertex position by 3. Vertices in the points array are organized in the
    // following order: lower-left, lower-right, upper-left, upper-right. The cell's diagonal starts at the
    // lower-left vertex and ends at the upper-right vertex.
    int si = (s < tileWidth ? (int) s : tileWidth - 1) + 1;
    int ti = (t < tileHeight ? (int) t : tileHeight - 1) + 1;
    int rowStride = tileWidth + 3;

    float* vertices = [_terrainGeometry points];
    float points[12]; // temporary working buffer
    int k = 3 * (si + ti * rowStride); // lower-left and lower-right vertices
    for (int i = 0; i < 6; i++)
    {
        points[i] = vertices[k + i];
    }

    k = 3 * (si + (ti + 1) * rowStride); // upper-left and upper-right vertices
    for (int i = 6; i < 12; i++)
    {
        points[i] = vertices[k + i];
    }

    // Compute the location's corresponding point on the cell in tile local coordinates,
    // given the fractional portion of the parameterized s and t coordinates. These values indicate the location's
    // relative placement within the cell. The cell's vertices are defined in the following order: lower-left,
    // lower-right, upper-left, upper-right. The cell's diagonal starts at the lower-left vertex and ends at the
    // upper-right vertex.
    double sf = (s < tileWidth ? s - (int) s : 1);
    double tf = (t < tileHeight ? t - (int) t : 1);

    if (sf < tf)
    {
        double x = points[3] + (1 - sf) * (points[0] - points[3]) + tf * (points[9] - points[3]);
        double y = points[4] + (1 - sf) * (points[1] - points[4]) + tf * (points[10] - points[4]);
        double z = points[5] + (1 - sf) * (points[2] - points[5]) + tf * (points[11] - points[5]);
        [result set:x y:y z:z];
    }
    else
    {
        double x = points[6] + sf * (points[9] - points[6]) + (1 - tf) * (points[0] - points[6]);
        double y = points[7] + sf * (points[10] - points[7]) + (1 - tf) * (points[1] - points[7]);
        double z = points[8] + sf * (points[11] - points[8]) + (1 - tf) * (points[2] - points[8]);
        [result set:x y:y z:z];
    }

    [result add3:[_terrainGeometry referenceCenter]];

    // Apply the offset.
    WWVec4* normal = [[WWVec4 alloc] initWithZeroVector];
    [[_tessellator globe] surfaceNormalAtPoint:result result:normal];
    [WWVec4 pointOnLine:result direction:normal t:offset result:result];
}
@end
