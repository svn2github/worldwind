/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.

 @version $Id$
 */

#import <CoreLocation/CoreLocation.h>
#import "WorldWind/Navigate/WWBasicNavigator.h"
#import "WorldWind/Navigate/WWBasicNavigatorState.h"
#import "WorldWind/Render/WWSceneController.h"
#import "WorldWind/Terrain/WWGlobe.h"
#import "WorldWind/Geometry/WWLocation.h"
#import "WorldWind/Geometry/WWPosition.h"
#import "WorldWind/Geometry/WWMatrix.h"
#import "WorldWind/Util/WWMath.h"
#import "WorldWind/WorldWindConstants.h"
#import "WorldWind/WorldWindView.h"
#import "WorldWind/WWLog.h"

#define DEFAULT_NEAR_DISTANCE 1
#define DEFAULT_FAR_DISTANCE 1000000000
#define DEFAULT_LATITUDE 0
#define DEFAULT_LONGITUDE 0
#define DEFAULT_ALTITUDE 10000000
#define DEFAULT_HEADING 0
#define DEFAULT_TILT 0
#define DISPLAY_LINK_FRAME_INTERVAL 3
#define MIN_NEAR_DISTANCE 1
#define MIN_FAR_DISTANCE 100

@implementation WWBasicNavigator
{
    WorldWindView* __weak view; // Keep a weak reference to the parent view prevent a circular reference.

    UIPanGestureRecognizer* panGestureRecognizer;
    UIPinchGestureRecognizer* pinchGestureRecognizer;
    UIRotationGestureRecognizer* rotationGestureRecognizer;
    UIPanGestureRecognizer* verticalPanGestureRecognizer;
    CGPoint lastPanTranslation;
    double gestureBeginRange;
    double gestureBeginHeading;
    double gestureBeginTilt;

    CADisplayLink* displayLink;
    int displayLinkObservers;

    WWPosition* animBeginLookAt;
    WWPosition* animEndLookAt;
    double animBeginRange;
    double animEndRange;
    double animMidRange;
    NSDate* animBeginDate;
    NSDate* animEndDate;
    BOOL animating;
}

- (WWBasicNavigator*) initWithView:(WorldWindView*)viewToNavigate
{
    self = [super init];

    if (viewToNavigate == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"View is nil")
    }

    if (self != nil)
    {
        self->view = viewToNavigate;
        self->panGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePanFrom:)];
        self->pinchGestureRecognizer = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(handlePinchFrom:)];
        self->rotationGestureRecognizer = [[UIRotationGestureRecognizer alloc] initWithTarget:self action:@selector(handleRotationFrom:)];
        self->verticalPanGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handleVerticalPanFrom:)];

        [self->panGestureRecognizer setDelegate:self];
        [self->pinchGestureRecognizer setDelegate:self];
        [self->rotationGestureRecognizer setDelegate:self];
        [self->verticalPanGestureRecognizer setDelegate:self];
        [self->verticalPanGestureRecognizer setMinimumNumberOfTouches:2];

        [self->view addGestureRecognizer:self->panGestureRecognizer];
        [self->view addGestureRecognizer:self->pinchGestureRecognizer];
        [self->view addGestureRecognizer:self->rotationGestureRecognizer];
        [self->view addGestureRecognizer:self->verticalPanGestureRecognizer];

        self->animBeginLookAt = [[WWPosition alloc] init];
        self->animEndLookAt = [[WWPosition alloc] init];

        _nearDistance = DEFAULT_NEAR_DISTANCE;
        _farDistance = DEFAULT_FAR_DISTANCE;
        _lookAt = [[WWLocation alloc] initWithDegreesLatitude:DEFAULT_LATITUDE longitude:DEFAULT_LONGITUDE];
        _range = DEFAULT_ALTITUDE;
        _heading = DEFAULT_HEADING;
        _tilt = DEFAULT_TILT;
        [self setInitialLocation];
    }

    return self;
}

