/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import <Foundation/Foundation.h>

@class WWDrawContext;

/**
* A protocol defining methods provided by all shapes consisting of both an interior and an outline.
*/
@protocol WWOutlinedShape

/**
* Indicates whether the shape should draw its outline.
*
* @param dc The current draw context.
*
* @return YES if the shape should draw its outline, otherwise NO.
*/
- (BOOL) isDrawOutline:(WWDrawContext*)dc;

/**
* Indicates whether the shape should draw its interior.
*
* @param dc The current draw context.
*
* @return YES if the shape should draw its interior, otherwise NO.
*/
- (BOOL) isDrawInterior:(WWDrawContext*)dc;

/**
* Draws the shape's outline.
*
* @param dc The current draw context.
*/
- (void) drawOutline:(WWDrawContext*)dc;

/**
* Draws the shape's interior.
*
* @param dc The current draw context.
*/
- (void) drawInterior:(WWDrawContext*)dc;

/**
* Indicates whether OpenGL polygon offset should be applied.
*
* @param dc The current draw context.
*
* @return YES if polygon offset should be applied, otherwise NO.
*/
- (BOOL) isEnableDepthOffset:(WWDrawContext*)dc;

/**
* Indicates the OpenGL polygon offset depth factor.
*
* @param dc The current draw context.
*
* @return The offset depth factor.
*/
- (float) depthOffsetFactor:(WWDrawContext*)dc;

/**
* Indicates the OpenGL polygon offset depth units.
*
* @param dc The current draw context.
*
* @return The offset depth units.
*/
- (float) depthOffsetUnits:(WWDrawContext*)dc;

@end