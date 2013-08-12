/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import <Foundation/Foundation.h>
#import "WWWMSDimension.h"

/**
* Represents WMS time Dimension entities and provides a mechanism for iterating over the dimensions.
*/
@interface WWWMSTimeDimension : WWWMSDimension
{
    NSMutableArray* values; // the strings for all the implied times of this dimension instance. Computed when needed.
}

/// @name Time Dimension Attributes

/// The time extents as defined in the layer's WMS capabilities.
@property (nonatomic, readonly) NSMutableArray* extents;

/// @name Initializing Time Dimensions

/**
* Initializes a time dimension from a specified WMS layer dimension string.
*
* @param dimensionString The dimension string as read from a layer's WMS capabilities.
*
* @return The initialized dimension.
*
* @exception NSInvalidArgumentException if the specified dimension string is nil.
*/
- (WWWMSTimeDimension*) initWithDimensionString:(NSString*)dimensionString;

//- (void) testParsing;

@end