- (void) dealloc
{
    // Remove gesture recognizers from the parent view when the navigator is de-allocated. The view is a weak reference,
    // so it may have been de-allocated. In this case it is unnecessary to remove these references.
    if (self->view != nil)
    {
        [self->view removeGestureRecognizer:self->panGestureRecognizer];
        [self->view removeGestureRecognizer:self->pinchGestureRecognizer];
        [self->view removeGestureRecognizer:self->rotationGestureRecognizer];
        [self->view removeGestureRecognizer:self->verticalPanGestureRecognizer];
    }

    // Invalidate the display link if the navigator is de-allocated before the display link can be cleaned up normally.
    if (self->displayLink != nil)
    {
        [self->displayLink invalidate];
    }
}

- (id<WWNavigatorState>) currentState
{
    // The view is a weak reference, so it may have been de-allocated. In this case currentState returns nil since it
    // has no context with which to compute the current modelview and projection matrices.
    if (self->view == nil)
    {
        WWLog(@"Unable to compute current navigator state: View is nil (deallocated)");
        return nil;
    }

    WWGlobe* globe = [[self->view sceneController] globe];
    double globeRadius = MAX([globe equatorialRadius], [globe polarRadius]);

    CGRect viewport = [self->view viewport];
    double viewportWidth = CGRectGetWidth(viewport);
    double viewportHeight = CGRectGetHeight(viewport);

    // Compute the current modelview matrix based on this Navigator's look-at location, range, heading, and tilt.
    WWMatrix* modelview = [[WWMatrix alloc] initWithIdentity];
    [modelview setLookAt:globe
          centerLatitude:[_lookAt latitude]
         centerLongitude:[_lookAt longitude]
          centerAltitude:0
           rangeInMeters:_range
                 heading:_heading
                    tilt:_tilt];

    // Compute the current near and far clip distances based on the current eye elevation relative to the globe. This
    // must be done after computing the modelview matrix, since the modelview matrix defines the eye position. Compute
    // the eye point in geographic. The eye point is computed by multiplying (0, 0, 0, 1) by the inverse of the
    // modelview matrix, then converting the result to a geographic position. We have pre-computed the result and stored
    // it inline here to avoid an unnecessary matrix multiplication.
    WWMatrix* mvi = [[[WWMatrix alloc] initWithIdentity] invertTransformMatrix:modelview];
    WWPosition* eyePos = [[WWPosition alloc] initWithDegreesLatitude:0 longitude:0 altitude:0];
    [globe computePositionFromPoint:mvi->m[3] y:mvi->m[7] z:mvi->m[11] outputPosition:eyePos];

    double globeElevation = [globe elevationForLatitude:[eyePos latitude] longitude:[eyePos longitude]]; // Must use globe elevation; terrain is not yet computed.
    double heightAboveTerrain = [eyePos altitude] - globeElevation;
    _nearDistance = [WWMath perspectiveSizePreservingMaxNearDistance:viewportWidth
                                                      viewportHeight:viewportHeight
                                                    distanceToObject:heightAboveTerrain];
    if (_nearDistance < MIN_NEAR_DISTANCE)
        _nearDistance = MIN_NEAR_DISTANCE;

    _farDistance = [WWMath horizonDistance:globeRadius elevation:[eyePos altitude]];
    if (_farDistance < MIN_FAR_DISTANCE)
        _farDistance = MIN_FAR_DISTANCE;

    // Compute the current projection matrix based on this Navigator's perspective properties and the current OpenGL
    // viewport. We use the WorldWindView's OpenGL viewport instead of the view's bounds because the viewport contains
    // the actual render buffer dimensions in OpenGL screen coordinates, whereas the bounds contain the view's
    // dimensions in UIKit screen coordinates.
    WWMatrix *projection = [[WWMatrix alloc] initWithIdentity];
    [projection setPerspectiveSizePreserving:viewportWidth
                              viewportHeight:viewportHeight
                                nearDistance:_nearDistance
                                 farDistance:_farDistance];

    return [[WWBasicNavigatorState alloc] initWithModelview:modelview projection:projection viewport:viewport];
}

