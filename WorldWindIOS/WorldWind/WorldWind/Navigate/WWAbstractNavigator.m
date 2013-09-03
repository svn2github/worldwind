/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.

 @version $Id$
 */

#import <CoreLocation/CoreLocation.h>
#import "WorldWind/Navigate/WWAbstractNavigator.h"
#import "WorldWind/Navigate/WWBasicNavigatorState.h"
#import "WorldWind/Geometry/WWMatrix.h"
#import "WorldWind/Geometry/WWPosition.h"
#import "WorldWind/Geometry/WWVec4.h"
#import "WorldWind/Render/WWSceneController.h"
#import "WorldWind/Terrain/WWGlobe.h"
#import "WorldWind/Util/WWMath.h"
#import "WorldWind/WorldWindView.h"
#import "WorldWind/WorldWindConstants.h"
#import "WorldWind/WWLog.h"

#define DEFAULT_HEADING 0
#define DEFAULT_TILT 0
#define DEFAULT_ROLL 0
#define DEFAULT_NEAR_DISTANCE 1
#define DEFAULT_FAR_DISTANCE 10000000
#define DISPLAY_LINK_FRAME_INTERVAL 3
#define MIN_NEAR_DISTANCE 1
#define MIN_FAR_DISTANCE 1000
#define TARGET_FAR_RESOLUTION 10.0

@implementation WWAbstractNavigator

//--------------------------------------------------------------------------------------------------------------------//
//-- Initializing Navigators --//
//--------------------------------------------------------------------------------------------------------------------//

- (WWAbstractNavigator*) initWithView:(WorldWindView*)view
{
    if (view == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"View is nil")
    }

    self = [super init];

    _view = view;
    _heading = DEFAULT_HEADING;
    _tilt = DEFAULT_TILT;
    _roll = DEFAULT_ROLL;
    _nearDistance = DEFAULT_NEAR_DISTANCE;
    _farDistance = DEFAULT_FAR_DISTANCE;

    return self;
}

- (void) dealloc
{
    [self dispose];
}

- (void) dispose
{
    // Invalidate the display link if the navigator is de-allocated before the display link can be cleaned up normally.
    if (displayLink != nil)
    {
        [displayLink invalidate];
        displayLink = nil;
    }
}

//--------------------------------------------------------------------------------------------------------------------//
//-- Navigator Protocol for Subclasses --//
//--------------------------------------------------------------------------------------------------------------------//

- (id<WWNavigatorState>) currentState
{
    return nil; // Must be implemented by subclass
}

