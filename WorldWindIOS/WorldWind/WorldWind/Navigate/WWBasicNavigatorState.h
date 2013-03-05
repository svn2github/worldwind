/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.

 @version $Id$
 */

#import <Foundation/Foundation.h>
#import "WorldWind/Navigate/WWNavigatorState.h"

@class WWMatrix;
@class WWVec4;
@class WWFrustum;

/**
* Provides an implementation of the WWNavigatorState protocol.
*/
@interface WWBasicNavigatorState : NSObject<WWNavigatorState>
{
@protected
    // The inverses of the modelview, projection, and concatenated modelview-projection matrices.
    WWMatrix* modelviewInv;
    WWMatrix* projectionInv;
    WWMatrix* modelviewProjectionInv;
    // Constants computed during initialization and used in pixelSizeAtDistance.
    double pixelSizeScale;
    double pixelSizeOffset;
}

/// @name Navigator State Attributes

/// The modelview matrix.
@property (nonatomic, readonly) WWMatrix* modelview;

/// The projection matrix.
@property (nonatomic, readonly) WWMatrix* projection;

/// The concatenation of the modelview and projection matrices.
@property (nonatomic, readonly) WWMatrix* modelviewProjection;

/// The viewport rectangle, in screen coordinates.
@property (nonatomic, readonly) CGRect viewport;

/// The eye point, in model coordinates.
@property (nonatomic, readonly) WWVec4* eyePoint;

// The view frustum, in model coordinates.
@property (nonatomic, readonly) WWFrustum* frustumInModelCoordinates;

/// @name Initializing Navigator State

/**
* Initialize this navigator state.
*
* @param modelviewMatrix The modelview matrix.
* @param projectionMatrix The projection matrix.
* @param viewport The viewport rectangle, in screen coordinates.
*
* @return The initialized instance.
*
* @exception NSInvalidArgumentException If either the modelview or projection matrices are nil.
*/
- (WWBasicNavigatorState*) initWithModelview:(WWMatrix*)modelviewMatrix
                                  projection:(WWMatrix*)projectionMatrix
                                    viewport:(CGRect)viewport;

@end