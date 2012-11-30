/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import <Foundation/Foundation.h>

@class WWTessellator;
@class WWTerrainTileList;
@class WWDrawContext;

@interface WWGlobe : NSObject

@property (readonly) WWTessellator* tessellator;

- (WWGlobe*) init;
- (WWTerrainTileList*) tessellate:(WWDrawContext*)dc;

@end
