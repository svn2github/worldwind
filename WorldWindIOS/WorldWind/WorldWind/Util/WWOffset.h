/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.

 @version $Id$
 */

#import <Foundation/Foundation.h>

@class WWVec4;

/**
* WWOffset describes an x- and y-offset relative to a virtual rectangle of variable size, typically in screen
* coordinates. World Wind uses WWOffset to define the relationship of an image, label or other screen shape relative to
* another screen shape or screen point.
*
* An offset contains an x parameter, a y parameter, and an xUnits and yUnits indicating the independent coordinate units
* for each of these parameters. Recognized units values are as follows:
*
* - WW_PIXELS - Parameters indicate pixels relative to a virtual rectangle's lower left corner. The positive x- and
* y-axes are pointing to the right and up, respectively.
* - WW_INSET_PIXELS - Parameters indicate inset pixels relative to a virtual rectangle's upper right corner. The
* positive x- and y-axes are pointing to the left and down, respectively.
* - WW_FRACTION - Parameters indicate fractions of a virtual rectangle's width and height in the range [0,1], relative
* to its lower left corner.
*/
@interface WWOffset : NSObject

/// @name Offset Attributes

/// The offset's x parameter. May be interpreted as pixels, inset pixels or a fraction, depending on the value of
/// xUnits.
@property (nonatomic) double x;

/// The offset's y parameter. May be interpreted as pixels, inset pixels or a fraction, depending on the value of
/// yUnits.
@property (nonatomic) double y;

/// The units for this offset's x parameter. May be one of WW_PIXELS, WW_INSET_PIXELS, WW_FRACTION, or nil. When set to
/// nil the x units defaults to WW_PIXELS.
@property (nonatomic) NSString* xUnits;

/// The units for this offset's y parameter. May be one of WW_PIXELS, WW_INSET_PIXELS, WW_FRACTION, or nil. When set to
/// nil the y units defaults to WW_PIXELS.
@property (nonatomic) NSString* yUnits;

/// @name Initializing Offsets

/**
* Initializes this offset with the specified parameters and units.
*
* The parameters may be any real value. The units may be one of WW_PIXELS, WW_INSET_PIXELS, WW_FRACTION, or nil. Units
* specified as nil default to WW_PIXELS.
*
* @param x The offset's x parameter.
* @param y The offset's y parameter.
* @param xUnits The units for the offset's x parameter, may be nil.
* @param yUnits The units for the offset's y parameter, may be nil.
*
* @return This offset initialized with the specified parameters and units.
*/
- (WWOffset*) initWithX:(double)x y:(double)y xUnits:(NSString*)xUnits yUnits:(NSString*)yUnits;

/**
* Initializes this offset as pixel coordinates.
*
* The x- and y-parameters indicate pixels relative to a virtual rectangle's lower left corner. The positive x- and
* y-axes are pointing to the right and up, respectively.
*
* @param x The x-coordinate, in pixels.
* @param y The y-coordinate, in pixels.
*
* @return This offset initialized with the specified pixel coordinates.
*/
- (WWOffset*) initWithPixelsX:(double)x y:(double)y;

/**
* Initializes this offset as inset pixel coordinates.
*
* The x- and y-parameters indicate pixels relative to a virtual rectangle's upper right corner. The positive x- and
* y-axes are pointing to the left and down, respectively.
*
* @param x The x-coordinate, in inset pixels.
* @param y The y-coordinate, in inset pixels.
*
* @return This offset initialized with the specified inset pixel coordinates.
*/
- (WWOffset*) initWithInsetPixelsX:(double)x y:(double)y;

/**
* Initializes this offset as fractional coordinates.
*
* The x- and y-parameters indicate fractions of the virtual rectangle's width and height in the range [0,1], relative to
* its lower left corner.
*
* @param x The x-coordinate, in fractions.
* @param y The y-coordinate, in fractions.
*
* @return This offset initialized with the specified fractional coordinates.
*/
- (WWOffset*) initWithFractionX:(double)x y:(double)y;

/**
* Initializes this offset with the parameters and units of the specified offset.
*
* @param offset The offset who's parameters and units are assigned to this instance's.
*
* @return This offset with its parameters and units set to those of the specified offset.
*
* @exception NSInvalidArgumentException If the offset is nil.
*/
- (WWOffset*) initWithOffset:(WWOffset*)offset;

/// @name Computing the Offset in Pixels

/**
* Computes this offset's absolute x- and y-coordinates in pixels for a rectangle of variable size and scale and adds
* the coordinates to the specified result vector.
*
* The rectangle's width and height are understood to be defined in pixels.
*
* The rectangle's x- and y-scale should be either 1.0 to indicate no scaling, or any scaling value that is applied to
* the rectangle's coordinates during rendering. Scale values are specified independently from dimensions to preserve the
* offset's location relative the rectangle in its original size. For example, if an offset is configured as pixel
* coordinates of (10, 10) and a scale of 2x is applied, the absolute offset coordinates are (20, 20). Fractional
* coordinates are always interpreted relative to the rectangle's scaled dimensions. If scale of 0.0 is specified, the
* corresponding offset coordinate is also 0.0.
*
* The offset's absolute x- and y-coordinates are added to the result vector's x- and y-coordinates, respectively.
*
* @param width The rectangle's width, in pixels.
* @param height The rectangle's height, in pixels.
* @param xScale The rectangle's x-scale, or 1.0 if the rectangle has no scale.
* @param yScale The rectangle's y-scale, or 1.0 if the rectangle has no scale.
* @param result The vector to add this offset's absolute x- and y-coordinates to.
*
* @exception NSInvalidArgumentException If the result is nil.
*/
- (void) addOffsetForWidth:(double)width height:(double)height xScale:(double)xScale yScale:(double)yScale
                    result:(WWVec4*)result;

/**
* Computes this offset's absolute x- and y-coordinates in pixels for a rectangle of variable size and scale and
* subtracts the coordinates from the specified result vector.
*
* The rectangle's width and height are understood to be defined in pixels.
*
* The rectangle's x- and y-scale should be either 1.0 to indicate no scaling, or any scaling value that is applied to
* the rectangle's coordinates during rendering. Scale values are specified independently from dimensions to preserve the
* offset's location relative the rectangle in its original size. For example, if an offset is configured as pixel
* coordinates of (10, 10) and a scale of 2x is applied, the absolute offset coordinates are (20, 20). Fractional
* coordinates are always interpreted relative to the rectangle's scaled dimensions. If scale of 0.0 is specified, the
* corresponding offset coordinate is also 0.0.
*
* The offset's absolute x- and y-coordinates are subtracted from the result vector's x- and y-coordinates, respectively.
*
* @param width The rectangle's width, in pixels.
* @param height The rectangle's height, in pixels.
* @param xScale The rectangle's x-scale, or 1.0 if the rectangle has no scale.
* @param yScale The rectangle's y-scale, or 1.0 if the rectangle has no scale.
* @param result The vector to subtract this offset's absolute x- and y-coordinates from.
*
* @exception NSInvalidArgumentException If the result is nil.
*/
- (void) subtractOffsetForWidth:(double)width height:(double)height xScale:(double)xScale yScale:(double)yScale
                         result:(WWVec4*)result;
@end