/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import <Foundation/Foundation.h>
#import "WorldWind/Util/WWTile.h"

@class WWTessellator;
@class WWDrawContext;

@interface WWTerrainTile : WWTile

@property (readonly) WWTessellator* tessellator;

- (WWTerrainTile*) initWithSector:(WWSector*)sector
                            level:(int)level
                              row:(int)row
                           column:(int)column
                      tessellator:(WWTessellator*)tessellator;
- (void) beginRendering:(WWDrawContext*)dc;
- (void) endRendering:(WWDrawContext*)dc;
- (void) render:(WWDrawContext*)dc;

@end
