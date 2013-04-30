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

#define NAVIGATOR_ANIMATION_DURATION 1.0
#define NAVIGATOR_RANGE_OFFSET 15000.0
#define NAVIGATOR_FIRST_PERSON_TILT 67.5
#define NAVIGATOR_LOOK_AT_TILT 45.0
#define DISPLAY_LINK_FRAME_INTERVAL 3

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
        [self animateNavigatorToPosition:currentPosition headingDegrees:currentHeading];
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

    if (![self updatePositionForElapsedTime:currentTime])
    {
        [self setEnabled:NO];
    }

    [self updateView];
    [_wwv drawView];
}

- (BOOL) updatePositionForElapsedTime:(NSTimeInterval)time
{
    double segmentIndex = [self pathIndexForElapsedTime:time];

    if (segmentIndex < [[_path positions] count] - 1)
    {
        double segmentPct = segmentIndex - (NSUInteger) segmentIndex;
        WWPosition* segmentBegin = [[_path positions] objectAtIndex:(NSUInteger) segmentIndex];
        WWPosition* segmentEnd = [[_path positions] objectAtIndex:(NSUInteger) segmentIndex + 1];
        [WWPosition rhumbInterpolate:segmentBegin endPosition:segmentEnd amount:segmentPct outputPosition:currentPosition];
        currentHeading = [WWPosition rhumbAzimuth:segmentBegin endLocation:segmentEnd];

        if ((int) segmentIndex != (int) currentIndex)
        {
            [self segmentDidChange:segmentBegin endPosition:segmentEnd];
        }

        currentIndex = segmentIndex;

        return YES;
    }
    else
    {
        WWPosition* segmentBegin = [[_path positions] objectAtIndex:(NSUInteger) segmentIndex - 1];
        WWPosition* segmentEnd = [[_path positions] objectAtIndex:(NSUInteger) segmentIndex];
        [currentPosition setPosition:segmentEnd];
        currentHeading = [WWPosition rhumbAzimuth:segmentBegin endLocation:segmentEnd];
        currentIndex = segmentIndex;

        return NO;
    }
}

- (double) pathIndexForElapsedTime:(NSTimeInterval)time
{
    WWGlobe* globe = [[_wwv sceneController] globe];
    double globeRadius = MAX([globe equatorialRadius], [globe polarRadius]);

    double distanceTraveled = _speed * time;
    double remainingDistance = distanceTraveled;

    NSUInteger i;
    for (i = 0; i < [[_path positions] count] - 1; i++)
    {
        WWPosition* segmentBegin = [[_path positions] objectAtIndex:i];
        WWPosition* segmentEnd = [[_path positions] objectAtIndex:i + 1];
        double segmentDistance = RADIANS([WWPosition rhumbDistance:segmentBegin endLocation:segmentEnd]) * globeRadius;

        if (remainingDistance < segmentDistance) // current position is within this segment
        {
            double pct = remainingDistance / segmentDistance;
            return (double) i + pct; // segment index plus the fractional distance between segmentBegin and segmentEnd
        }

        remainingDistance -= segmentDistance;
    }

    return i; // last position
}

- (void) segmentDidChange:(WWPosition*)beginPosition endPosition:(WWPosition*)endPosition
{
    animBeginTime = [NSDate timeIntervalSinceReferenceDate];
    animEndTime = animBeginTime + NAVIGATOR_ANIMATION_DURATION;
    animBeginHeading = [[_wwv navigator] heading];
    animEndHeading = [WWPosition rhumbAzimuth:beginPosition endLocation:endPosition];
}

- (void) updateView
{
    NSTimeInterval now = [NSDate timeIntervalSinceReferenceDate];
    if (now >= animBeginTime && now <= animEndTime)
    {
        double animPct = [WWMath smoothStepValue:now min:animBeginTime max:animEndTime];
        double heading = [WWMath interpolateDegrees1:animBeginHeading degrees2:animEndHeading amount:animPct];
        [[_wwv navigator] setHeading:heading];
    }

    [marker setPosition:currentPosition];
    [self setNavigatorToPosition:currentPosition];
}

//--------------------------------------------------------------------------------------------------------------------//
//-- Navigator Interface --//
//--------------------------------------------------------------------------------------------------------------------//

- (void) animateNavigatorToPosition:(WWPosition*)position headingDegrees:(double)heading
{
    id<WWNavigator> navigator = [_wwv navigator];

    if ([navigator isKindOfClass:[WWFirstPersonNavigator class]])
    {
        WWFirstPersonNavigator* firstPersonNav = (WWFirstPersonNavigator*) navigator;
        [firstPersonNav animateToEyePosition:position
                              headingDegrees:heading
                                 tiltDegrees:NAVIGATOR_FIRST_PERSON_TILT
                                 rollDegrees:0
                                overDuration:WWNavigatorDurationDefault];
    }
    else if ([navigator isKindOfClass:[WWLookAtNavigator class]])
    {
        WWLookAtNavigator* lookAtNav = (WWLookAtNavigator*) navigator;
        WWPosition* lookAtPos = [[WWPosition alloc] initWithLocation:position altitude:0]; // Ignore the path position's altitude.
        double lookAtRange = [position altitude] + NAVIGATOR_RANGE_OFFSET;
        [lookAtNav animateToLookAtPosition:lookAtPos
                                     range:lookAtRange
                            headingDegrees:heading
                               tiltDegrees:NAVIGATOR_LOOK_AT_TILT
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
        [firstPersonNav setTilt:NAVIGATOR_FIRST_PERSON_TILT];
    }
    else if ([navigator isKindOfClass:[WWLookAtNavigator class]])
    {
        WWLookAtNavigator* lookAtNav = (WWLookAtNavigator*) navigator;
        double lookAtRange = [position altitude] + NAVIGATOR_RANGE_OFFSET;
        [[lookAtNav lookAtPosition] setLocation:position]; // Ignore the path position's altitude.
        [lookAtNav setRange:lookAtRange];
        [lookAtNav setTilt:NAVIGATOR_LOOK_AT_TILT];
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
        [self navigatorDidChange];
    }
    else if ([name isEqualToString:WW_NAVIGATOR_ANIMATION_ENDED])
    {
        [self navigatorAnimationDidEnd];
    }
    else if ([name isEqualToString:WW_NAVIGATOR_ANIMATION_BEGAN]
            || [name isEqualToString:WW_NAVIGATOR_ANIMATION_CANCELLED]
            || [name isEqualToString:WW_NAVIGATOR_GESTURE_RECOGNIZED])
    {
        [self navigatorInterrupted];
    }
}

- (void) navigatorDidChange
{
    if (displayLink == nil) // The navigator changed during the initial animation; restart the animation.
    {
        [self stopObservingNavigator];
        [self animateNavigatorToPosition:currentPosition headingDegrees:currentHeading];
        [self startObservingNavigator];
    }
}

- (void) navigatorAnimationDidEnd
{
    [self startDisplayLink];
}

- (void) navigatorInterrupted
{
    [self setEnabled:NO];
}

@end