/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.

 @version $Id$
 */

#import "WorldWind/Navigate/WWLookAtNavigator.h"
#import "WorldWind/Navigate/WWNavigatorState.h"
#import "WorldWind/Geometry/WWLine.h"
#import "WorldWind/Geometry/WWMatrix.h"
#import "WorldWind/Geometry/WWPosition.h"
#import "WorldWind/Geometry/WWVec4.h"
#import "WorldWind/Render/WWSceneController.h"
#import "WorldWind/Terrain/WWGlobe.h"
#import "WorldWind/Util/WWMath.h"
#import "WorldWind/WorldWindConstants.h"
#import "WorldWind/WorldWindView.h"
#import "WorldWind/WWLog.h"

#define DEFAULT_RANGE 10000000
#define DEFAULT_HEADING 0
#define DEFAULT_TILT 0
#define DEFAULT_ROLL 0

@implementation WWLookAtNavigator

//--------------------------------------------------------------------------------------------------------------------//
//-- Initializing Navigators --//
//--------------------------------------------------------------------------------------------------------------------//

- (WWLookAtNavigator*) initWithView:(WorldWindView*)view
{
    return [self initWithView:view navigatorToMatch:nil];
}

- (WWLookAtNavigator*) initWithView:(WorldWindView*)view navigatorToMatch:(id<WWNavigator>)navigator
{
    self = [super initWithView:view]; // Superclass validates the view argument.

    panGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePanFrom:)];
    pinchGestureRecognizer = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(handlePinchFrom:)];
    rotationGestureRecognizer = [[UIRotationGestureRecognizer alloc] initWithTarget:self action:@selector(handleRotationFrom:)];
    verticalPanGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handleVerticalPanFrom:)];

    // Gesture recognizers maintain a weak reference to their delegate.
    [panGestureRecognizer setDelegate:self];
    [pinchGestureRecognizer setDelegate:self];
    [rotationGestureRecognizer setDelegate:self];
    [verticalPanGestureRecognizer setDelegate:self];
    [verticalPanGestureRecognizer setMinimumNumberOfTouches:2];

    [view addGestureRecognizer:panGestureRecognizer];
    [view addGestureRecognizer:pinchGestureRecognizer];
    [view addGestureRecognizer:rotationGestureRecognizer];
    [view addGestureRecognizer:verticalPanGestureRecognizer];

    if (navigator != nil)
    {
        id<WWNavigatorState> currentState = [navigator currentState];
        NSDictionary* params = [self viewingParametersForModelview:[currentState modelview] rollDegrees:0]; // TODO: Get roll from navigator.
        _lookAtPosition = [params objectForKey:WW_ORIGIN];
        _range = [[params objectForKey:WW_RANGE] doubleValue];
        _heading = [[params objectForKey:WW_HEADING] doubleValue];
        _tilt = [[params objectForKey:WW_TILT] doubleValue];
        _roll = [[params objectForKey:WW_ROLL] doubleValue];
    }
    else
    {
        WWPosition* lastKnownPosition = [self lastKnownPosition];
        _lookAtPosition = [[WWPosition alloc] initWithLocation:lastKnownPosition altitude:0];
        _range = DEFAULT_RANGE; // TODO: Compute initial range to fit globe in viewport.
        _heading = DEFAULT_HEADING;
        _tilt = DEFAULT_TILT;
        _roll = DEFAULT_ROLL;
    }

    return self;
}

- (void) dispose
{
    [super dispose];

    // Remove gesture recognizers from the parent view when the navigator is de-allocated. The view is a weak reference,
    // so it may have been de-allocated. In this case it is unnecessary to remove these references.
    UIView* view = [self view];
    if (view != nil)
    {
        [view removeGestureRecognizer:panGestureRecognizer];
        [view removeGestureRecognizer:pinchGestureRecognizer];
        [view removeGestureRecognizer:rotationGestureRecognizer];
        [view removeGestureRecognizer:verticalPanGestureRecognizer];
    }
}

- (NSDictionary*) viewingParametersForModelview:(WWMatrix*)modelview rollDegrees:(double)roll
{
    WWGlobe* globe = [[[self view] sceneController] globe];
    WWVec4* lookAtPoint = [[WWVec4 alloc] initWithZeroVector];

    WWVec4* eyePoint = [modelview extractEyePoint];
    WWVec4* forward = [modelview extractForwardVector];
    WWLine* forwardRay = [[WWLine alloc] initWithOrigin:eyePoint direction:forward];

    if (![globe intersectWithRay:forwardRay result:lookAtPoint])
    {
        WWPosition* eyePos = [[WWPosition alloc] initWithZeroPosition];
        [globe computePositionFromPoint:[eyePoint x] y:[eyePoint y] z:[eyePoint z] outputPosition:eyePos];

        double globeRadius = MAX([globe equatorialRadius], [globe polarRadius]);
        double globeElevation = [globe elevationForLatitude:[eyePos latitude] longitude:[eyePos longitude]];
        double heightAboveSurface = [eyePos altitude] - globeElevation;
        double horizonDistance = [WWMath horizonDistanceForGlobeRadius:globeRadius eyeAltitude:heightAboveSurface];

        [forwardRay pointAt:horizonDistance result:lookAtPoint];
    }

    return [modelview extractViewingParameters:lookAtPoint forRollDegrees:roll onGlobe:globe];

}

