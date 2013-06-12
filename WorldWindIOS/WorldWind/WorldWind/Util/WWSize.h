/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.

 @version $Id$
 */

#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>

/**
* WWSize describes a width and height relative to a virtual rectangle of variable size and its containing rectangle,
* both typically in screen coordinates. World Wind uses WWSize to define the dimensions of a 2D image, label, or other
* screen shape relative to its original dimensions and the WorldWindow's viewport dimensions.
*
* ### Parameters and Units ###
*
* WWSize contains a width-parameter, a height-parameter, and a width-units and height-units indicating the independent
* coordinate units for each of these parameters. The meaning of a parameter value depends on the corresponding unit.
* Supported unit values are as follows:
*
* - WW_PIXELS (default) - Parameters indicate absolute dimensions in pixels.
* - WW_FRACTION - Parameters indicate dimensions as fractions of the containing rectangle's dimensions, and are
* understood to be in the range [0,1], where 0 indicates a dimension of 0 and 1 indicates a dimension equal to the
* containing rectangle's  dimension. The container dimensions are specified by the containerWidth and containerHeight
* arguments passed to sizeForOriginalWidth:originalHeight:containerWidth:containerHeight:.
* - WW_ORIGINAL_SIZE - Parameters are ignored and dimensions adopt the originalWidth or originalHeight arguments passed
* to sizeForOriginalWidth:originalHeight:containerWidth:containerHeight:.
* - WW_ORIGINAL_ASPECT - Parameters are ignored and dimensions maintain the aspect ratio of the originalWidth and
* originalHeight passed to sizeForOriginalWidth:originalHeight:containerWidth:containerHeight:. This is equivalent to
* WW_ORIGINAL_SIZE when both the width-units and height-units are set to WW_ORIGINAL_ASPECT.
*
* ### Coordinate Systems ###
*
* WWSize implicitly adopts the coordinate system used by the caller. For example, a size may be used with coordinates in
* either the UIKit coordinates of a UIView or in the OpenGL coordinates of a WorldWindow. The values of any width- and
* height-parameters in pixels must be in the same coordinate system as the arguments passed to
* sizeForOriginalWidth:originalHeight:containerWidth:containerHeight:.
*/
@interface WWSize : NSObject

/// @name Attributes

/// The size's width-parameter.
///
/// May be interpreted as pixels, a fraction, or ignored, depending on the value of widthUnits.
@property (nonatomic) double width;

/// The size's height-parameter.
///
/// May be interpreted as pixels, a fraction, or ignored, depending on the value of heightUnits.
@property (nonatomic) double height;

/// The units for this size's width-parameter.
///
/// May be one of WW_PIXELS, WW_FRACTION, WW_ORIGINAL_SIZE, WW_ORIGINAL_ASPECT, or nil. When set to nil the widthUnits
/// defaults to WW_PIXELS.
@property (nonatomic) NSString* widthUnits;

/// The units for this size's height-parameter.
///
/// May be one of WW_PIXELS, WW_FRACTION, WW_ORIGINAL_SIZE, WW_ORIGINAL_ASPECT, or nil. When set to nil the heightUnits
/// defaults to WW_PIXELS.
@property (nonatomic) NSString* heightUnits;

/// @name Initializing Sizes

/**
* Initializes this size with the specified parameters and units.
*
* The parameters may be any real value. The units may be one of WW_PIXELS, WW_FRACTION, WW_ORIGINAL_SIZE,
* WW_ORIGINAL_ASPECT, or nil. Units specified as nil default to WW_PIXELS.
*
* @param width The size's width-parameter.
* @param height The size's height-parameter.
* @param widthUnits The units for the size's width-parameter. May be nil.
* @param heightUnits The units for the size's height-parameter. May be nil.
*
* @return This size initialized with the specified parameters an units.
*/
- (WWSize*) initWithWidth:(double)width
                   height:(double)height
               widthUnits:(NSString*)widthUnits
              heightUnits:(NSString*)heightUnits;

/**
* Initializes this size as a dimension in pixels.
*
* The width- and height-parameters indicate absolute dimensions in pixels.
*
* @param width The width, in pixels.
* @param height The height, in pixels.
*
* @return This size initialized with the specified pixel dimensions.
*/
- (WWSize*) initWithPixelsWidth:(double)width height:(double)height;

/**
* Initializes this size as a fractional dimension of the size's container.
*
* The width- and height-parameters indicate dimensions as fractions of the containing rectangle's dimensions, and are
* understood to be in the range [0,1], where 0 indicates a dimension of 0 and 1 indicates a dimension equal to the
* containing rectangle's dimension. The container dimensions are specified by the containerWidth and containerHeight
* arguments passed to sizeForOriginalWidth:originalHeight:containerWidth:containerHeight:.
*
* @param width The width-parameter, as a fraction in the range [0,1].
* @param height The height-parameter, as a fraction in the range [0,1].
*
* @return This size initialized with the specified fractional dimensions.
*/
- (WWSize*) initWithFractionWidth:(double)width height:(double)height;

/**
* Initializes this size to adopt the original size of a specified rectangle.
*
* The width- and height-parameters are ignored and dimensions adopt the originalWidth or originalHeight arguments passed
* to sizeForOriginalWidth:originalHeight:containerWidth:containerHeight:.
*
* @return This size initialized to adopt a specified original size.
*/
- (WWSize*) initWithOriginalSize;

/**
* Initializes this size with the parameters and units of the specified size.
*
* @param size The size who's parameters and units are assigned to this instance's.
*
* @return This size with its parameters and units set to those of the specified size.
*
* @exception NSInvalidArgumentException if the size is nil.
*/
- (WWSize*) initWithSize:(WWSize*)size;

/// @name Computing the Absolute Size

/**
* Computes this size's absolute dimensions in pixels for a rectangle of a specified size its containing rectangle, both
* in pixels.
*
* The returned size is in pixels, and is defined in the coordinate system used by the caller.
*
* @param originalWidth The rectangle's width, in pixels.
* @param originalHeight The rectangle's height, in pixels.
* @param containerWidth The containing rectangle's width, in pixels.
* @param containerHeight The containing rectangle's height, in pixels.
*
* @return The size's absolute width and height in pixels.
*/
- (CGSize) sizeForOriginalWidth:(double)originalWidth
                 originalHeight:(double)originalHeight
                 containerWidth:(double)containerWidth
                containerHeight:(double)containerHeight;

@end