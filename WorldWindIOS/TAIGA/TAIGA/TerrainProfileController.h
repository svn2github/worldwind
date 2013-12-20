/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import <Foundation/Foundation.h>

@class TerrainProfileView;

@interface TerrainProfileController : NSObject

@property (nonatomic, readonly) TerrainProfileView* terrainProfileView;

- (TerrainProfileController*) initWithTerrainProfileView:(TerrainProfileView*)terrainProfileView;

@end