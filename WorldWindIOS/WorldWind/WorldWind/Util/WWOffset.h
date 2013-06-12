/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.

 @version $Id$
 */

#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>

/**
* WWOffset describes an x- and y-offset relative to a virtual rectangle of variable size, typically in screen
* coordinates. World Wind uses WWOffset to define the location of a 2D image, label or other screen shape relative to
* a reference location.
*
* ### Parameters and Units ###
*
* WWOffset contains an x-parameter, a y-parameter, and an x-units and y-units indicating the independent coordinate
* units for each of these parameters. The meaning of a parameter value depends on the corresponding unit. Supported unit
* values are as follows:
*
* - WW_PIXELS (default) - Parameters indicate pixels relative to the virtual rectangle's origin.
* - WW_INSET_PIXELS - Parameters indicate inset pixels relative to the virtual rectangle's corner diagonal to its
* origin.
* - WW_FRACTION - Parameters indicate fractions of the virtual rectangle's width and height in the range [0,1], where
* 0 indicates the rectangle's origin and 1 indicates the corner opposite its origin.
*
* ### Coordinate Systems ###
*
* WWOffset implicitly adopts the coordinate system used by the caller. For example, an offset may be used with
* coordinates in either the UIKit coordinates of a UIView or in the OpenGL coordinates of a WorldWindow. The values of
* any x- and y-parameters in pixels or inset pixels must be in the same coordinate system as the arguments passed to
* offsetForWidth:height:.
*/
@interface WWOffset : NSObject

/// @name Attributes

/// The offset's x-parameter.
///
/// May be interpreted as pixels, inset pixels, or a fraction, depending on the value of xUnits.
@property (nonatomic) double x;

/// The offset's y parameter.
///
/// May be interpreted as pixels, inset pixels, or a fraction, depending on the value of yUnits.
@property (nonatomic) double y;

/// The units for this offset's x-parameter.
///
/// May be one of WW_PIXELS, WW_INSET_PIXELS, WW_FRACTION, or nil. When set to nil the xUnits defaults to WW_PIXELS.
@property (nonatomic) NSString* xUnits;

/// The units for this offset's y-parameter.
///
/// May be one of WW_PIXELS, WW_INSET_PIXELS, WW_FRACTION, or nil. When set to nil yUnits defaults to WW_PIXELS.
@property (nonatomic) NSString* yUnits;

/// @name Initializing Offsets

/**
* Initializes this offset with the specified parameters and units.
*
* The parameters may be any real value. The units may be one of WW_PIXELS, WW_INSET_PIXELS, WW_FRACTION, or nil. Units
* specified as nil default to WW_PIXELS.
*
* @param x The offset's x-parameter.
* @param y The offset's y-parameter.
* @param xUnits The units for the offset's x-parameter, may be nil.
* @param yUnits The units for the offset's y-parameter, may be nil.
*
* @return This offset initialized with the specified parameters and units.
*/
- (WWOffset*) initWithX:(double)x y:(double)y xUnits:(NSString*)xUnits yUnits:(NSString*)yUnits;

/**
* Initializes this offset as pixel coordinates.
*
* The x- and y-parameters indicate pixels relative to the virtual rectangle's origin.
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
* The x- and y-parameters indicate inset pixels relative to the virtual rectangle's corner diagonal to its origin.
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
* The x- and y-parameters indicate fractions of the virtual rectangle's width and height in the range [0,1], where 0
* indicates the rectangle's origin and 1 indicates the corner opposite its origin.
*
* @param x The x-coordinate, as a fraction in the range [0,1].
* @param y The y-coordinate, as a fraction in the range [0,1].
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

/// @name Computing the Absolute Offset

/**
* Computes this offset's absolute x- and y-coordinates in pixels for a rectangle of a specified size in pixels.
*
* The returned offset is in pixels relative to the rectangle's origin, and is defined in the coordinate system used by
* the caller.
*
* @param width The rectangle's width, in pixels.
* @param height The rectangle's height, in pixels.
*
* @return The offset's absolute x- and y-coordinates in pixels relative to the rectangle's origin.
*/
- (CGPoint) offsetForWidth:(double)width height:(double)height;

@end