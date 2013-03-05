/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.

 @version $Id$
 */

#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>

@class WWMatrix;
@class WWVec4;
@class WWFrustum;

/**
* Provides viewing information computed by the navigator.
*/
@protocol WWNavigatorState

/// @name Attributes

/**
* Returns the modelview matrix.
*
* @return The modelview matrix.
*/
- (WWMatrix*) modelview;

/**
* Returns the projection matrix.
*
* @return The projection matrix.
*/
- (WWMatrix*) projection;

/**
* Returns the concatenation of the modelview and projection matrices.
*
* @return The concatenation of the modelview and projection matrices.
*/
- (WWMatrix*) modelviewProjection;

/**
* Returns the viewport rectangle in screen coordinates.
*
* @return The viewport rectangle in screen coordinates.
*/
- (CGRect) viewport;

/**
* Returns the eye point, in model coordinates.
*
* @return The eye point.
*/
- (WWVec4*) eyePoint;

/**
* Returns the frustum.
*
* @return The frustum.
*/
- (WWFrustum*) frustum;

/**
* Returns the frustum in model coordinates.
*
* @return The frustum in model coordinates.
*/
- (WWFrustum*) frustumInModelCoordinates;

/// @name Operations on Navigator State

/**
* Transforms the specified modelPoint from model coordinates to screen coordinates.
*
* This stores the transformed point in the screenPoint parameter, and returns YES or NO to indicate whether or not the
* transformation is successful. This returns NO if the modelview or projection matrices are malformed, or if the
* specified modelPoint is behind the eye.
*
* This performs the same computations as the OpenGL vertex transformation pipeline, but is not guaranteed to result in
* the exact same floating point values.
*
* @param modelPoint The point to transform, in model coordinates.
* @param screenPoint The transformed result, in screen coordinates.
*
* @return YES if the transformation is successful, otherwise NO.
*
* @exception NSInvalidArgumentException If the modelPoint or the screenPoint are nil.
*/
- (BOOL) project:(WWVec4*)modelPoint result:(WWVec4*)screenPoint;

/**
* Transforms the specified screenPoint from screen coordinates to model coordinates.
*
* This stores the transformed point in the modelPoint parameter, and returns YES or NO to indicate whether the
* transformation is successful. This returns NO if the modelview or projection matrices are malformed, or if the
* specified screenPoint's Z coordinate is less than zero.
*
* This performs the same computations as the OpenGL vertex transformation pipeline, but is not guaranteed to result in
* the exact same floating point values.
*
* @param screenPoint The point to transform, in screen coordinates.
* @param modelPoint The transformed result, in model coordinates.
*
* @return YES if the transformation is successful, otherwise NO.
*
* @exception NSInvalidArgumentException If the screenPoint or the modelPoint are nil.
*/
- (BOOL) unProject:(WWVec4*)screenPoint result:(WWVec4*)modelPoint;

/**
* Indicates the approximate size of a pixel, in model coordinates, at a specified distance from the current eye point.
*
* This returns 0 if the specified distance is zero. The return value of this method is undefined if the distance is less
* than zero.
*
* @param distance The distance from the eye point at which to determine pixel size.
*
* @return The approximate pixel size, in model coordinates, at the specified distance from the eye point.
*/
- (double) pixelSizeAtDistance:(double)distance;

@end