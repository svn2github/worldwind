/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.

 @version $Id$
 */

#import <Foundation/Foundation.h>

@class WWMatrix;
@class WWVec4;

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
* Returns the eye point, in model coordinates.
*
* @return The eye point.
 */
- (WWVec4*) eyePoint;

@end
