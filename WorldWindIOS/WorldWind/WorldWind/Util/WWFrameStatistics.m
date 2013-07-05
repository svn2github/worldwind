/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.

 @version $Id$
 */

#import "WorldWind/Util/WWFrameStatistics.h"

@implementation WWFrameStatistics

- (WWFrameStatistics*) init
{
    self = [super init];

    return self;
}

- (void) beginFrame
{
    _frameTime = [NSDate timeIntervalSinceReferenceDate];
    _tessellationTime = 0;
    _layerRenderingTime = 0;
    _orderedRenderingTime = 0;
    _displayRenderbufferTime = 0;
    _terrainTileCount = 0;
    _imageTileCount = 0;
    _renderedTileCount = 0;
    _tileUpdateCount = 0;
    _textureLoadCount = 0;
    _vboLoadCount = 0;
    ++frameCount;
}

- (void) endFrame
{
    NSTimeInterval now = [NSDate timeIntervalSinceReferenceDate];
    _frameTime = now - _frameTime;
    frameTimeCumulative += _frameTime;

    if (now - frameTimeBase > 2)
    {
        _frameTimeAverage = frameTimeCumulative / frameCount;
        _frameRateAverage = frameCount / (now - frameTimeBase);
        frameTimeBase = now;
        frameTimeCumulative = 0;
        frameCount = 0;
    }
}

- (void) incrementTerrainTileCount:(NSUInteger)amount
{
    _terrainTileCount += amount;
}

- (void) incrementImageTileCount:(NSUInteger)amount
{
    _imageTileCount += amount;
}

- (void) incrementRenderedTileCount:(NSUInteger)amount
{
    _renderedTileCount += amount;
}

- (void) incrementTileUpdateCount:(NSUInteger)amount
{
    _tileUpdateCount += amount;
}

- (void) incrementTextureLoadCount:(NSUInteger)amount
{
    _textureLoadCount += amount;
}

- (void) incrementVboLoadCount:(NSUInteger)amount
{
    _vboLoadCount += amount;
}

@end