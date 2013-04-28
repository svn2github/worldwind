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

#define NAVIGATOR_LOOK_AT_RANGE 30000.0
#define DISPLAY_LINK_FRAME_INTERVAL 3

@implementation PathFollower

- (PathFollower*) initWithPath:(WWPath*)path speed:(double)speed view:(WorldWindView*)view
{
    self = [super init];

    _path = path;
    _speed = speed;
    _wwv = view;

    WWPosition* firstPosition = [[_path positions] objectAtIndex:0];
    currentPosition = [[WWPosition alloc] initWithPosition:firstPosition];

    WWShapeAttributes* attributes = [[WWShapeAttributes alloc] init];
    [attributes setInteriorColor:[[WWColor alloc] initWithR:.24 g:.47 b:.99 a:1]];
    marker = [[WWSphere alloc] initWithPosition:currentPosition radiusInPixels:7];
    [marker setDisplayName:@"Location on Path"];
    [marker setAttributes:attributes];

    layer = [[WWRenderableLayer alloc] init];
    [layer setDisplayName:@"Path Marker"];
    [layer addRenderable:marker];
    [[[_wwv sceneController] layers] addLayer:layer];

    return self;
}

- (void) dispose
{
    [self stopDisplayLink];
    [self stopObservingNavigator];

    [layer removeRenderable:marker];
    [[[_wwv sceneController] layers] removeLayer:layer];
}

- (void) setEnabled:(BOOL)enabled
{
    if (_enabled == enabled)
    {
        return;
    }

    if (enabled)
    {
        [self animateNavigatorToPosition:currentPosition];
        [self startObservingNavigator]; // Observe after the animation begins to ignore its begin notification.
    }
    else
    {
        [self stopDisplayLink];
        [self stopObservingNavigator];
    }

    _enabled = enabled;
}

//--------------------------------------------------------------------------------------------------------------------//
//-- Timer Interface --//
//--------------------------------------------------------------------------------------------------------------------//

- (void) startDisplayLink
{
    if (displayLink == nil)
    {
        beginTime = [NSDate timeIntervalSinceReferenceDate];
        offsetTime = currentTime; // Initially zero, then the last time associated with a timer firing thereafter.

        displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(displayLinkDidFire:)];
        [displayLink setFrameInterval:DISPLAY_LINK_FRAME_INTERVAL];
        [displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    }
}

- (void) stopDisplayLink
{
    if (displayLink != nil)
    {
        [displayLink invalidate];
        displayLink = nil;
    }
}

- (void) displayLinkDidFire:(CADisplayLink*)notifyingDisplayLink
{
    NSTimeInterval now = [NSDate timeIntervalSinceReferenceDate];
    currentTime = offsetTime + now - beginTime;

    if ([self positionForTimeInterval:currentTime outPosition:currentPosition])
    {
        [marker setPosition:currentPosition];
        [self setNavigatorToPosition:currentPosition];
        [_wwv drawView];
    }
    else
    {
        [self setEnabled:NO];
    }
}

- (BOOL) positionForTimeInterval:(NSTimeInterval)timeInterval outPosition:(WWPosition*)result;
{
    double distanceTraveled = _speed * timeInterval;

    double remainingDistance = distanceTraveled;
    WWPosition* previousPathPosition = [[_path positions] objectAtIndex:0];

    for (NSUInteger i = 1; i < [[_path positions] count]; i++)
    {
        WWPosition* nextPathPosition = [[_path positions] objectAtIndex:i];

        double segmentDistance = [WWPosition rhumbDistance:previousPathPosition endLocation:nextPathPosition];
        segmentDistance = RADIANS(segmentDistance);
        segmentDistance *= [[[_wwv sceneController] globe] equatorialRadius];
        if (remainingDistance - segmentDistance > 0) // current position is beyond this segment
        {
            remainingDistance -= segmentDistance;
            previousPathPosition = nextPathPosition;
            continue;
        }

        if (remainingDistance - segmentDistance == 0)
        {
            [result setPosition:nextPathPosition];
            return YES;
        }

        // remainingDistance - segmentDistance < 0 ==> current position is within this segment
        double s = remainingDistance / segmentDistance;
        [WWPosition rhumbInterpolate:previousPathPosition
                         endPosition:nextPathPosition
                              amount:s
                      outputPosition:result];
        return YES;
    }

    WWPosition* lastPosition = [[_path positions] lastObject];
    [result setPosition:lastPosition];
    return NO;
}

