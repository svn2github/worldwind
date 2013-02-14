/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import <Foundation/Foundation.h>
#import "WorldWind/Terrain/WWTerrain.h"

@class WWDrawContext;

/**
* Represents tessellated terrain associated with a WWDrawContext.
*/
@interface WWBasicTerrain : NSObject <WWTerrain>

/// @name Terrain Attributes

/// The terrain's draw context.
@property (nonatomic, readonly) WWDrawContext* dc;

/// @name Initializing Terrain

/**
* Initializes this terrain instance to the terrain associated with a specified draw context.
*
* @param dc The draw context.
*
* @return This terrain instance initialized to the terrain associated with the specified draw context.
*
* @exception NSInvalidArgumentException if the draw context is nil.
*/
- (WWBasicTerrain*) initWithDrawContext:(WWDrawContext*)dc;

@end