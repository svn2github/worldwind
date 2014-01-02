/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import "PathFollower.h"
#import "WorldWind/Geometry/WWPosition.h"
#import "WorldWind/Layer/WWLayer.h"
#import "WorldWind/Layer/WWLayerList.h"
#import "WorldWind/Layer/WWRenderableLayer.h"
#import "WorldWind/Navigate/WWLookAtNavigator.h"
#import "WorldWind/Navigate/WWFirstPersonNavigator.h"
#import "WorldWind/Render/WWSceneController.h"
#import "WorldWind/Shapes/WWPath.h"
#import "WorldWind/Shapes/WWShapeAttributes.h"
#import "WorldWind/Shapes/WWSphere.h"
#import "WorldWind/Terrain/WWGlobe.h"
#import "WorldWind/Util/WWColor.h"
#import "WorldWind/Util/WWMath.h"
#import "WorldWind/WorldWindConstants.h"
#import "WorldWind/WorldWindView.h"
#import "WorldWind/WWLog.h"

@implementation PathFollower

- (PathFollower*) initWithPath:(WWPath*)path speed:(double)speed view:(WorldWindView*)view
{
    self = [super init];

    _path = path;
    _speed = speed;
    _wwv = view;

    WWPosition* firstPosition = [[_path positions] objectAtIndex:0];
    WWPosition* secondPosition = [[_path positions] objectAtIndex:1];
    currentPosition = [[WWPosition alloc] initWithPosition:firstPosition];
    currentHeading = [WWPosition rhumbAzimuth:firstPosition endLocation:secondPosition];

    WWShapeAttributes* attrs = [[WWShapeAttributes alloc] init];
    [attrs setInteriorColor:[[WWColor alloc] initWithR:.24 g:.47 b:.99 a:1]];
    marker = [[WWSphere alloc] initWithPosition:currentPosition radiusInPixels:7];
    [marker setAttributes:attrs];

    layer = [[WWRenderableLayer alloc] init];
    [layer setEnabled:NO];
    [layer setDisplayName:@"Path Position"];
    [layer addRenderable:marker];
    [[[_wwv sceneController] layers] addLayer:layer];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(navigatorDidChange)
                                                 name:WW_NAVIGATOR_CHANGED object:nil];

    return self;
}

- (void) dispose
{
    [self setEnabled:NO];
    [[[_wwv sceneController] layers] removeLayer:layer];
}

- (void) setEnabled:(BOOL)enabled
{
    if (_enabled == enabled)
        return;

    _enabled = enabled;
    followingPath = NO;

    if (_enabled)
    {
        [self startFollowingPath];
        [layer setEnabled:YES];
    }
    else
    {
        [[_wwv navigator] stopAnimations];
        [layer setEnabled:NO];
    }

    [[NSNotificationCenter defaultCenter] postNotificationName:WW_REQUEST_REDRAW object:self];
}

- (void) navigatorDidChange
{
    if (!_enabled)
        return;

    if (followingPath)
    {
        [self followPath];
    }
    else
    {
        [self startFollowingPath];
    }
}

- (void) startFollowingPath
{
    [[_wwv navigator] animateWithDuration:WWNavigatorDurationAutomatic animations:^
    {
        [self setNavigator:[_wwv navigator] withPosition:currentPosition heading:currentHeading];
    } completion:^(BOOL finished)
    {
        if (!finished) // animation was interrupted by a gesture or another animation
        {
            [self setEnabled:NO];
            return;
        }

        [self followPath];
    }];
}

