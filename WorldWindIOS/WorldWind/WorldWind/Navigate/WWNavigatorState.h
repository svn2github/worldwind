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
