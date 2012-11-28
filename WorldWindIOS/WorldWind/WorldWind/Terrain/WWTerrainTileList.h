/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import <Foundation/Foundation.h>

@class WWSector;
@class WWTessellator;

@interface WWTerrainTileList : NSObject

@property WWSector* sector;
@property (readonly) WWTessellator* tessellator;

- (WWTerrainTileList*) initWithTessellator:(WWTessellator*)tessellator;

@end
