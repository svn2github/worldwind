/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import <Foundation/Foundation.h>

@class WWTessellator;
@class WWTerrainTile;
@class WWTerrainTileList;
@class WWDrawContext;
@class WWPosition;
@class WWSector;
@class WWVec4;

@interface WWGlobe : NSObject

@property(readonly, nonatomic) double equatorialRadius;
@property(readonly, nonatomic) double polarRadius;
@property(readonly, nonatomic) double es;
@property(readonly, nonatomic) double minElevation;
@property(readonly, nonatomic) WWTessellator* tessellator;

- (WWGlobe*) init;

- (WWTerrainTileList*) tessellate:(WWDrawContext*)dc;

- (void) computePointFromPosition:(double)latitude
                        longitude:(double)longitude
                         altitude:(double)altitude
                      outputPoint:(WWVec4*)result;

- (void) computePointFromPosition:(double)latitude
                        longitude:(double)longitude
                         altitude:(double)altitude
                           offset:(WWVec4*)offset
                      outputArray:(float [])result;

- (void) computePointsFromPositions:(WWSector*)sector
                             numLat:(int)numLat
                             numLon:(int)numLon
                    metersElevation:(double [])metersElevation
                  constantElevation:(double*)constantElevation
                             offset:(WWVec4*)offset
                        outputArray:(float [])result;

- (void) computePositionFromPoint:(double)x
                                y:(double)y
                                z:(double)z
                   outputPosition:(WWPosition*)result;

- (void) computeNormal:(double)latitude
             longitude:(double)longitude
           outputPoint:(WWVec4*)result;

- (void) computeNorthTangent:(double)latitude
                   longitude:(double)longitude
                  outputPoint:(WWVec4*)result;

- (double) getElevation:(double)latitude longitude:(double)longitude;

- (void) getElevations:(WWSector*)sector
                numLat:(int)numLat
                numLon:(int)numLon
      targetResolution:(double)targetResolution
  verticalExaggeration:(double)verticalExaggeration
           outputArray:(double[])outputArray;


@end