- (void) gotoLocation:(WWLocation*)location overDuration:(NSTimeInterval)duration
{
    if (location == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Location is nil")
    }

    if (duration < 0)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Duration is invalid")
    }

    [self beginAnimationWithLookAt:location range:_range overDuration:duration];
}

- (void) gotoLookAt:(WWLocation*)lookAt range:(double)range overDuration:(NSTimeInterval)duration
{
    if (lookAt == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"LookAt is nil")
    }

    if (range < 0)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Range is invalid")
    }

    if (duration < 0)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Duration is invalid")
    }

    [self beginAnimationWithLookAt:lookAt range:range overDuration:duration];
}

- (void) gotoRegionWithCenter:(WWLocation*)center radius:(double)radius overDuration:(NSTimeInterval)duration
{
    if (center == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Center is nil")
    }

    if (radius < 0)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Radius is invalid");
    }

    if (duration < 0)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Duration is invalid")
    }

    double fitDistance = [WWMath eyeDistanceToFitObjectWithRadius:radius inViewport:[view viewport]];
    [self beginAnimationWithLookAt:center range:fitDistance overDuration:duration];
}

- (void) setInitialLocation
{
    [_lookAt setDegreesLatitude:DEFAULT_LATITUDE timeZoneForLongitude:[NSTimeZone localTimeZone]];

    if (![CLLocationManager locationServicesEnabled])
    {
        WWLog(@"Location services is disabled; Using default navigator location.");
        return;
    }

    CLLocationManager* locationManager = [[CLLocationManager alloc] init];
    CLLocation* location = [locationManager location];
    if (location == nil)
    {
        WWLog(@"Location services has no previous location; Using default navigator location.");
        return;
    }

    WWLog(@"Initializing navigator with previous known location (%f, %f)", [location coordinate].latitude, [location coordinate].longitude);
    [_lookAt setCLLocation:location];
}

- (void) startDisplayLink
{
    if (self->displayLinkObservers == 0)
    {
        self->displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(displayLinkDidFire:)];
        [self->displayLink setFrameInterval:DISPLAY_LINK_FRAME_INTERVAL];
        [self->displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    }

    self->displayLinkObservers++;
}

- (void) stopDisplayLink
{
    self->displayLinkObservers--;

    if (self->displayLinkObservers == 0)
    {
        [self->displayLink invalidate];
        self->displayLink = nil;
    }
}

- (void) displayLinkDidFire:(CADisplayLink*)aDisplayLink
{
    if (self->animating)
    {
        NSDate* now = [NSDate date];
        [self updateAnimationForDate:now];
    }

    [view drawView]; // The view is a weak reference; this has no effect if the view has been deallocated.
}