//--------------------------------------------------------------------------------------------------------------------//
//-- Navigator Interface --//
//--------------------------------------------------------------------------------------------------------------------//

- (void) animateNavigatorToPosition:(WWPosition*)position
{
    id<WWNavigator> navigator = [_wwv navigator];

    if ([navigator isKindOfClass:[WWFirstPersonNavigator class]])
    {
        WWFirstPersonNavigator* firstPersonNav = (WWFirstPersonNavigator*) navigator;
        [firstPersonNav animateToEyePosition:position
                              headingDegrees:[firstPersonNav heading]
                                 tiltDegrees:[firstPersonNav tilt]
                                 rollDegrees:0
                                overDuration:WWNavigatorDurationDefault];
    }
    else if ([navigator isKindOfClass:[WWLookAtNavigator class]])
    {
        WWLookAtNavigator* lookAtNav = (WWLookAtNavigator*) navigator;
        WWPosition* lookAtPos = [[WWPosition alloc] initWithLocation:position altitude:0]; // Ignore the path position's altitude.
        [lookAtNav animateToLookAtPosition:lookAtPos
                                     range:NAVIGATOR_LOOK_AT_RANGE
                            headingDegrees:[lookAtNav heading]
                               tiltDegrees:[lookAtNav tilt]
                               rollDegrees:0
                              overDuration:WWNavigatorDurationDefault];
    }
    else
    {
        WWLog(@"Unknown navigator type: %@", navigator);
    }
}

- (void) setNavigatorToPosition:(WWPosition*)position
{
    id<WWNavigator> navigator = [_wwv navigator];

    if ([navigator isKindOfClass:[WWFirstPersonNavigator class]])
    {
        WWFirstPersonNavigator* firstPersonNav = (WWFirstPersonNavigator*) navigator;
        [[firstPersonNav eyePosition] setPosition:position];

    }
    else if ([navigator isKindOfClass:[WWLookAtNavigator class]])
    {
        WWLookAtNavigator* lookAtNav = (WWLookAtNavigator*) navigator;
        [[lookAtNav lookAtPosition] setLocation:position]; // Ignore the path position's altitude.
        [lookAtNav setRange:NAVIGATOR_LOOK_AT_RANGE];
    }
    else
    {
        WWLog(@"Unknown navigator type: %@", navigator);
    }
}

- (void) startObservingNavigator
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleNavigatorNotification:)
                                                 name:nil
                                               object:nil];
}

- (void) stopObservingNavigator
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void) handleNavigatorNotification:(NSNotification*)notification
{
    NSString* name = [notification name];

    if ([name isEqualToString:WW_NAVIGATOR_CHANGED])
    {
        [self navigatorChanged];
    }
    else if ([name isEqualToString:WW_NAVIGATOR_ANIMATION_ENDED])
    {
        [self navigatorAnimationEnded];
    }
    else if ([name isEqualToString:WW_NAVIGATOR_ANIMATION_BEGAN]
            || [name isEqualToString:WW_NAVIGATOR_ANIMATION_CANCELLED]
            || [name isEqualToString:WW_NAVIGATOR_GESTURE_RECOGNIZED])
    {
        [self navigatorInterrupted];
    }
}

- (void) navigatorChanged
{
    if (displayLink == nil)
    {
        [self stopObservingNavigator];
        [self animateNavigatorToPosition:currentPosition];
        [self startObservingNavigator];
    }
}

- (void) navigatorAnimationEnded
{
    [self startDisplayLink];
}

- (void) navigatorInterrupted
{
    [self setEnabled:NO];
}

@end