//--------------------------------------------------------------------------------------------------------------------//
//-- Getting a Navigator State Snapshot --//
//--------------------------------------------------------------------------------------------------------------------//

- (id<WWNavigatorState>) currentState
{
    // Compute the current modelview matrix based on this navigator's look-at position, range, heading, and tilt.
    WWGlobe* globe = [[[self view] sceneController] globe];
    WWMatrix* modelview = [[WWMatrix alloc] initWithIdentity];
    [modelview multiplyByLookAtModelview:_lookAtPosition
                                   range:_range
                          headingDegrees:_heading
                             tiltDegrees:_tilt
                             rollDegrees:_roll
                                 onGlobe:globe];

    return [self currentStateForModelview:modelview];
}

//--------------------------------------------------------------------------------------------------------------------//
//-- Animating to a Location of Interest --//
//--------------------------------------------------------------------------------------------------------------------//

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

    WWPosition* lookAtPosition = [[WWPosition alloc] initWithLocation:location altitude:0];

    [self gotoLookAtPosition:lookAtPosition
                       range:_range
              headingDegrees:_heading
                 tiltDegrees:_tilt
                 rollDegrees:_roll
                overDuration:duration];
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

    CGRect viewport = [[self view] viewport];
    double range = [WWMath perspectiveFitDistance:viewport forObjectWithRadius:radius];
    WWPosition* lookAtPosition = [[WWPosition alloc] initWithLocation:center altitude:0];

    [self gotoLookAtPosition:lookAtPosition
                       range:range
              headingDegrees:_heading
                 tiltDegrees:0
                 rollDegrees:_roll
                overDuration:duration];
}

- (void) gotoLookAtPosition:(WWPosition*)lookAtPosition
                      range:(double)range
               overDuration:(NSTimeInterval)duration
{
    if (lookAtPosition == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Look at position is nil")
    }

    if (duration < 0)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Duration is invalid")
    }

    [self gotoLookAtPosition:lookAtPosition
                       range:range
              headingDegrees:_heading
                 tiltDegrees:_tilt
                 rollDegrees:_roll
                overDuration:duration];
}

- (void) gotoLookAtPosition:(WWPosition*)lookAtPosition
                      range:(double)range
             headingDegrees:(double)heading
                tiltDegrees:(double)tilt
                rollDegrees:(double)roll
               overDuration:(NSTimeInterval)duration;
{

    if (lookAtPosition == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Look at position is nil")
    }

    if (duration < 0)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Duration is invalid")
    }

    // Store the animation's begin and end values for this navigator's attributes. These values are interpolated in
    // animationDidUpdate:begin:end.
    animBeginLookAt = [[WWPosition alloc] initWithPosition:_lookAtPosition];
    animEndLookAt = [[WWPosition alloc] initWithPosition:lookAtPosition];
    animBeginRange = _range;
    animEndRange = range;
    animBeginHeading = _heading;
    animEndHeading = heading;
    animBeginTilt = _tilt;
    animEndTilt = tilt;
    animBeginRoll = _roll;
    animEndRoll = roll;

    // Compute the mid range used as an intermediate range during animation. If the begin and end locations on the
    // globe's surface are not visible from the begin or end range, the mid range is defined as a value greater than the
    // begin and end ranges. This maintains the user's geographic context for the animation's beginning and end.
    WorldWindView* view = [self view];
    WWPosition* pa = animBeginLookAt;
    WWPosition* pb = animEndLookAt;
    WWGlobe* globe = [[view sceneController] globe];
    CGRect viewport = [view viewport];
    double fitDistance = [WWMath perspectiveFitDistance:viewport forPositionA:pa positionB:pb onGlobe:globe];
    animMidRange = (fitDistance > animBeginRange && fitDistance > animEndRange) ? fitDistance : DBL_MAX;

    // Compute the animation's duration when necessary. The caller may specify a duration of WWNavigatorDurationDefault
    // to indicate that the navigator compute a default duration based on the begin and end values. This uses a hybrid
    // of the begin and end locations and ranges in order to factor the change in both attributes into the duration.
    pa = [[WWPosition alloc] initWithLocation:animBeginLookAt altitude:animBeginRange];
    pb = [[WWPosition alloc] initWithLocation:animEndLookAt altitude:animEndRange];
    NSTimeInterval defaultDuration = [WWMath durationForAnimationWithBeginPosition:pa endPosition:pb onGlobe:globe];
    NSTimeInterval animDuration = (duration == WWNavigatorDurationDefault ? defaultDuration : duration);

    // Cancel any currently active animation and begin a new animation with the values and duration computed above.
    [self cancelAnimation];
    [super beginAnimationWithDuration:animDuration];
}

