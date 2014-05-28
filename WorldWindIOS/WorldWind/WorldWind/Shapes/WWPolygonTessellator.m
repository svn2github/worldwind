/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.

 @version $Id$
 */

#import "WWPolygonTessellator.h"
#import "WorldWind/WWLog.h"

void WWPolygonTessellatorBegin(GLenum type, void* userData)
{
    [(__bridge WWPolygonTessellator*) userData tessBegin:type];
}

void WWPolygonTessellatorEdgeFlag(GLboolean boundaryEdge, void* userData)
{
    [(__bridge WWPolygonTessellator*) userData tessEdgeFlag:boundaryEdge];
}

void WWPolygonTessellatorVertex(void* vertexData, void* userData)
{
    [(__bridge WWPolygonTessellator*) userData tessVertex:vertexData];
}

void WWPolygonTessellatorEnd(void* userData)
{
    [(__bridge WWPolygonTessellator*) userData tessEnd];
}

void WWPolygonTessellatorCombine(GLdouble coords[3], void* vertexData[4], GLdouble weight[4], void** outData, void* userData)
{
    [(__bridge WWPolygonTessellator*) userData tessCombine:coords vertexData:vertexData weight:weight outData:outData];
}

@implementation WWPolygonTessellator

- (WWPolygonTessellator*) init
{
    self = [super init];

    tess = gluNewTess();
    gluTessCallback(tess, GLU_TESS_BEGIN_DATA, (_GLUfuncptr) &WWPolygonTessellatorBegin);
    gluTessCallback(tess, GLU_TESS_EDGE_FLAG_DATA, (_GLUfuncptr) &WWPolygonTessellatorEdgeFlag);
    gluTessCallback(tess, GLU_TESS_VERTEX_DATA, (_GLUfuncptr) &WWPolygonTessellatorVertex);
    gluTessCallback(tess, GLU_TESS_END_DATA, (_GLUfuncptr) &WWPolygonTessellatorEnd);
    gluTessCallback(tess, GLU_TESS_COMBINE_DATA, (_GLUfuncptr) &WWPolygonTessellatorCombine);

    vertexIndices = [[NSMutableArray alloc] init];
    _interiorIndices = [[NSMutableArray alloc] init];
    _boundaryIndices = [[NSMutableArray alloc] init];

    return self;
}

- (void) dealloc
{
    if (tess)
    {
        gluDeleteTess(tess);
        tess = NULL;
    }
}

- (void) reset
{
    [vertexIndices removeAllObjects];
    [_interiorIndices removeAllObjects];
    [_boundaryIndices removeAllObjects];
    combineBlock = NULL;
}

- (void) setCombineBlock:(void (^)(double x, double y, double z, GLushort* outIndex))block
{
    combineBlock = block;
}

- (void) setPolygonNormal:(double)x y:(double)y z:(double)z
{
    gluTessNormal(tess, x, y, z);
}

- (void) beginPolygon
{
    gluTessBeginPolygon(tess, (__bridge void*) self); // Use self as the polygon user data to enable callbacks to this instance.
}

- (void) beginContour
{
    gluTessBeginContour(tess);
}

- (void) addVertex:(double)x y:(double)y z:(double)z withIndex:(GLushort)index
{
    vertexCoord[0] = x;
    vertexCoord[1] = y;
    vertexCoord[2] = z;

    NSNumber* vertexIndex = [NSNumber numberWithUnsignedShort:index];
    [vertexIndices addObject:vertexIndex];

    gluTessVertex(tess, vertexCoord, (__bridge void*) vertexIndex); // Associate the vertex with its index in the vertex array.
}

- (void) endContour
{
    gluTessEndContour(tess);
}

- (void) endPolygon
{
    gluTessEndPolygon(tess);
}

- (void) tessBegin:(GLenum)type
{
    // Intentionally left blank.
}

- (void) tessEdgeFlag:(GLboolean)boundaryEdge
{
    isBoundaryEdge = boundaryEdge;
}

- (void) tessVertex:(GLvoid*)vertex
{
    // Accumulate interior indices appropriate for use as GL_TRIANGLES primitives. Based on the GLU tessellator
    // documentation we can assume that the tessellator is providing triangles because it's configured with the
    // edgeFlag callback.
    NSNumber* index = (__bridge NSNumber*) vertex;
    [_interiorIndices addObject:index];

    // Accumulate outline indices appropriate for use as GL_LINES. The tessBoundaryEdge flag indicates whether or not
    // the triangle edge starting with the current vertex is a boundary edge.
    if (([_boundaryIndices count] % 2) == 1)
    {
        [_boundaryIndices addObject:index];
    }
    if (isBoundaryEdge)
    {
        [_boundaryIndices addObject:index];

        NSUInteger interiorCount = [_interiorIndices count];
        if (interiorCount > 0 && (interiorCount % 3) == 0)
        {
            [_boundaryIndices addObject:[_interiorIndices objectAtIndex:interiorCount - 3]];
        }
    }
}

- (void) tessEnd
{
    // Intentionally left blank.
}

- (void) tessCombine:(GLdouble[3])coords vertexData:(void*[4])vertexData weight:(GLdouble[4])weight outData:(void**)outData
{
    if (combineBlock)
    {
        GLushort index;
        combineBlock(coords[0], coords[1], coords[2], &index);

        NSNumber* vertexIndex = [NSNumber numberWithUnsignedShort:index];
        [vertexIndices addObject:vertexIndex];

        *outData = (__bridge void*) vertexIndex; // Associate the tessellated vertex with its index in the vertex array.
    }
    else
    {
        WWLog(@"");
    }
}

@end