- (void) handlePanFrom:(UIPanGestureRecognizer*)recognizer
{
    // Apply the translation of the pan gesture to this Navigator's look-at location. We convert the pan translation
    // from screen pixels to arc degrees in order to provide a translation that is appropriate for the current eye
    // position. In order to convert from pixels to arc degrees we assume that this Navigator's range represents the
    // distance that the gesture is intended for. The translation is applied incrementally so that simultaneously
    // applied heading changes are correctly integratedinto the navigator's current location.

    // Note: the view property is a weak reference, so it may have been de-allocated. In this case the contents of the
    // CG structures below will be undefined. However, the view's gesture recognizers will not be sent any messages
    // after the view itself is de-allocated.

    UIGestureRecognizerState state = [recognizer state];

    if (state == UIGestureRecognizerStateBegan)
    {
        self->lastPanTranslation = CGPointMake(0, 0);
        [self gestureRecognizerDidBegin:recognizer];
    }
    else if (state == UIGestureRecognizerStateEnded || state == UIGestureRecognizerStateCancelled)
    {
        [self gestureRecognizerDidEnd:recognizer];
    }
    else if (state == UIGestureRecognizerStateChanged)
    {
        // Compute the translation in the view's local coordinate system.
        CGPoint panTranslation = [recognizer translationInView:self->view];
        double dx = panTranslation.x - self->lastPanTranslation.x;
        double dy = panTranslation.y - self->lastPanTranslation.y;
        self->lastPanTranslation = panTranslation;

        // Convert the translation from the view's local coordinate system to meters, assuming the translation is
        // intended for an object that is 'range' meters away form the eye position. Convert from change in screen
        // relative coordinates to change in model relative coordinates by inverting the change in X. There is no need
        // to invert the change in Y because the Y axis coordinates are already inverted.
        CGRect viewport = [self->view viewport];
        double distance = MAX(1, _range);
        double metersPerPixel = [WWMath perspectiveSizePreservingMaxPixelSize:CGRectGetWidth(viewport)
                                                               viewportHeight:CGRectGetHeight(viewport)
                                                             distanceToObject:distance];
        double forwardMeters = dy * metersPerPixel;
        double sideMeters = -dx * metersPerPixel;

        // Convert the translation from meters to arc degrees. The globe's radius provides the necessary context to
        // perform this conversion.
        WWGlobe* globe = [[self->view sceneController] globe];
        double globeRadius = MAX([globe equatorialRadius], [globe polarRadius]);
        double forwardDegrees = DEGREES(forwardMeters / globeRadius);
        double sideDegrees = DEGREES(sideMeters / globeRadius);

        // Convert the translation from arc degrees to change in latitude and longitude relative to the current heading.
        // The resultant translation in latitude and longitude is defined in the equirectangular coordinate system.
        double sinHeading = sin(RADIANS(_heading));
        double cosHeading = cos(RADIANS(_heading));
        double latDegrees = forwardDegrees * cosHeading - sideDegrees * sinHeading;
        double lonDegrees = forwardDegrees * sinHeading + sideDegrees * cosHeading;

        // Apply the change in latitude and longitude to this navigator's lookAt property. Limit the new latitude to the
        // range (-90, 90) in order to stop the forward movement at the pole. Panning over the pole requires a
        // corresponding change in heading, which has not been implemented here in favor of simplicity.
        double newLat = [WWMath clampValue:([_lookAt latitude] + latDegrees) min:-90 max:90];
        double newLon = NormalizedDegreesLongitude([_lookAt longitude] + lonDegrees);
        [_lookAt setDegreesLatitude:newLat longitude:newLon];
    }
    else
    {
        WWLog(@"Unknown gesture recognizer state: %d", state);
    }
}

- (void) handlePinchFrom:(UIPinchGestureRecognizer*)recognizer
{
    // Apply the inverse of the pinch gesture's scale to this Navigator's range. Pinch-in gestures move the eye position
    // closer to the look-at position, while pinch-out gestures move the eye away from the look-at position. There is no
    // need to apply any additional scaling to the change in range based on eye position because the nature of a pinch
    // gesture already accomplishes this. Each pinch gesture applies a linear scale to the current range. This scale
    // value has a limited range - typically between 1/10 and 10 - due to the limited size of the touch surface and an
    // average user's hand. This means that large changes in range are accomplished by multiple successive pinch
    // gestures, rather than one continuous gesture. Since each gesture's scale is applied to the current range, the
    // resultant scaling is implicitly appropriate for the current eye position.

    UIGestureRecognizerState state = [recognizer state];

    if (state == UIGestureRecognizerStateBegan)
    {
        self->gestureBeginRange = _range;
        [self gestureRecognizerDidBegin:recognizer];
    }
    else if (state == UIGestureRecognizerStateEnded || state == UIGestureRecognizerStateCancelled)
    {
        [self gestureRecognizerDidEnd:recognizer];
    }
    else if (state == UIGestureRecognizerStateChanged)
    {
        // Ignore a scale of zero. This appears to be a bug in UIPinchGestureRecognzier's handling of the user changing
        // between two and three fingers while pinching.
        CGFloat scale = [recognizer scale];
        if (scale != 0)
        {
            _range = self->gestureBeginRange / scale;
        }
    }
    else
    {
        WWLog(@"Unknown gesture recognizer state: %d", state);
    }
}

