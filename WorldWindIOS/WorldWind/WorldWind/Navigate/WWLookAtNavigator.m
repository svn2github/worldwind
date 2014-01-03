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
    panPinchRotationGestureRecognizers = [NSArray arrayWithObjects:panGestureRecognizer, pinchGestureRecognizer, rotationGestureRecognizer, nil];

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
        // Convert the other navigator's modelview matrix and roll to parameters appropriate for this navigator. A
        // navigator's roll is assumed to apply to the vector coming out of the screen and therefore is the only
        // parameter that can be exchanged directly between navigators. Knowing the roll enables this conversion to
        // disambiguate between heading and roll when the navigator is looking straight down.
        id<WWNavigatorState> currentState = [navigator currentState];
        double roll = [navigator roll];
        NSDictionary* params = [self viewingParametersForModelview:[currentState modelview] rollDegrees:roll];
        _lookAtPosition = [params objectForKey:WW_ORIGIN];
        _range = [[params objectForKey:WW_RANGE] doubleValue];
        [self setHeading:[[params objectForKey:WW_HEADING] doubleValue]];
        [self setTilt:[[params objectForKey:WW_TILT] doubleValue]];
        [self setRoll:[[params objectForKey:WW_ROLL] doubleValue]];
    }
    else
    {
        WWPosition* lastKnownPosition = [self lastKnownPosition];
        _lookAtPosition = [[WWPosition alloc] initWithLocation:lastKnownPosition altitude:0];
        _range = DEFAULT_RANGE; // TODO: Compute initial range to fit globe in viewport.
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

- (void) setLookAtPosition:(WWPosition*)lookAtPosition
{
    if (lookAtPosition == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Look-at position is nil")
    }

    [_lookAtPosition setPosition:lookAtPosition];
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
                          headingDegrees:[self heading]
                             tiltDegrees:[self tilt]
                             rollDegrees:[self roll]
                                 onGlobe:globe];

    return [self currentStateForModelview:modelview];
}

//--------------------------------------------------------------------------------------------------------------------//
//-- Setting the Location of Interest --//
//--------------------------------------------------------------------------------------------------------------------//

- (void) setCenterLocation:(WWLocation*)location
{
    if (location == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Location is nil")
    }

    [_lookAtPosition setLocation:location];
}

- (void) setCenterLocation:(WWLocation*)location radius:(double)radius
{
    if (location == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Location is nil")
    }

    if (radius < 0)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Radius is invalid");
    }

    CGRect viewport = [[self view] viewport];
    [_lookAtPosition setLocation:location];
    _range = [WWMath perspectiveFitDistance:viewport forObjectWithRadius:radius];
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

        // Convert the translation from screen coordinates to meters, assuming the translation is intended for an object
        // that is 'range' meters away form the eye position. Use the view bounds instead of the viewport to maintain
        // the same screen coordinates used by the translation values. Convert from change in screen relative
        // coordinates to change in model relative coordinates by inverting the change in X. There is no need to invert
        // the change in Y because the Y axis coordinates are already inverted.
        CGRect bounds = [[self view] bounds];
        double distance = MAX(1, _range);
        double metersPerPixel = [WWMath perspectivePixelSize:bounds atDistance:distance];
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
        double sinHeading = sin(RADIANS([self heading]));
        double cosHeading = cos(RADIANS([self heading]));
        double latDegrees = forwardDegrees * cosHeading - sideDegrees * sinHeading;
        double lonDegrees = forwardDegrees * sinHeading + sideDegrees * cosHeading;

        // Apply the change in latitude and longitude to this navigator's lookAt property. Limit the new latitude to the
        // range (-90, 90) in order to stop the forward movement at the pole. Panning over the pole requires a
        // corresponding change in heading, which has not been implemented here in favor of simplicity.
        double newLat = [WWMath clampValue:([_lookAtPosition latitude] + latDegrees) min:-90 max:90];
        double newLon = [WWMath normalizeDegreesLongitude:[_lookAtPosition longitude] + lonDegrees];
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
        gestureBeginHeading = [self heading];
        [self gestureRecognizerDidBegin:recognizer];
    }
    else if (state == UIGestureRecognizerStateEnded || state == UIGestureRecognizerStateCancelled)
    {
        [self gestureRecognizerDidEnd:recognizer];
    }
    else if (state == UIGestureRecognizerStateChanged)
    {
        double headingDegrees = DEGREES(-[recognizer rotation]);
        [self setHeading:[WWMath normalizeDegrees:gestureBeginHeading + headingDegrees]];
    }
    else
    {
        WWLog(@"Unknown gesture recognizer state: %d", state);
    }
}