- (id<WWNavigatorState>) currentStateForModelview:(WWMatrix*)modelview
{
    if (modelview == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Modelview matrix is nil")
    }

    // The view is a weak reference, so it may have been de-allocated. In this case currentState returns nil since it
    // has no context with which to compute the current modelview and projection matrices.
    if (_view == nil)
    {
        WWLog(@"Unable to compute current navigator state: View is nil (deallocated)");
        return nil;
    }

    WWGlobe* globe = [[_view sceneController] globe];
    CGRect viewport = [_view viewport];

    // Compute the eye point in model coordinates and the corresponding eye position in geographic coordinates.
    WWVec4* eyePoint = [modelview extractEyePoint];
    WWPosition* eyePos = [[WWPosition alloc] init];
    [globe computePositionFromPoint:[eyePoint x] y:[eyePoint y] z:[eyePoint z] outputPosition:eyePos];

    // Compute the far clip distance based on the current eye altitude. This must be done after computing the modelview
    // matrix and before computing the near clip distance. The far clip distance depends on the modelview matrix, and
    // the near clip distance depends on the far clip distance.
    double globeRadius = MAX([globe equatorialRadius], [globe polarRadius]);
    _farDistance = [WWMath horizonDistanceForGlobeRadius:globeRadius eyeAltitude:[eyePos altitude]];
    if (_farDistance < MIN_FAR_DISTANCE)
        _farDistance = MIN_FAR_DISTANCE;

    // Compute the near clip distance in order to achieve a desired depth resolution at the far clip distance. This
    // computed distance is limited such that it does not intersect the terrain when possible and is never less than
    // one.
    GLint viewDepthBits = [_view depthBits];
    _nearDistance = [WWMath perspectiveNearDistanceForFarDistance:_farDistance farResolution:TARGET_FAR_RESOLUTION depthBits:viewDepthBits];

    double distanceToSurface = [eyePos altitude] - [globe elevationForLatitude:[eyePos latitude] longitude:[eyePos longitude]];
    if (distanceToSurface > 0) // The eye is above the terrain; avoid intersecting the terrain with the near clip plane.
    {
        double maxNearDistance = [WWMath perspectiveNearDistance:viewport forObjectAtDistance:distanceToSurface];
        if (_nearDistance > maxNearDistance)
            _nearDistance = maxNearDistance;
    }

    if (_nearDistance < MIN_NEAR_DISTANCE) // The near clip distance must be at least one.
        _nearDistance = MIN_NEAR_DISTANCE;

    // Compute the current projection matrix based on this Navigator's perspective properties and the current OpenGL
    // viewport. We use the WorldWindView's OpenGL viewport instead of the view's bounds because the viewport contains
    // the actual render buffer dimensions in OpenGL screen coordinates, whereas the bounds contain the view's
    // dimensions in UIKit screen coordinates.
    WWMatrix* projection = [[WWMatrix alloc] initWithIdentity];
    [projection setToPerspectiveProjection:viewport nearDistance:_nearDistance farDistance:_farDistance];

    return [[WWBasicNavigatorState alloc] initWithModelview:modelview
                                                 projection:projection
                                                       view:_view
                                                    heading:_heading
                                                       tilt:_tilt];
}

//--------------------------------------------------------------------------------------------------------------------//
//-- Setting the Location of Interest --//
//--------------------------------------------------------------------------------------------------------------------//

- (void) setToPosition:(WWPosition*)position
{
    // Must be implemented by subclass
}

- (void) setToRegionWithCenter:(WWPosition*)center radius:(double)radius
{
    // Must be implemented by subclass
}

- (void) animateToPosition:(WWPosition*)position overDuration:(NSTimeInterval)duration
{
    // Must be implemented by subclass
}

- (void) animateToRegionWithCenter:(WWPosition*)center radius:(double)radius overDuration:(NSTimeInterval)duration
{
    // Must be implemented by subclass
}

//--------------------------------------------------------------------------------------------------------------------//
//-- Core Location Interface for Subclasses --//
//--------------------------------------------------------------------------------------------------------------------//

- (WWPosition*) lastKnownPosition
{
    WWPosition* position = [[WWPosition alloc] initWithZeroPosition];
    [position setDegreesLatitude:0 timeZoneForLongitude:[NSTimeZone localTimeZone]];

    if (![CLLocationManager locationServicesEnabled])
    {
        WWLog(@"Location services is disabled; Using default navigator location.");
        return position;
    }

    CLLocationManager* locationManager = [[CLLocationManager alloc] init];
    CLLocation* location = [locationManager location];
    if (location == nil)
    {
        WWLog(@"Location services has no previous location; Using default navigator location.");
        return position;
    }

    WWLog(@"Initializing navigator with previous known location (%f, %f)", [location coordinate].latitude, [location coordinate].longitude);
    [position setCLPosition:location];
    return position;
}

//--------------------------------------------------------------------------------------------------------------------//
//-- Display Link Interface for Subclasses --//
//--------------------------------------------------------------------------------------------------------------------//

- (void) startDisplayLink
{
    if (displayLinkObservers == 0)
    {
        displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(displayLinkDidFire:)];
        [displayLink setFrameInterval:DISPLAY_LINK_FRAME_INTERVAL];
        [displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    }

    displayLinkObservers++;
}