- (void) animationDidBegin
{
    [super animationDidBegin];

    // The animation has just begun. Explicitly set the begin values rather than interpolating to ensure that the begin
    // values are set exactly as the caller requested.
    [_lookAtPosition setLocation:animBeginLookAt];
    _range = animBeginRange;
    _heading = animBeginHeading;
    _tilt = animBeginTilt;
    _roll = animBeginRoll;
}

- (void) animationDidEnd
{
    [super animationDidEnd];

    // The animation has ended. Explicitly set the end values rather than interpolating to ensure that the end values
    // are set exactly as the caller requested.
    [_lookAtPosition setLocation:animEndLookAt];
    _range = animEndRange;
    _heading = animEndHeading;
    _tilt = animEndTilt;
    _roll = animEndRoll;
}

- (void) animationDidUpdate:(NSDate*)date begin:(NSDate*)begin end:(NSDate*)end
{
    NSTimeInterval now = [date timeIntervalSinceReferenceDate];
    NSTimeInterval beginTime = [begin timeIntervalSinceReferenceDate];
    NSTimeInterval endTime = [end timeIntervalSinceReferenceDate];
    NSTimeInterval midTime = (beginTime + endTime) / 2;

    // The animation is between the start time and the end time. Compute the fraction of time that has passed as a value
    // between 0 and 1, then use the fraction to interpolate between the begin and end values. This uses hermite
    // interpolation via [WWMath smoothStepValue] to ease in and ease out of the begin and end values, respectively.

    double animationPct = [WWMath smoothStepValue:now min:beginTime max:endTime];
    [WWPosition greatCircleInterpolate:animBeginLookAt endPosition:animEndLookAt
                                amount:animationPct outputPosition:_lookAtPosition];

    if (animMidRange == DBL_MAX) // The animation is not using a mid range value.
    {
        _range = [WWMath interpolateValue1:animBeginRange value2:animEndRange amount:animationPct];
    }
    else if (now <= midTime) // The animation is using a mid range value, and is in the first half of its duration.
    {
        double firstHalfPct = [WWMath smoothStepValue:now min:beginTime max:midTime];
        _range = [WWMath interpolateValue1:animBeginRange value2:animMidRange amount:firstHalfPct];
    }
    else // The animation is using a mid range value, and is in the second half of its duration.
    {
        double secondHalfPct = [WWMath smoothStepValue:now min:midTime max:endTime];
        _range = [WWMath interpolateValue1:animMidRange value2:animEndRange amount:secondHalfPct];
    }

    _heading = [WWMath interpolateValue1:animBeginHeading value2:animEndHeading amount:animationPct];
    _tilt = [WWMath interpolateValue1:animBeginTilt value2:animEndTilt amount:animationPct];
    _roll = [WWMath interpolateValue1:animBeginRoll value2:animEndRoll amount:animationPct];
}

//--------------------------------------------------------------------------------------------------------------------//
//-- Gesture Recognizer Interface for Subclasses --//
//--------------------------------------------------------------------------------------------------------------------//

