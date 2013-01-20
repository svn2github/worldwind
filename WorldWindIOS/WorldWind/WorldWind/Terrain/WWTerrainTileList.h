/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import <Foundation/Foundation.h>

@class WWSector;
@class WWTessellator;
@class WWDrawContext;
@class WWTerrainTile;
@class WWVec4;

/**
* Holds the list of terrain tiles active in the current frame.
*/
@interface WWTerrainTileList : NSObject
{
@protected
    NSMutableArray* tiles;
}

@property(nonatomic) WWSector* sector;
@property(readonly, nonatomic, weak) WWTessellator* tessellator;

- (WWTerrainTileList*) initWithTessellator:(WWTessellator*)tessellator;

- (void) addTile:(WWTerrainTile*)tile;

- (WWTerrainTile*) objectAtIndex:(NSUInteger)index;

- (NSUInteger) count;

- (void) beginRendering:(WWDrawContext*)dc;

- (void) endRendering:(WWDrawContext*)dc;

/**
* Computes a point on the terrain at a specified latitude and longitude.
*
* @param latitude The point's latitude.
* @param longitude The point's longitude.
* @param offset An offset in meters from the terrain surface at which to place the point. The returned point is
* displaced by this amount along the normal vector _to the globe_.
* @param result A pointer to a vector in which to store the result.
*
* @return YES if the point could be computed from the current list of terrain tiles, otherwise NO.
*
* @exception NSInvalidArgumentException If the result pointer is nil.
*/
- (BOOL) surfacePoint:(double)latitude
            longitude:(double)longitude
               offset:(double)offset
               result:(WWVec4*)result;

@end
