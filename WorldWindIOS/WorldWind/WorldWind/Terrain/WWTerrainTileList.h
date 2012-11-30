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

@interface WWTerrainTileList : NSObject
{
@protected
    NSMutableArray* tiles;
}

@property WWSector* sector;
@property (readonly) WWTessellator* tessellator;

- (WWTerrainTileList*) initWithTessellator:(WWTessellator*)tessellator;
- (void) addTile:(WWTerrainTile*)tile;
- (WWTerrainTile*) objectAtIndex:(NSUInteger)index;
- (NSUInteger) count;
- (void) beginRendering:(WWDrawContext*)dc;
- (void) endRendering:(WWDrawContext*)dc;

@end
