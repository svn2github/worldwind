/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.

 @version $Id$
 */

#import <Foundation/Foundation.h>

@class WWVec4;
@class WWMatrix;

@interface WWTerrainGeometry : NSObject

@property (nonatomic) WWVec4* referenceCenter;
@property (nonatomic) WWMatrix* transformationMatrix;
@property (nonatomic) int numPoints;
@property (nonatomic) float* points;


@end