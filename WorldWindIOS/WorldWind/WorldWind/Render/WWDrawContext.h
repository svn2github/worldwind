/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import <Foundation/Foundation.h>

@class WWGlobe;
@class WWLayerList;
@class WWTerrainTileList;
@class WWSector;

@interface WWDrawContext : NSObject

@property (readonly) NSDate* timestamp;
@property WWGlobe* globe;
@property WWLayerList* layers;
@property WWTerrainTileList* surfaceGeometry;
@property WWSector* visibleSector;

- (void) reset;

@end