- (void) handlePanFrom:(UIPanGestureRecognizer*)recognizer
{
    // Apply the translation of the pan gesture to this navigator's look-at position. We convert the pan translation
    // from screen pixels to arc degrees in order to provide a translation that is appropriate for the current eye
    // position. In order to convert from pixels to arc degrees we assume that this navigator's range represents the
    // distance that the gesture is intended for. The translation is applied incrementally so that simultaneously
    // applied heading changes are correctly integrated into the navigator's current location.

    // Note: the view property is a weak reference, so it may have been de-allocated. In this case the contents of the
    // CG structures below will be undefined. However, the view's gesture recognizers will not be sent any messages
    // after the view itself is de-allocated.

    UIGestureRecognizerState state = [recognizer state];

    if (state == UIGestureRecognizerStateBegan)
    {
        lastPanTranslation = CGPointMake(0, 0);
        [self gestureRecognizerDidBegin:recognizer];
    }
    else if (state == UIGestureRecognizerStateEnded || state == UIGestureRecognizerStateCancelled)
    {
        [self gestureRecognizerDidEnd:recognizer];
    }
    else if (state == UIGestureRecognizerStateChanged)
    {
        // Compute the translation in the view's local coordinate system.
        CGPoint panTranslation = [recognizer translationInView:[recognizer view]];
        double dx = panTranslation.x - lastPanTranslation.x;
        double dy = panTranslation.y - lastPanTranslation.y;
        lastPanTranslation = panTranslation;

        // Convert the translation from the view's local coordinate system to meters, assuming the translation is
        // intended for an object that is 'range' meters away form the eye position. Convert from change in screen
        // relative coordinates to change in model relative coordinates by inverting the change in X. There is no need
        // to invert the change in Y because the Y axis coordinates are already inverted.
        CGRect viewport = [[self view] viewport];
        double distance = MAX(1, _range);
        double metersPerPixel = [WWMath perspectivePixelSize:viewport atDistance:distance];
        double forwardMeters = dy * metersPerPixel;
        double sideMeters = -dx * metersPerPixel;

        // Convert the translation from meters to arc degrees. The globe's radius provides the necessary context to
        // perform this conversion.
        WWGlobe* globe = [[[self view] sceneController] globe];
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
        double newLat = [WWMath clampValue:([_lookAtPosition latitude] + latDegrees) min:-90 max:90];
        double newLon = NormalizedDegreesLongitude([_lookAtPosition longitude] + lonDegrees);
        [_lookAtPosition setDegreesLatitude:newLat longitude:newLon];
    }
    else
    {
        WWLog(@"Unknown gesture recognizer state: %d", state);
    }
}

- (void) handlePinchFrom:(UIPinchGestureRecognizer*)recognizer
{
    // Apply the inverse of the pinch gesture's scale to this navigator's range. Pinch-in gestures move the eye position
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
        gestureBeginRange = _range;
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
            _range = gestureBeginRange / scale;
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
        gestureBeginHeading = _heading;
        [self gestureRecognizerDidBegin:recognizer];
    }
    else if (state == UIGestureRecognizerStateEnded || state == UIGestureRecognizerStateCancelled)
    {
        [self gestureRecognizerDidEnd:recognizer];
    }
    else if (state == UIGestureRecognizerStateChanged)
    {
        double headingDegrees = DEGREES(-[recognizer rotation]);
        _heading = NormalizedDegreesHeading(gestureBeginHeading + headingDegrees);
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
        gestureBeginTilt = _tilt;
        [self gestureRecognizerDidBegin:recognizer];
    }
    else if (state == UIGestureRecognizerStateEnded || state == UIGestureRecognizerStateCancelled)
    {
        [self gestureRecognizerDidEnd:recognizer];
    }
    else if (state == UIGestureRecognizerStateChanged)
    {
        UIView* view = [recognizer view];
        CGPoint translation = [recognizer translationInView:view];
        CGRect bounds = [view bounds];

        double tiltDegrees = 90 * translation.y / CGRectGetHeight(bounds);
        _tilt = [WWMath clampValue:gestureBeginTilt + tiltDegrees min:0 max:90];
    }
    else
    {
        WWLog(@"Unknown gesture recognizer state: %d", state);
    }
}

- (BOOL) gestureRecognizer:(UIGestureRecognizer*)recognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer*)otherRecognizer
{
    if (recognizer == panGestureRecognizer)
    {
        return otherRecognizer == pinchGestureRecognizer || otherRecognizer == rotationGestureRecognizer;
    }
    else if (recognizer == pinchGestureRecognizer)
    {
        return otherRecognizer == panGestureRecognizer || otherRecognizer == rotationGestureRecognizer;
    }
    else if (recognizer == rotationGestureRecognizer)
    {
        return otherRecognizer == panGestureRecognizer || otherRecognizer == pinchGestureRecognizer;
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
    if (recognizer == verticalPanGestureRecognizer)
    {
        UIPanGestureRecognizer* pgr = (UIPanGestureRecognizer*) recognizer;
        UIView* view = [recognizer view];

        CGPoint translation = [pgr translationInView:view];
        if (fabs(translation.x) > fabs(translation.y))
        {
            return NO; // Do not recognize the gesture; the pan is horizontal.
        }

        NSUInteger numTouches = [pgr numberOfTouches];
        if (numTouches < 2)
        {
            return NO; // Do not recognize the gesture; not enough touches.
        }

        CGPoint touch1 = [pgr locationOfTouch:0 inView:view];
        CGPoint touch2 = [pgr locationOfTouch:1 inView:view];
        double slope = (touch2.y - touch1.y) / (touch2.x - touch1.x);
        if (fabs(slope) > 1)
        {
            return NO; // Do not recognize the gesture; touches do not represent two fingers placed horizontally.
        }
    }

    return YES;
}

@end