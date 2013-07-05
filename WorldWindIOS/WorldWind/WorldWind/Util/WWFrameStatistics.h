/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.

 @version $Id$
 */

#import <Foundation/Foundation.h>

/**
* WWFrameStatistics indicates per-frame measurements and cumulative frame performance statistics associated with a
* WorldWindView. Per-frame measurements include time intervals indicating how long the most recent frame took to
* complete and counts indicating the number of performance-sensitive objects and operations during the most recent
* frame. Cumulative statistics indicate the average frame time and average frame rate based on time interval
* measurements from the most recent frame as well frames displayed during the most recent two seconds.
*/
@interface WWFrameStatistics : NSObject
{
@protected
    NSTimeInterval frameTimeBase;
    NSTimeInterval frameTimeCumulative;
    NSUInteger frameCount;
}

/// @name Per-Frame Measurements

/// The time taken to display the most recent frame, in seconds.
///
/// The frame time is measured as the time interval between beginFrame and endFrame, which the WorldWindView calls
/// immediately before and after rendering a frame, respectively.
@property (nonatomic) NSTimeInterval frameTime;

/// The portion of the frameTime taken to tessellate terrain in the most recent frame, in seconds.
///
/// Tessellation time is measured as time spent in [WWTessellator tessellate:].
@property (nonatomic) NSTimeInterval tessellationTime;

/// The portion of the frameTime taken to render all layers in the most recent frame, in seconds.
///
/// Layer rendering time is measured as time spent calling [WWLayer render:] for each layer in the WWSceneController's
/// layer list.
@property (nonatomic) NSTimeInterval layerRenderingTime;

/// The portion of the frameTime taken to render all ordered renderables in the most recent frame, in seconds.
///
/// Ordered rendering time is measured as time spent sorting and rendering the WWSceneController's list of
/// WWOrderedRenderable objects.
@property (nonatomic) NSTimeInterval orderedRenderingTime;

/// The portion of the frameTime taken to display the renderbuffer's contents on screen in the most recent frame,
/// in seconds.
///
/// Display renderbuffer time is measured as time spend in `EAGLContext presentRenderBuffer:`.
@property (nonatomic) NSTimeInterval displayRenderbufferTime;

/// The number of terrain tiles in the most recent frame.
@property (nonatomic) NSUInteger terrainTileCount;

/// The number of image tiles in the most recent frame.
@property (nonatomic) NSUInteger imageTileCount;

/// The number of rendered tiles in the most recent frame.
@property (nonatomic) NSUInteger renderedTileCount;

/// The number of tile updates performed in the most recent frame.
///
/// Calls to [WWTile update:] that perform work to update the tile's properties increment this count.
@property (nonatomic) NSUInteger tileUpdateCount;

/// The number of OpenGL texture data loads performed in the most recent frame.
///
/// Calls to [WWTexture bind:] that load texture data to OpenGL increment this count.
@property (nonatomic) NSUInteger textureLoadCount;

/// The number of OpenGL vertex buffer object loads performed in the most recent frame.
///
/// Terrain rendering operations and shape rendering operations that load vertex buffer data to OpenGL increment this
/// count.
@property (nonatomic) NSUInteger vboLoadCount;

/// @name Cumulative Performance Statistics

/// The average frame time over the most recent two seconds.
@property (nonatomic) NSTimeInterval frameTimeAverage;

/// The average number of frames per second over the most recent two seconds.
@property (nonatomic) double frameRateAverage;

/// @name Initializing Frame Statistics

/**
* Initializes this frame statistics with default values. All measurements are initialized to zero.
*
* @return This frame statistics initialized with default values.
*/
- (WWFrameStatistics*) init;

/// @name Indicating Frame Boundaries

/**
* Indicates the beginning of a new frame.
*
* This frame statistics sets all per-frame measurements to zero and marks the current time. The result of this method is
* undefined if beginFrame is called without a corresponding call to endFrame.
*/
- (void) beginFrame;

/**
* Indicates the end of the frame that began with a call to beginFrame.
*
* This frame statistics updates frameTime with the interval since the time marked in beginFrame, and potentially updates
* the frameTimeAverage and frameRateAverage. The result of this method is undefined if endFrame is called without a
* corresponding call to beginFrame.
*/
- (void) endFrame;

/// @name Operations on Per-Frame Measurements

/**
* Adds a specified unsigned integer value to terrainTileCount.
*
* @param amount The amount to add.
*/
- (void) incrementTerrainTileCount:(NSUInteger)amount;

/**
* Adds a specified unsigned integer value to imageTileCount.
*
* @param amount The amount to add.
*/
- (void) incrementImageTileCount:(NSUInteger)amount;

/**
* Adds a specified unsigned integer value to renderedTileCount.
*
* @param amount The amount to add.
*/
- (void) incrementRenderedTileCount:(NSUInteger)amount;

/**
* Adds a specified unsigned integer value to tileUpdateCount.
*
* @param amount The amount to add.
*/
- (void) incrementTileUpdateCount:(NSUInteger)amount;

/**
* Adds a specified unsigned integer value to textureLoadCount.
*
* @param amount The amount to add.
*/
- (void) incrementTextureLoadCount:(NSUInteger)amount;

/**
* Adds a specified unsigned integer value to vboLoadCount.
*
* @param amount The amount to add.
*/
- (void) incrementVboLoadCount:(NSUInteger)amount;

@end