- (void) handleRotationFrom:(UIRotationGestureRecognizer*)recognizer
{
    UIGestureRecognizerState state = [recognizer state];

    if (state == UIGestureRecognizerStateBegan)
    {
        self->gestureBeginHeading = _heading;
        [self gestureRecognizerDidBegin:recognizer];
    }
    else if (state == UIGestureRecognizerStateEnded || state == UIGestureRecognizerStateCancelled)
    {
        [self gestureRecognizerDidEnd:recognizer];
    }
    else if (state == UIGestureRecognizerStateChanged)
    {
        double rotationInDegrees = DEGREES([recognizer rotation]);
        _heading = NormalizedDegreesHeading(self->gestureBeginHeading - rotationInDegrees);
    }
    else
    {
        WWLog(@"Unknown gesture recognizer state: %d", state);
    }
}

- (void) handleVerticalPanFrom:(UIPanGestureRecognizer*)recognizer
{
    // Note: the view property is a weak reference, so it may have been de-allocated. In this case the contents of the
    // CG structures below will be undefined. However, the view's gesture recognizers will not be sent any messages
    // after the view itself is de-allocated.

    UIGestureRecognizerState state = [recognizer state];

    if (state == UIGestureRecognizerStateBegan)
    {
        self->gestureBeginTilt = _tilt;
        [self gestureRecognizerDidBegin:recognizer];
    }
    else if (state == UIGestureRecognizerStateEnded || state == UIGestureRecognizerStateCancelled)
    {
        [self gestureRecognizerDidEnd:recognizer];
    }
    else if (state == UIGestureRecognizerStateChanged)
    {
        CGPoint translation = [recognizer translationInView:self->view];
        CGRect bounds = [self->view bounds];
        double degrees = 90 * translation.y / CGRectGetHeight(bounds);
        _tilt = [WWMath clampValue:self->gestureBeginTilt + degrees min:0 max:90];
    }
    else
    {
        WWLog(@"Unknown gesture recognizer state: %d", state);
    }
}

- (BOOL) gestureRecognizer:(UIGestureRecognizer*)recognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer*)otherRecognizer
{
    if (recognizer == self->panGestureRecognizer)
    {
        return otherRecognizer == self->pinchGestureRecognizer || otherRecognizer == self->rotationGestureRecognizer;
    }
    else if (recognizer == self->pinchGestureRecognizer)
    {
        return otherRecognizer == self->panGestureRecognizer || otherRecognizer == self->rotationGestureRecognizer;
    }
    else if (recognizer == self->rotationGestureRecognizer)
    {
        return otherRecognizer == self->panGestureRecognizer || otherRecognizer == self->pinchGestureRecognizer;
    }
    else
    {
        return NO;
    }
}

- (BOOL) gestureRecognizerShouldBegin:(UIGestureRecognizer*)recognizer
{
    // Note: the view property is a weak reference, so it may have been de-allocated. In this case the contents of the
    // CG structures below will be undefined. However, the view's gesture recognizers will not be sent any messages
    // after the view itself is de-allocated.

    // Determine whether the vertical pan gesture recognizer should recognizer its gesture. This gesture recognizer is
    // a UIPanGestureRecognizer configured with two or more touches. In order to limit its recognition to a vertical pan
    // gesture, we place additional limitations on its recognition in this delegate.
    if (recognizer == self->verticalPanGestureRecognizer)
    {
        UIPanGestureRecognizer* pgr = (UIPanGestureRecognizer*) recognizer;

        CGPoint translation = [pgr translationInView:self->view];
        if (fabs(translation.x) > fabs(translation.y))
        {
            return NO; // Do not recognize the gesture; the pan is horizontal.
        }

        NSUInteger numTouches = [pgr numberOfTouches];
        if (numTouches < 2)
        {
            return NO; // Do not recognize the gesture; not enough touches.
        }

        CGPoint touch1 = [pgr locationOfTouch:0 inView:self->view];
        CGPoint touch2 = [pgr locationOfTouch:1 inView:self->view];
        double slope = (touch2.y - touch1.y) / (touch2.x - touch1.x);
        if (fabs(slope) > 1)
        {
            return NO; // Do not recognize the gesture; touches do not represent two fingers placed horizontally.
        }
    }

    return YES;
}

