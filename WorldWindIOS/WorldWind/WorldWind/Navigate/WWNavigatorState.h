/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.

 @version $Id$
 */

#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>

@class WWFrustum;
@class WWLine;
@class WWMatrix;
@class WWVec4;

/**
* Provides viewing information computed by the navigator at a single point in time.
*/
@protocol WWNavigatorState

/// @name Navigator State Attributes

/**
* Returns the navigator's modelview matrix.
*
* The modelview matrix maps points in model coordinates into eye coordinates. Eye coordinates occupy the same space as
* model coordinates but place the origin at the eyePoint, the z-axis coming out of the screen, the y-axis pointing to
* the top of the screen, and the x-axis pointing to the right side of the screen.
*
* @return The modelview matrix.
*/
- (WWMatrix*) modelview;

/**
* Returns the navigator's projection matrix.
*
* The projection matrix maps points in eye coordinates into clip coordinates. Clip coordinates are represented by a cube
* centered at the origin and extending from negative one to positive one for each of the x-, y- and z-axes.
*
* @return The projection matrix.
*/
- (WWMatrix*) projection;

/**
* Returns the navigator's combined modelview - projection matrix.
*
* This matrix is computed by multiplying the projection matrix by the modelview matrix, in that order. The
* modelview - projection matrix maps points in model coordinates into clip coordinates. See the documentation for the
* individual matrices for an explanation of these coordinate systems.
*
* @return The combined modelview - projection matrix.
*/
- (WWMatrix*) modelviewProjection;

/**
* Returns the navigator's viewport rectangle in OpenGL screen coordinates.
*
* The viewport is in the OpenGL screen coordinate system of the WorldWindView, with its origin in the bottom-left corner
* and axes that extend up and to the right from the origin point.
*
* The viewport rectangle defines the location of the drawing region on screen as well as its resolution in pixels. This
* rectangle's lower left corner maps to (-1, -1, -1) in clip coordinates, and its upper right corner maps to (1, 1, -1).
* The viewport typically has coordinates (0, 0, width, height), where width and height are the screen width and height
* in pixels, respectively. Note that the viewport origin is in the lower left corner.
*
* @return The viewport rectangle.
*/
- (CGRect) viewport;

/**
* Returns the navigator's eye point in model coordinates.
*
* The eye point is the point the viewer is looking from and maps to the center of the screen.
*
* @return The eye point.
*/
- (WWVec4*) eyePoint;

/**
* Returns the navigator's forward vector in model coordinates.
*
* The forward vector is the direction the viewer is looking and maps to a vector going into the screen.
*
* @return The forward vector, in model coordinates.
*/
- (WWVec4*) forward;

/**
* Returns the navigator's forward-ray in model coordinates.
*
* The forward-ray originates from the navigator's eyePoint and is directed along its forward vector. This ray is
* effectively going into the screen from the screen's center.
*
* @return The forward-ray.
*/
- (WWLine*) forwardRay;

/**
* Returns the navigator's frustum in model coordinates.
*
* The frustum originates at the eyePoint and extends outward along the forward vector. The navigator's near distance and
* far distance identify the minimum and maximum distance, respectively, at which an object in the scene is visible.
*
* @return The frustum in model coordinates.
*/
- (WWFrustum*) frustumInModelCoordinates;

/// @name Operations on Navigator State

/**
* Transforms the specified modelPoint from model coordinates to OpenGL screen coordinates.
*
* The resultant screen point is in the OpenGL screen coordinate system of the WorldWindView, with its origin in the
* bottom-left corner and axes that extend up and to the right from the origin point.
*
* This stores the transformed point in the screenPoint parameter, and returns YES or NO to indicate whether or not the
* transformation is successful. This returns NO if this navigator state's modelview or projection matrices are
* malformed, or if the modelPoint is clipped by the near clipping plane or the far clipping plane.
*
* This performs the same computations as the OpenGL vertex transformation pipeline, but is not guaranteed to result in
* the exact same floating point values.
*
* @param modelPoint The point to transform, in model coordinates.
* @param screenPoint The transformed result, in OpenGL screen coordinates.
*
* @return YES if the transformation is successful, otherwise NO.
*
* @exception NSInvalidArgumentException If the modelPoint or the screenPoint are nil.
*/
- (BOOL) project:(WWVec4*)modelPoint result:(WWVec4*)screenPoint;

/**
* Transforms the specified modelPoint from model coordinates to OpenGL screen coordinates, applying an offset to the
* modelPoint's projected depth value.
*
* The resultant screen point is in the OpenGL screen coordinate system of the WorldWindView, with its origin in the
* bottom-left corner and axes that extend up and to the right from the origin point.
*
* This stores the transformed point in the screenPoint parameter, and returns YES or NO to indicate whether or not the
* transformation is successful. This returns NO if this navigator state's modelview or projection matrices are
* malformed, or if the modelPoint is clipped by the near clipping plane or the far clipping plane, ignoring the depth
* offset.
*
* The depth offset may be any real number and is typically used to move the screenPoint slightly closer to the user's
* eye in order to give it visual priority over nearby points. An offset of zero has no effect. An offset less than zero
* brings the screenPoint closer to the eye, while an offset greater than zero pushes the screenPoint away from the eye.
*
* This performs the same computations as the OpenGL vertex transformation pipeline, but is not guaranteed to result in
* the exact same floating point values. Applying a non-zero depth offset has no effect on on whether the modelPoint is
* clipped by this method or by OpenGL. Clipping is performed on the original modelPoint ignoring the depth offset, and
* the final depth value after applying the offset is clamped to the range [0,1].
*
* @param modelPoint The point to transform, in model coordinates.
* @param screenPoint The transformed result, in OpenGL screen coordinates.
* @param offset The amount of offset to apply.
*
* @return YES if the transformation is successful, otherwise NO.
*
* @exception NSInvalidArgumentException If the modelPoint or the screenPoint are nil.
*/
- (BOOL) project:(WWVec4*)modelPoint result:(WWVec4*)screenPoint depthOffset:(double)depthOffset;