- (void) followPath
{
    followingPath = YES;
    beginTime = [NSDate timeIntervalSinceReferenceDate]; // now
    markTime = elapsedTime; // previously accumulated elapsed time

    [[_wwv navigator] animateWithBlock:^(NSDate* timestamp, BOOL* stop)
    {
        elapsedTime = markTime + [timestamp timeIntervalSinceReferenceDate] - beginTime;
        [self updateCurrentPositionWithTimeInterval:elapsedTime];
        [self markCurrentPosition];
        [self followCurrentPosition];
        *stop = _finished; // stop when we've reached the last path position
    } completion:^(BOOL finished)
    {
        if (!finished)// animation was interrupted by a gesture or another animation
        {
            [self setEnabled:NO];
        }
    }];
}

- (void) updateCurrentPositionWithTimeInterval:(NSTimeInterval)seconds
{
    if (seconds < 0)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Time interval is invalid")
    }

    NSUInteger positionCount = [[_path positions] count];
    if (positionCount == 1)
    {
        WWPosition* pos = [[_path positions] firstObject];
        [currentPosition setPosition:pos];
        currentHeading = 0;
    }
    else // if (positionCount > 1)
    {
        WWGlobe* globe = [[_wwv sceneController] globe];
        double globeRadius = MAX([globe equatorialRadius], [globe polarRadius]);
        double legDistance[positionCount - 1];
        double routeDistance = 0;

        NSUInteger i;
        for (i = 0; i < positionCount - 1; i++)
        {
            WWPosition* begin = [[_path positions] objectAtIndex:i];
            WWPosition* end = [[_path positions] objectAtIndex:i + 1];
            legDistance[i] = RADIANS([WWLocation rhumbDistance:begin endLocation:end]) * globeRadius; // meters
            routeDistance += legDistance[i];
        }

        double distanceTraveled = _speed * seconds; // meters/second * seconds
        double remainingDistance = distanceTraveled;

        for (i = 0; i < positionCount - 1; i++)
        {
            if (remainingDistance < legDistance[i]) // location is within this non-zero length leg
            {
                double legPct = remainingDistance / legDistance[i];
                WWPosition* begin = [[_path positions] objectAtIndex:i];
                WWPosition* end = [[_path positions] objectAtIndex:i + 1];
                [WWPosition rhumbInterpolate:begin endPosition:end amount:legPct outputPosition:currentPosition];
                currentHeading = [WWPosition rhumbAzimuth:begin endLocation:end];
                return;
            }

            remainingDistance -= legDistance[i];
        }

        // location is at the last position
        WWPosition* begin = [[_path positions] objectAtIndex:i - 1];
        WWPosition* end = [[_path positions] objectAtIndex:i];
        [currentPosition setPosition:end];
        currentHeading = [WWPosition rhumbAzimuth:begin endLocation:end];
        _finished = YES;
    }
}

- (void) markCurrentPosition
{
    [marker setPosition:currentPosition];
}

- (void) followCurrentPosition
{
    id<WWNavigator> navigator = [_wwv navigator];

    NSTimeInterval now = [NSDate timeIntervalSinceReferenceDate];
    if (lastHeading != currentHeading)
    {
        lastHeading = currentHeading;
        headingBeginTime = now;
        headingEndTime = now + 1;
        beginHeading = [navigator heading];
        endHeading = currentHeading;
    }

    double headingPct = [WWMath smoothStepValue:now min:headingBeginTime max:headingEndTime];
    double newHeading = [WWMath interpolateDegrees1:beginHeading degrees2:endHeading amount:headingPct];

    [self setNavigator:navigator withPosition:currentPosition heading:newHeading];
}

- (void) setNavigator:(id<WWNavigator>)navigator withPosition:(WWPosition*)position heading:(double)heading
{
    if ([navigator isKindOfClass:[WWFirstPersonNavigator class]])
    {
        [(WWFirstPersonNavigator*) navigator setEyePosition:position];
        [(WWFirstPersonNavigator*) navigator setHeading:heading];
        [(WWFirstPersonNavigator*) navigator setTilt:67.5];
    }
    else
    {
        [navigator setHeading:heading];
        [navigator setTilt:45];
        [navigator setCenterLocation:position radius:20000];
    }
}

@end