- (void) gestureRecognizerDidBegin:(UIGestureRecognizer*)recognizer
{
    // Start the display link if it's not already running. We keep the current display link running rather than
    // restarting it in order to transition from an animation to a gesture without delay.
    [self startDisplayLink];

    // Navigator gestures stop any currently active animation. Cancel animations after starting the display link in
    // order to keep the display link running rather than restarting it.
    [self cancelAnimation];

    // Post a notification that the navigator has recognized a gesture. Do this last so that the navigator posts the
    // gesture recognized notification after any animation cancelled notifications.
    [self postGestureRecognized:recognizer];

}

- (void) gestureRecognizerDidEnd:(UIGestureRecognizer*)recognizer
{
    [self stopDisplayLink];
}

- (void) postGestureRecognized:(UIGestureRecognizer*)recognizer
{
    NSNotification* notification = [NSNotification notificationWithName:WW_NAVIGATOR_GESTURE_RECOGNIZED object:self];
    [[NSNotificationCenter defaultCenter] postNotification:notification];
}

- (void) beginAnimationWithLookAt:(WWLocation*)lookAt range:(double)range overDuration:(NSTimeInterval)duration
{
    // Move to animation's end values immediately when requested to do so.
    if (duration == WWNavigatorDurationImmediate)
    {
        // Cancel any currently active animation. This has no effect if there is no currently active animation.
        [self cancelAnimation];

        // Apply the animation's end values to the navigator's internal properties, posting an animation began and
        // animation ended notification before and after the change, respectively.
        [self postAnimationBegan];
        [_lookAt setLocation:lookAt];
        _range = range;
        [self postAnimationEnded];

        // Cause the World Wind view to redraw itself.  The view is a weak reference, but this has no effect if the view
        // has been deallocated.
        [view drawView];
        return;
    }

    [animBeginLookAt setLocation:_lookAt];
    [animEndLookAt setLocation:lookAt];

    animBeginRange = _range;
    animEndRange = range;

    // Compute the mid range used as an intermediate range during animation. If the begin and end locations are not
    // visible from the begin or end range, the mid range is defined as a value greater than the begin and end ranges.
    // This maintains the user's geographic context for the animation's beginning and end.
    WWPosition* pa = animBeginLookAt;
    WWPosition* pb = animEndLookAt;
    WWGlobe* globe = [[view sceneController] globe];
    CGRect viewport = [view viewport];
    double fitDistance = [WWMath eyeDistanceToFitPositionA:pa positionB:pb onGlobe:globe inViewport:viewport];
    animMidRange = (fitDistance > animBeginRange && fitDistance > animEndRange) ? fitDistance : DBL_MAX;

    // Compute the animation's begin and end date based on the implicit start time and the specified duration.
    NSTimeInterval defaultDuration = [WWMath durationForAnimationWithBeginPosition:pa endPosition:pb onGlobe:globe];
    NSTimeInterval animTimeInterval = (duration == WWNavigatorDurationDefault ? defaultDuration : duration);
    animBeginDate = [NSDate date];
    animEndDate = [NSDate dateWithTimeInterval:animTimeInterval sinceDate:animBeginDate];

    if (animating)
    {
        // Post an animation cancelled notification follow by an animation began notification if the navigator is
        // already animating.
        [self postAnimationCancelled];
        [self postAnimationBegan];
    }
    else
    {
        // Start the display link if the navigator is not already animating, and post an animation began notification.
        // We keep the current display link running rather than restarting it in order to transition from one animation
        // to the next without delay.
        [self startDisplayLink];
        [self postAnimationBegan];
        animating = YES;
    }
}

