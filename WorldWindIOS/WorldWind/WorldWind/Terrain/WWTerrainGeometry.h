/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.

 @version $Id$
 */

#import <Foundation/Foundation.h>

@class WWVec4;
@class WWMatrix;

@interface WWTerrainGeometry : NSObject

@property WWVec4* referenceCenter;
@property WWMatrix* transformationMatrix;
@property NSObject* vboCacheKey;
@property int numPoints;
@property float* points;
@property BOOL mustRegenerateVbos;


@end