- (void) handleVerticalPanFrom:(UIPanGestureRecognizer*)recognizer
{
    UIGestureRecognizerState state = [recognizer state];

    if (state == UIGestureRecognizerStateBegan)
    {
        gestureBeginTilt = [self tilt];
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
        [self setTilt:[WWMath clampValue:gestureBeginTilt + tiltDegrees min:0 max:90]];
    }
    else
    {
        WWLog(@"Unknown gesture recognizer state: %d", state);
    }
}

- (BOOL) gestureRecognizer:(UIGestureRecognizer*)recognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer*)otherRecognizer
{
    // Determine whether the two gesture recognizers should simultaneously recognizer their gestures. This navigator's
    // pan pinch and rotation gesture recognizers are intended to execute simultaneously, yet be mutually exclusive of
    // all other gestures. We implement the methods of UIGestureRecognizerDelegate to ensure that only the appropriate
    // gesture recognizers execute simultaneously.

    return [panPinchRotationGestureRecognizers containsObject:recognizer]
        && [panPinchRotationGestureRecognizers containsObject:otherRecognizer];
}

- (BOOL) gestureRecognizerShouldBegin:(UIGestureRecognizer*)recognizer
{
    // Determine whether the two pan gesture recognizers should recognizer their gestures. These gestures are intended
    // to be mutually exclusive, yet verticalPanGestureRecognizer is essentially a subset of panGestureRecognizer. We
    // implement the methods of UIGestureRecognizerDelegate to ensure that the appropriate pan gesture recognizer begins
    // regardless of which gets the first opportunity to recognize a gesture.

    if (recognizer == panGestureRecognizer)
    {
        UIGestureRecognizerState pinchState = [pinchGestureRecognizer state];
        UIGestureRecognizerState rotationState = [rotationGestureRecognizer state];

        // Begin the standard pan gesture when either the of the pinch or rotation gestures have been recognized, which
        // implicitly prevents the vertical pan gesture from being recognized. If either of these gestures have
        // transitioned to a recognized state then the vertical pan gesture will be prevented from recognizing by this
        // navigator's implementation of [gestureRecognizer:shouldRecognizeSimultaneouslyWithGestureRecognizer:].
        if (pinchState == UIGestureRecognizerStateBegan || pinchState == UIGestureRecognizerStateChanged
            || rotationState == UIGestureRecognizerStateBegan || rotationState == UIGestureRecognizerStateChanged)
        {
            return YES;
        }

        // Otherwise, begin the standard pan gesture only when the gesture does not meet the necessary criteria for a
        // vertical pan gesture.
        return ![self gestureRecognizerIsVerticalPan:panGestureRecognizer];
    }
    else if (recognizer == verticalPanGestureRecognizer)
    {
        // Begin the vertical pan gesture only when the gesture meets the necessary criteria. This assumes that none of
        // the standard pan, pinch or rotation gestures have been recognized. This navigator's implementation of
        // [gestureRecognizer:shouldRecognizeSimultaneouslyWithGestureRecognizer:] prevents the vertical pan from
        // exiting the possible state.
        return [self gestureRecognizerIsVerticalPan:verticalPanGestureRecognizer];
    }
    else
    {
        return YES; // Return the default (YES) for all other gesture recognizers.
    }
}