- (void) endAnimation
{
    if (animating)
    {
        [self stopDisplayLink];
        [self postAnimationEnded];
        animating = NO;
    }
}

- (void) cancelAnimation
{
    if (animating)
    {
        [self stopDisplayLink];
        [self postAnimationCancelled];
        animating = NO;
    }
}

- (void) updateAnimationForDate:(NSDate*)date
{
    NSTimeInterval beginTime = [animBeginDate timeIntervalSinceReferenceDate];
    NSTimeInterval endTime = [animEndDate timeIntervalSinceReferenceDate];
    NSTimeInterval midTime = (beginTime + endTime) / 2;
    NSTimeInterval now = [date timeIntervalSinceReferenceDate];

    if (now <= beginTime)
    {
        // The animation has yet to start or has just started. Explicitly set the current values to the specified begin
        // values rather than computing a interpolated values to ensure that the begin values are set exactly as the
        // caller requested.
        [_lookAt setLocation:animBeginLookAt];
        _range = animBeginRange;
    }
    else if (now >= endTime)
    {
        // The animation has reached its scheduled end based on the implicit start time and specified duration.
        // Explicitly set the current values to the specified end values rather than computing a interpolated values to
        // ensure that the end values are set exactly as the caller requested.
        [_lookAt setLocation:animEndLookAt];
        _range = animEndRange;
        [self endAnimation];
    }
    else
    {
        // The animation is currently between the implicit start time and specified duration. Compute the fraction of
        // time that has passed as a value between 0 and 1, then use the fraction to interpolate between the begin and
        // end values. This uses hermite interpolation via WWMath's smoothStepValue method to ease in and ease out of
        // the begin and end values, respectively.

        double locationPct = [WWMath smoothStepValue:now min:beginTime max:endTime];
        [WWLocation greatCircleInterpolate:animBeginLookAt endLocation:animEndLookAt
                                    amount:locationPct outputLocation:_lookAt];

        if (animMidRange == DBL_MAX) // The animation is not using a mid range value.
        {
            double rangePct = [WWMath smoothStepValue:now min:beginTime max:endTime];
            _range = [WWMath interpolateValue1:animBeginRange value2:animEndRange amount:rangePct];
        }
        else if (now <= midTime) // The animation is using a mid range value, and is in the first half of its duration.
        {
            double rangePct = [WWMath smoothStepValue:now min:beginTime max:midTime];
            _range = [WWMath interpolateValue1:animBeginRange value2:animMidRange amount:rangePct];
        }
        else // The animation is using a mid range value, and is in the second half of its duration.
        {
            double rangePct = [WWMath smoothStepValue:now min:midTime max:endTime];
            _range = [WWMath interpolateValue1:animMidRange value2:animEndRange amount:rangePct];
        }
    }
}

- (void) postAnimationBegan
{
    NSNotification* notification = [NSNotification notificationWithName:WW_NAVIGATOR_ANIMATION_BEGAN object:self];
    [[NSNotificationCenter defaultCenter] postNotification:notification];
}

- (void) postAnimationEnded
{
    NSNotification* notification = [NSNotification notificationWithName:WW_NAVIGATOR_ANIMATION_ENDED object:self];
    [[NSNotificationCenter defaultCenter] postNotification:notification];
}

- (void) postAnimationCancelled
{
    NSNotification* notification = [NSNotification notificationWithName:WW_NAVIGATOR_ANIMATION_CANCELLED object:self];
    [[NSNotificationCenter defaultCenter] postNotification:notification];
}

@end