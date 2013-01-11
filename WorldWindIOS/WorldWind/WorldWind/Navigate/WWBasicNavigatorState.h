/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.

 @version $Id$
 */

#import <Foundation/Foundation.h>
#import "WorldWind/Navigate/WWNavigatorState.h"

@class WWMatrix;
@class WWVec4;

/**
* Provides an implementation of the WWNavigatorState protocol.
*/
@interface WWBasicNavigatorState : NSObject<WWNavigatorState>

/// @name Attributes

/// The modelview matrix.
@property (nonatomic, readonly) WWMatrix* modelview;

/// The project matrix.
@property (nonatomic, readonly) WWMatrix* projection;

/// The concatenation of the modelview and projection matrices.
@property (nonatomic, readonly) WWMatrix* modelviewProjection;

/// The eye point, in model coordinates.
@property (nonatomic, readonly) WWVec4* eyePoint;

/// @name Initializing Navigator State

/**
* Initialize this navigator state.
*
* @param modelviewMatrix The modelview matrix.
* @param projection The projection matrix.
*
* @return The initialized instance.
*
* @exception NSInvalidArgumentException if either the modelview or projection matrices are nil.
*/
- (WWBasicNavigatorState*) initWithModelview:(WWMatrix*)modelviewMatrix projection:(WWMatrix*)projectionMatrix;

@end
