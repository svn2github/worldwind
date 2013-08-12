/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import <Foundation/Foundation.h>
#import "WorldWind/Util/WWWMSDimensionIterator.h"

/**
* Represents a WMS layer dimension and provides a means for iterating over the dimensions values.
*/
@interface WWWMSDimension : NSObject


/// @name Dimension Attributes

/// The dimension's name, as specified in the layer's capabilities.
@property (nonatomic) NSString* name;

/// The dimension's display name, as specified in the layer's capabilities.
@property (nonatomic) NSString* units;

/// The dimension's units symbol, as specified in the layer's capabilities.
@property (nonatomic) NSString* unitsSymbol;

/// The dimension's default value, as specified in the layer's capabilities.
@property (nonatomic) NSString* defaultValue;

/// Indicates whether multiple values of the dimension can be queried from the server in a single GetMap request,
// as specified in the layer's capabilities.
@property (nonatomic) BOOL multipleValues;

/// Indicates whether the server uses the nearest value to a requested dimension of the exact value doesn't exist,
// as specified in the layer's capabilities.
@property (nonatomic) BOOL nearestValue;

/// Indicates for temporal extents whether "CURRENT" is a valid value to pass as the TIME parameter in GetMap
// requests, as specified in the layer's capabilities.
@property (nonatomic) BOOL current;

/**
* Returns the string to use when specifying this dimension in a WMS GetMap request.
*
* @return The GetMap parameter name.
*/
- (NSString*)getMapParameterName;

/// Indicates the number of individual values in this dimension. The values themselves are returned by an iterator
// produce by instances of this class.
- (int) count;

/// @name Iterating Over Dimensions

/**
* Returns an iterator over all the dimensions specified by the dimension string.
*
* @return The iterator.
*/
- (id <WWWMSDimensionIterator>) iterator;

@end