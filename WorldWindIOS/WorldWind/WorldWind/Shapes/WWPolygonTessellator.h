/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.

 @version $Id$
 */

#import <Foundation/Foundation.h>
#import "WorldWind/GLU/glu.h"

@interface WWPolygonTessellator : NSObject
{
@protected
    GLUtesselator* tess;
    GLboolean isBoundaryEdge;
    GLdouble vertexCoord[3];
    NSMutableArray* vertexIndices; // vertex indices collected during tessellation
    void (^combineBlock)(double x, double y, double z, GLushort* outIndex);
}

/// interior indices collected during tessellation
@property (nonatomic) NSMutableArray* interiorIndices;

/// boundary indices collected during tessellation
@property (nonatomic) NSMutableArray* boundaryIndices;

/// @name Initializing Polygon Tessellators

- (WWPolygonTessellator*) init;

/// @name Tessellating Polygons

- (void) reset;

- (void) setCombineBlock:(void (^)(double x, double y, double z, GLushort* outIndex))block;

- (void) setPolygonNormal:(double)x y:(double)y z:(double)z;

- (void) beginPolygon;

- (void) beginContour;

- (void) addVertex:(double)x y:(double)y z:(double)z withIndex:(GLushort)index;

- (void) endContour;

- (void) endPolygon;

/// @name Methods of Interest Only to Subclasses

- (void) tessBegin:(GLenum)type;

- (void) tessEdgeFlag:(GLboolean)boundaryEdge;

- (void) tessVertex:(void*)vertexData;

- (void) tessEnd;

- (void) tessCombine:(GLdouble[3])coords vertexData:(void*[4])vertexData weight:(GLdouble[4])weight outData:(void**)outData;

@end