/**
* Transforms the specified screen point from OpenGL screen coordinates to model coordinates.
*
* The screen point is understood to be in the OpenGL screen coordinate system of the WorldWindView, with its origin in
* the bottom-left corner and axes that extend up and to the right from the origin point.
*
* This stores the transformed point in the modelPoint parameter, and returns YES or NO to indicate whether the
* transformation is successful. This returns NO if this navigator state's modelview or projection matrices are
* malformed, or if the screenPoint is clipped by the near clipping plane or the far clipping plane.
*
* This performs the same computations as the OpenGL vertex transformation pipeline, but is not guaranteed to result in
* the exact same floating point values.
*
* @param screenPoint The point to transform, in OpenGL screen coordinates.
* @param modelPoint The transformed result, in model coordinates.
*
* @return YES if the transformation is successful, otherwise NO.
*
* @exception NSInvalidArgumentException If the screenPoint or the modelPoint are nil.
*/
- (BOOL) unProject:(WWVec4*)screenPoint result:(WWVec4*)modelPoint;

/**
* Converts an OpenGL screen point to UIKit coordinates.
*
* The specified point is understood to be in the OpenGL screen coordinate of the WorldWindView, with its origin in the
* bottom-left corner and axes that extend up and to the right from the origin point.
*
* The returned point is in the UIKit coordinate system of the WorldWindView, with its origin in the top-left corner and
* axes that extend down and to the right from the origin point. See the section titled View Geometry and Coordinate
* Systems in the [View Programming Guide for iOS](http://developer.apple.com/library/ios/#documentation/WindowsViews/Conceptual/ViewPG_iPhoneOS/WindowsandViews/WindowsandViews.html).
*
* @param point The OpenGL screen point.
*
* @return The OpenGL screen point converted to UIKit coordinates.
*
* @exception NSInvalidArgumentException If the screenPoint is nil.
*/
- (CGPoint) convertPointToView:(WWVec4*)screenPoint;

/**
* Converts a UIKit screen point to OpenGL screen coordinates.
*
* The specified point is understood to be in the UIKit coordinate system of the WorldWindView, with its origin in the
* top-left corner and axes that extend down and to the right from the origin point. See the section titled View Geometry
* and Coordinate Systems in the [View Programming Guide for iOS](http://developer.apple.com/library/ios/#documentation/WindowsViews/Conceptual/ViewPG_iPhoneOS/WindowsandViews/WindowsandViews.html).
*
* The returned point is in the OpenGL screen coordinate system of the WorldWindView, with its origin in the bottom-left
* corner and axes that extend up and to the right from the origin point.
*
* @param point The UIKit screen point.
*
* @return The UIKit screen point converted to OpenGL screen coordinates.
*/
- (WWVec4*) convertPointToViewport:(CGPoint)point;

/**
* Computes a ray originating at the navigator's eyePoint and extending through the specified point in UIKit screen
* coordinates.
*
* The screen point is understood to be in the UIKit coordinate system of the WorldWindView, with its origin in the
* top-left corner and axes that extend down and to the right from the origin point. See the section titled View Geometry
* and Coordinate Systems in the [View Programming Guide for iOS](http://developer.apple.com/library/ios/#documentation/WindowsViews/Conceptual/ViewPG_iPhoneOS/WindowsandViews/WindowsandViews.html).
*
* The results of this method are undefined if the specified point is outside of the WorldWindView's bounds.
*
* @param point The UIKit screen coordinate to compute a ray for.
*
* @return The ray through the specified screen point.
*/
- (WWLine*) rayFromScreenPoint:(CGPoint)point;

/**
* Computes the approximate size of a pixel at a specified distance from the navigator state's eyePoint.
*
* This method assumes the model of a screen composed of rectangular pixels, where pixel coordinates demote infinitely
* thin space between pixels. The units of the returned size are in model coordinates per pixel (usually meters per
* pixel). This returns 0 if the specified distance is zero. The returned size is undefined if the distance is less than
* zero.
*
* @param distance The distance from the eye point at which to determine pixel size, in model coordinates.
*
* @return The approximate pixel size at the specified distance from the eye point, in model coordinates per pixel.
*/
- (double) pixelSizeAtDistance:(double)distance;

/**
* Indicates the number of degrees clockwise from north to which the view is directed.
*
* @return The number of degrees of heading clockwise relative to north.
*/
- (double) heading;

/**
* The number of degrees the globe is tilted relative to its surface being parallel to the screen. Values are
* typically in the range 0 to 90 but may vary from that depending on the navigator in use.
*
* @return The number of degrees of tilt.
*/
- (double) tilt;

@end