- (BOOL) gestureRecognizerIsVerticalPan:(UIPanGestureRecognizer*)recognizer
{
    NSUInteger numTouches = [recognizer numberOfTouches];
    if (numTouches < 2)
    {
        return NO; // Do not recognize the gesture; not enough touches.
    }

    UIView* view = [recognizer view];
    CGPoint translation = [recognizer translationInView:view];
    if (fabs(translation.x) > fabs(translation.y))
    {
        return NO; // Do not recognize the gesture; the pan is horizontal.
    }

    CGPoint touch1 = [recognizer locationOfTouch:0 inView:view];
    CGPoint touch2 = [recognizer locationOfTouch:1 inView:view];
    double slope = (touch2.y - touch1.y) / (touch2.x - touch1.x);
    if (fabs(slope) > 1)
    {
        return NO; // Do not recognize the gesture; touches do not represent two fingers placed horizontally.
    }

    return YES;
}

//--------------------------------------------------------------------------------------------------------------------//
//-- Animation Interface for Subclasses --//
//--------------------------------------------------------------------------------------------------------------------//

- (void) setupAnimationWithDuration:(NSTimeInterval)duration animations:(void (^)(void))animations
{
    NSDate* now = [NSDate date];

    // Capture the begin state of the navigator's animatable properties by storing their current values. These values
    // are interpolated in doUpdateAnimation:.
    animBeginLookAt = [[WWPosition alloc] initWithPosition:_lookAtPosition];
    animBeginRange = _range;
    animBeginHeading = [self heading];
    animBeginTilt = [self tilt];
    animBeginRoll = [self roll];

    // Capture the end state of the navigator's animatable properties by storing their values after invoking the
    // caller-specified animation block. These values are interpolated in doUpdateAnimation:.
    animations();
    animEndLookAt = [[WWPosition alloc] initWithPosition:_lookAtPosition];
    animEndRange = _range;
    animEndHeading = [self heading];
    animEndTilt = [self tilt];
    animEndRoll = [self roll];

    // Restore the navigator's animatable properties to their begin values.
    [_lookAtPosition setPosition:animBeginLookAt];
    _range = animBeginRange;
    [self setHeading:animBeginHeading];
    [self setTilt:animBeginTilt];
    [self setRoll:animBeginRoll];

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

    // Compute the animation's duration when necessary based on the begin and end values. This uses a hybrid of the
    // begin and end locations and ranges in order to factor the change in both location and altitude into the duration.
    if (duration == WWNavigatorDurationAutomatic)
    {
        pa = [[WWPosition alloc] initWithLocation:animBeginLookAt altitude:animBeginRange];
        pb = [[WWPosition alloc] initWithLocation:animEndLookAt altitude:animEndRange];
        duration = [WWMath perspectiveAnimationDuration:viewport forPositionA:pa positionB:pb onGlobe:globe];
    }

    animationBeginDate = now;
    animationEndDate = [NSDate dateWithTimeInterval:duration sinceDate:now];
}

- (void) doUpdateAnimation:(NSDate*)timestamp
{
    NSTimeInterval now = [timestamp timeIntervalSinceReferenceDate];
    NSTimeInterval beginTime = [animationBeginDate timeIntervalSinceReferenceDate];
    NSTimeInterval endTime = [animationEndDate timeIntervalSinceReferenceDate];
    NSTimeInterval midTime = (beginTime + endTime) / 2;

    if (now > beginTime && now < endTime) // The animation is between the start time and the end time.
    {
        // Compute the fraction of time that has passed as a value between 0 and 1, then use the fraction to interpolate
        // between the begin and end values. This uses hermite interpolation via [WWMath smoothStepValue] to ease in and
        // ease out of the begin and end values, respectively.

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

        [self setHeading:[WWMath interpolateDegrees1:animBeginHeading degrees2:animEndHeading amount:animationPct]];
        [self setTilt:[WWMath interpolateDegrees1:animBeginTilt degrees2:animEndTilt amount:animationPct]];
        [self setRoll:[WWMath interpolateDegrees1:animBeginRoll degrees2:animEndRoll amount:animationPct]];
    }
    else if (now >= endTime) // The animation has reached its scheduled end.
    {
        // Explicitly set the end values rather than interpolating to ensure that the end values are set exactly as the
        // caller requested.
        [_lookAtPosition setPosition:animEndLookAt];
        _range = animEndRange;
        [self setHeading:animEndHeading];
        [self setTilt:animEndTilt];
        [self setRoll:animEndRoll];

        // Stop the animation display link and invoke the completion block, if any.
        [self endAnimation:YES];
    }
}

@end