- (void) stopDisplayLink
{
    displayLinkObservers--;

    if (displayLinkObservers == 0)
    {
        [displayLink invalidate];
        displayLink = nil;
    }
}

- (void) displayLinkDidFire:(CADisplayLink*)notifyingDisplayLink
{
    if (animating)
    {
        NSDate* now = [NSDate date];
        [self updateAnimationForDate:now];
    }

    [_view drawView]; // The view is a weak reference; this has no effect if the view has been deallocated.
}

//--------------------------------------------------------------------------------------------------------------------//
//-- Gesture Recognizer Interface for Subclasses --//
//--------------------------------------------------------------------------------------------------------------------//

- (void) gestureRecognizerDidBegin:(UIGestureRecognizer*)recognizer
{
    // Cancel any currently active animations and start the display link. Navigator gestures override any currently
    // active animation.
    [self cancelAnimation];
    [self startDisplayLink];

    // Post a notification that the navigator has recognized a gesture. Do this last so that the navigator posts the
    // gesture recognized notification after any animation cancelled notifications.
    NSNotification* notification = [NSNotification notificationWithName:WW_NAVIGATOR_GESTURE_RECOGNIZED object:self];
    [[NSNotificationCenter defaultCenter] postNotification:notification];
}

- (void) gestureRecognizerDidEnd:(UIGestureRecognizer*)recognizer
{
    // Stop the display link and redraw the view. This handles the case when the last gesture update and the gesture end
    // occur before the display link has a chance to fire and redraw the view.
    [self stopDisplayLink];
    [_view drawView]; // The view is a weak reference; this has no effect if the view has been deallocated.
}

//--------------------------------------------------------------------------------------------------------------------//
//-- Animation Interface for Subclasses --//
//--------------------------------------------------------------------------------------------------------------------//

- (void) beginAnimationWithDuration:(NSTimeInterval)duration
{
    if (!animating)
    {
        // Compute the animation's begin and end date based on the current time and the specified duration.
        animBeginDate = [NSDate date];
        animEndDate = [NSDate dateWithTimeInterval:duration sinceDate:animBeginDate];

        [self animationDidBegin];
        animating = YES;
    }
}

- (void) endAnimation
{
    if (animating)
    {
        [self animationDidEnd];
        animating = NO;
    }
}

- (void) cancelAnimation
{
    if (animating)
    {
        [self animationWasCancelled];
        animating = NO;
    }
}

- (void) updateAnimationForDate:(NSDate*)date
{
    NSTimeInterval now = [date timeIntervalSinceReferenceDate];
    NSTimeInterval endTime = [animEndDate timeIntervalSinceReferenceDate];

    if (now >= endTime) // The animation has reached its scheduled end.
    {
        [self endAnimation];
    }
    else
    {
        [self animationDidUpdate:date begin:animBeginDate end:animEndDate];
    }
}

- (void) animationDidBegin
{
    [self startDisplayLink];

    NSNotification* notification = [NSNotification notificationWithName:WW_NAVIGATOR_ANIMATION_BEGAN object:self];
    [[NSNotificationCenter defaultCenter] postNotification:notification];
}

- (void) animationDidEnd
{
    [self stopDisplayLink];

    NSNotification* notification = [NSNotification notificationWithName:WW_NAVIGATOR_ANIMATION_ENDED object:self];
    [[NSNotificationCenter defaultCenter] postNotification:notification];
}

- (void) animationWasCancelled
{
    [self stopDisplayLink];

    NSNotification* notification = [NSNotification notificationWithName:WW_NAVIGATOR_ANIMATION_CANCELLED object:self];
    [[NSNotificationCenter defaultCenter] postNotification:notification];
}

- (void) animationDidUpdate:(NSDate*)date begin:(NSDate*)begin end:(NSDate*)end
{
    // Must be implemented by subclass
}

@end