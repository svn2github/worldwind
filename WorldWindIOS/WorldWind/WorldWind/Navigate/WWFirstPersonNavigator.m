/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.

 @version $Id$
 */

#import "WorldWind/Navigate/WWFirstPersonNavigator.h"
#import "WorldWind/Navigate/WWNavigatorState.h"
#import "WorldWind/Geometry/WWLine.h"
#import "WorldWind/Geometry/WWMatrix.h"
#import "WorldWind/Geometry/WWPosition.h"
#import "WorldWind/Geometry/WWVec4.h"
#import "WorldWind/Render/WWSceneController.h"
#import "WorldWind/Terrain/WWGlobe.h"
#import "WorldWind/Util/WWMath.h"
#import "WorldWind/WorldWindView.h"
#import "WorldWind/WorldWindConstants.h"
#import "WorldWind/WWLog.h"

#define DEFAULT_ALTITUDE 10000000
#define TWO_FINGER_PAN_MAX_SLOPE 2

@implementation WWFirstPersonNavigator

//--------------------------------------------------------------------------------------------------------------------//
//-- Initializing Navigators --//
//--------------------------------------------------------------------------------------------------------------------//

- (WWFirstPersonNavigator*) initWithView:(WorldWindView*)view
{
    return [self initWithView:view navigatorToMatch:nil];
}

- (WWFirstPersonNavigator*) initWithView:(WorldWindView*)view navigatorToMatch:(id<WWNavigator>)navigator
{
    self = [super initWithView:view]; // Superclass validates the view argument.

    panGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePanFrom:)];
    pinchGestureRecognizer = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(handlePinchFrom:)];
    rotationGestureRecognizer = [[UIRotationGestureRecognizer alloc] initWithTarget:self action:@selector(handleRotationFrom:)];
    twoFingerPanGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handleTwoFingerPanFrom:)];

    // Gesture recognizers maintain a weak reference to their delegate.
    [panGestureRecognizer setDelegate:self];
    [panGestureRecognizer setMaximumNumberOfTouches:1];
    [pinchGestureRecognizer setDelegate:self];
    [rotationGestureRecognizer setDelegate:self];
    [twoFingerPanGestureRecognizer setDelegate:self];
    [twoFingerPanGestureRecognizer setMinimumNumberOfTouches:2];

    [view addGestureRecognizer:panGestureRecognizer];
    [view addGestureRecognizer:pinchGestureRecognizer];
    [view addGestureRecognizer:rotationGestureRecognizer];
    [view addGestureRecognizer:twoFingerPanGestureRecognizer];

    if (navigator != nil)
    {
        // Convert the other navigator's modelview matrix and roll to parameters appropriate for this navigator. A
        // navigator's roll is assumed to apply to the vector coming out of the screen and therefore is the only
        // parameter that can be exchanged directly between navigators. Knowing the roll enables this conversion to
        // disambiguate between heading and roll when the navigator is looking straight down.
        id<WWNavigatorState> currentState = [navigator currentState];
        double roll = [navigator roll];
        NSDictionary* params = [self viewingParametersForModelview:[currentState modelview] rollDegrees:roll];
        _eyePosition = [params objectForKey:WW_ORIGIN];
        [self setHeading:[[params objectForKey:WW_HEADING] doubleValue]];
        [self setTilt:[[params objectForKey:WW_TILT] doubleValue]];
        [self setRoll:[[params objectForKey:WW_ROLL] doubleValue]];
    }
    else
    {
        WWPosition* lastKnownPosition = [self lastKnownPosition];
        _eyePosition = [[WWPosition alloc] initWithLocation:lastKnownPosition altitude:DEFAULT_ALTITUDE]; // TODO: Compute initial altitude to fit globe in viewport.
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
        [view removeGestureRecognizer:twoFingerPanGestureRecognizer];
    }
}

- (NSDictionary*) viewingParametersForModelview:(WWMatrix*)modelview rollDegrees:(double)roll
{
    WWGlobe* globe = [[[self view] sceneController] globe];
    WWVec4* eyePoint = [modelview extractEyePoint];

    return [modelview extractViewingParameters:eyePoint forRollDegrees:roll onGlobe:globe];
}

- (NSDictionary*) viewingParametersForLookAt:(WWPosition*)lookAt range:(double*)range rollDegrees:(double)roll
{
    WWGlobe* globe = [[[self view] sceneController] globe];
    WWVec4* lookAtPoint = [[WWVec4 alloc] initWithZeroVector];
    id<WWNavigatorState> currentState = [self currentState];

    if ([globe intersectWithRay:[currentState forwardRay] result:lookAtPoint])
    {
        WWMatrix* modelview = [[WWMatrix alloc] initWithMatrix:[currentState modelview]];
        NSDictionary* params = [modelview extractViewingParameters:lookAtPoint forRollDegrees:roll onGlobe:globe];
        double lookAtRange = (range != NULL ? *range : [[params valueForKey:WW_RANGE] doubleValue]);

        [modelview setToIdentity];
        [modelview multiplyByLookAtModelview:lookAt
                                       range:lookAtRange
                              headingDegrees:[[params objectForKey:WW_HEADING] doubleValue]
                                 tiltDegrees:[[params objectForKey:WW_TILT] doubleValue]
                                 rollDegrees:[[params objectForKey:WW_ROLL] doubleValue]
                                     onGlobe:globe];

        WWVec4* eyePoint = [modelview extractEyePoint];
        return [modelview extractViewingParameters:eyePoint forRollDegrees:roll onGlobe:globe];
    }
    else
    {
        WWLocation* eyeLocation = lookAt;
        double eyeAltitude = (range != NULL ? ([lookAt altitude] + *range) : [_eyePosition altitude]);
        WWPosition* eyePos = [[WWPosition alloc] initWithLocation:eyeLocation altitude:eyeAltitude];

        return [NSDictionary dictionaryWithObjectsAndKeys:
                eyePos, WW_ORIGIN,
                @([self heading]), WW_HEADING,
                @(0), WW_TILT,
                @(roll), WW_ROLL,
                nil];
    }
}

//--------------------------------------------------------------------------------------------------------------------//
//-- Getting a Navigator State Snapshot --//
//--------------------------------------------------------------------------------------------------------------------//

- (id<WWNavigatorState>) currentState
{
    // Compute the current modelview matrix based on this navigator's eye position, heading, and tilt.
    WWGlobe* globe = [[[self view] sceneController] globe];
    WWMatrix* modelview = [[WWMatrix alloc] initWithIdentity];
    [modelview multiplyByFirstPersonModelview:_eyePosition
                               headingDegrees:[self heading]
                                  tiltDegrees:[self tilt]
                                  rollDegrees:[self roll]
                                      onGlobe:globe];

    return [self currentStateForModelview:modelview];
}

//--------------------------------------------------------------------------------------------------------------------//
//-- Setting the Location of Interest --//
//--------------------------------------------------------------------------------------------------------------------//

- (void) setToPosition:(WWPosition*)position
{
    if (position == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Position is nil")
    }

    NSDictionary* params = [self viewingParametersForLookAt:position range:nil rollDegrees:[self roll]];
    _eyePosition = [params objectForKey:WW_ORIGIN];
    [self setHeading:[[params objectForKey:WW_HEADING] doubleValue]];
    [self setTilt:[[params objectForKey:WW_TILT] doubleValue]];
    [self setRoll:[[params objectForKey:WW_ROLL] doubleValue]];
}

- (void) setToRegionWithCenter:(WWPosition*)center radius:(double)radius
{
    if (center == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Center is nil")
    }

    if (radius < 0)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Radius is invalid");
    }

    CGRect viewport = [[self view] viewport];
    double range = [WWMath perspectiveFitDistance:viewport forObjectWithRadius:radius];

    NSDictionary* params = [self viewingParametersForLookAt:center range:&range rollDegrees:[self roll]];
    _eyePosition = [params objectForKey:WW_ORIGIN];
    [self setHeading:[[params objectForKey:WW_HEADING] doubleValue]];
    [self setTilt:[[params objectForKey:WW_TILT] doubleValue]];
    [self setRoll:[[params objectForKey:WW_ROLL] doubleValue]];
}

- (void) animateToPosition:(WWPosition*)position overDuration:(NSTimeInterval)duration
{
    if (position == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Position is nil")
    }

    if (duration < 0)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Duration is invalid")
    }

    NSDictionary* params = [self viewingParametersForLookAt:position range:nil rollDegrees:[self roll]];
    [self animateToEyePosition:[params objectForKey:WW_ORIGIN]
                headingDegrees:[[params objectForKey:WW_HEADING] doubleValue]
                   tiltDegrees:[[params objectForKey:WW_TILT] doubleValue]
                   rollDegrees:[[params objectForKey:WW_ROLL] doubleValue]
                  overDuration:duration];
}

- (void) animateToRegionWithCenter:(WWPosition*)center radius:(double)radius overDuration:(NSTimeInterval)duration
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

    NSDictionary* params = [self viewingParametersForLookAt:center range:&range rollDegrees:[self roll]];
    [self animateToEyePosition:[params objectForKey:WW_ORIGIN]
                headingDegrees:[[params objectForKey:WW_HEADING] doubleValue]
                   tiltDegrees:[[params objectForKey:WW_TILT] doubleValue]
                   rollDegrees:[[params objectForKey:WW_ROLL] doubleValue]
                  overDuration:duration];
}

- (void) animateToEyePosition:(WWPosition*)eyePosition
                 overDuration:(NSTimeInterval)duration
{
    if (eyePosition == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Eye position is nil")
    }

    if (duration < 0)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Duration is invalid")
    }

    [self animateToEyePosition:eyePosition
                headingDegrees:[self heading]
                   tiltDegrees:[self tilt]
                   rollDegrees:[self roll]
                  overDuration:duration];
}

- (void) animateToEyePosition:(WWPosition*)eyePosition
               headingDegrees:(double)heading
                  tiltDegrees:(double)tilt
                  rollDegrees:(double)roll
                 overDuration:(NSTimeInterval)duration
{
    if (eyePosition == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Eye position is nil")
    }

    if (duration < 0)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Duration is invalid")
    }

    // Store the animation's begin and end values for this navigator's attributes. These values are interpolated in
    // animationDidUpdate:begin:end.
    animBeginLocation = [[WWLocation alloc] initWithLocation:_eyePosition];
    animEndLocation = [[WWLocation alloc] initWithLocation:eyePosition];
    animBeginAltitude = [_eyePosition altitude];
    animEndAltitude = [eyePosition altitude];
    animBeginHeading = [self heading];
    animEndHeading = heading;
    animBeginTilt = [self tilt];
    animEndTilt = tilt;
    animBeginRoll = [self roll];
    animEndRoll = roll;

    // Compute the mid range used as an intermediate range during animation. If the begin and end locations on the
    // globe's surface are not visible from the begin or end range, the mid range is defined as a value greater than the
    // begin and end ranges. This maintains the user's geographic context for the animation's beginning and end.
    WorldWindView* view = [self view];
    WWPosition* pa = _eyePosition;
    WWPosition* pb = eyePosition;
    WWGlobe* globe = [[view sceneController] globe];
    CGRect viewport = [view viewport];
    double fitDistance = [WWMath perspectiveFitDistance:viewport forPositionA:pa positionB:pb onGlobe:globe];
    animMidAltitude = (fitDistance > [pa altitude] && fitDistance > [pb altitude]) ? fitDistance : DBL_MAX;

    // Compute the animation's duration when necessary. The caller may specify a duration of WWNavigatorDurationDefault
    // to indicate that the navigator compute a default duration based on the begin and end values. This uses a hybrid
    // of the begin and end locations and ranges in order to factor the change in both attributes into the duration.
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
    [_eyePosition setLocation:animBeginLocation altitude:animBeginAltitude];
    [self setHeading:animBeginHeading];
    [self setTilt:animBeginTilt];
    [self setRoll:animBeginRoll];
}

- (void) animationDidEnd
{
    [super animationDidEnd];

    // The animation has ended. Explicitly set the end values rather than interpolating to ensure that the end values
    // are set exactly as the caller requested.
    [_eyePosition setLocation:animEndLocation altitude:animEndAltitude];
    [self setHeading:animEndHeading];
    [self setTilt:animEndTilt];
    [self setRoll:animEndRoll];
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
    [WWLocation greatCircleInterpolate:animBeginLocation endLocation:animEndLocation
                                amount:animationPct outputLocation:_eyePosition];

    if (animMidAltitude == DBL_MAX) // The animation is not using a mid range value.
    {
        [_eyePosition setAltitude:[WWMath interpolateValue1:animBeginAltitude value2:animEndAltitude amount:animationPct]];
    }
    else if (now <= midTime) // The animation is using a mid range value, and is in the first half of its duration.
    {
        double firstHalfPct = [WWMath smoothStepValue:now min:beginTime max:midTime];
        [_eyePosition setAltitude:[WWMath interpolateValue1:animBeginAltitude value2:animMidAltitude amount:firstHalfPct]];
    }
    else // The animation is using a mid range value, and is in the second half of its duration.
    {
        double secondHalfPct = [WWMath smoothStepValue:now min:midTime max:endTime];
        [_eyePosition setAltitude:[WWMath interpolateValue1:animMidAltitude value2:animEndAltitude amount:secondHalfPct]];
    }

    [self setHeading:[WWMath interpolateDegrees1:animBeginHeading degrees2:animEndHeading amount:animationPct]];
    [self setTilt:[WWMath interpolateDegrees1:animBeginTilt degrees2:animEndTilt amount:animationPct]];
    [self setRoll:[WWMath interpolateDegrees1:animBeginRoll degrees2:animEndRoll amount:animationPct]];
}

//--------------------------------------------------------------------------------------------------------------------//
//-- Gesture Recognizer Interface for Subclasses --//
//--------------------------------------------------------------------------------------------------------------------//

- (void) handlePanFrom:(UIPanGestureRecognizer*)recognizer
{
    // Apply the translation of the pan gesture to this navigator's eye position. We convert the pan translation from
    // screen pixels to arc degrees in order to provide a translation that is appropriate for the current eye position.
    // In order to convert from pixels to arc degrees we assume that the eye altitude is the distance that the gesture
    // is intended for.

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

        // Compute the distance between the eye point and the point at the center of the screen. This provides a
        // range we can use as a context for this gesture. Fall back to using the eye position's altitude if we cannot
        // determine the point at the center of the screen.
        double range = [_eyePosition altitude];
        id<WWNavigatorState> currentState = [self currentState];
        WWGlobe* globe = [[[self view] sceneController] globe];
        WWVec4* point = [[WWVec4 alloc] initWithZeroVector];
        if ([globe intersectWithRay:[currentState forwardRay] result:point])
        {
            range = [point distanceTo3:[currentState eyePoint]];
        }

        // Convert the translation from the view's local coordinate system to meters, assuming the translation is
        // intended for an object that is 'range' meters away form the eye position. Convert from change in screen
        // relative coordinates to change in model relative coordinates by inverting the change in X. There is no need
        // to invert the change in Y because the Y axis coordinates are already inverted.
        CGRect viewport = [[self view] viewport];
        double distance = MAX(1, range);
        double metersPerPixel = [WWMath perspectivePixelSize:viewport atDistance:distance];
        double forwardMeters = dy * metersPerPixel;
        double sideMeters = -dx * metersPerPixel;

        // Convert the translation from meters to arc degrees. The globe's radius provides the necessary context to
        // perform this conversion.
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
        double newLat = [WWMath clampValue:([_eyePosition latitude] + latDegrees) min:-90 max:90];
        double newLon = [WWMath normalizeDegreesLongitude:[_eyePosition longitude] + lonDegrees];
        [_eyePosition setDegreesLatitude:newLat longitude:newLon];
    }
    else
    {
        WWLog(@"Unknown gesture recognizer state: %d", state);
    }
}

- (void) handlePinchFrom:(UIPinchGestureRecognizer*)recognizer
{
    // Pinch-in gestures move the eye point closer to the touch point, while pinch-out gestures move the eye point away
    // from the touch point. There is no need to apply any additional scaling to the change in distance because the
    // nature of a pinch gesture already accomplishes this. Each pinch gesture applies a linear scale to the current
    // distance. This scale value has a limited range - typically between 1/10 and 10 - due to the limited size of the
    // touch surface and an average user's hand. This means that large changes in distance are accomplished by multiple
    // successive pinch gestures, rather than one continuous gesture. Since each gesture's scale is applied to the
    // current distance, the resultant scaling is implicitly appropriate for the current eye position.

    UIGestureRecognizerState state = [recognizer state];

    if (state == UIGestureRecognizerStateBegan)
    {
        [self beginTouchPointGesture:recognizer];
        [self gestureRecognizerDidBegin:recognizer];
    }
    else if (state == UIGestureRecognizerStateEnded || state == UIGestureRecognizerStateCancelled)
    {
        [self endTouchPointGesture:recognizer];
        [self gestureRecognizerDidEnd:recognizer];
    }
    else if (state == UIGestureRecognizerStateChanged)
    {
        // Ignore a scale of zero. This appears to be a bug in UIPinchGestureRecognzier's handling of the user changing
        // between two and three fingers while pinching.
        CGFloat scale = [recognizer scale];
        if (scale != 0)
        {
            WWVec4* eyePoint = [touchPointBeginState eyePoint];
            double ts = -(1 - 1 / scale);
            double x = ([touchPoint x] - [eyePoint x]) * ts;
            double y = ([touchPoint y] - [eyePoint y]) * ts;
            double z = ([touchPoint z] - [eyePoint z]) * ts;
            [touchPointPinch setTranslation:x y:y z:z];

            [self applyTouchPointGestures];
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
        [self beginTouchPointGesture:recognizer];
        [self gestureRecognizerDidBegin:recognizer];
    }
    else if (state == UIGestureRecognizerStateEnded || state == UIGestureRecognizerStateCancelled)
    {
        [self endTouchPointGesture:recognizer];
        [self gestureRecognizerDidEnd:recognizer];
    }
    else if (state == UIGestureRecognizerStateChanged)
    {
        double degrees = DEGREES(-[recognizer rotation]);
        [touchPointRotation setToIdentity];
        [touchPointRotation multiplyByTranslation:[touchPoint x] y:[touchPoint y] z:[touchPoint z]];
        [touchPointRotation multiplyByRotationAxis:[touchPointNormal x] y:[touchPointNormal y] z:[touchPointNormal z] angleDegrees:degrees];
        [touchPointRotation multiplyByTranslation:-[touchPoint x] y:-[touchPoint y] z:-[touchPoint z]];

        [self applyTouchPointGestures];
    }
    else
    {
        WWLog(@"Unknown gesture recognizer state: %d", state);
    }
}

- (void) handleTwoFingerPanFrom:(UIPanGestureRecognizer*)recognizer
{
    UIGestureRecognizerState state = [recognizer state];

    if (state == UIGestureRecognizerStateBegan)
    {
        gestureBeginHeading = [self heading];
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

        double headingDegrees = 90 * -translation.x / CGRectGetWidth(bounds);
        double tiltDegrees = 90 * translation.y / CGRectGetHeight(bounds);
        [self setHeading:[WWMath normalizeDegrees:gestureBeginHeading + headingDegrees]];
        [self setTilt:[WWMath clampValue:gestureBeginTilt + tiltDegrees min:0 max:90]];
    }
    else
    {
        WWLog(@"Unknown gesture recognizer state: %d", state);
    }
}

- (BOOL) gestureRecognizer:(UIGestureRecognizer*)recognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer*)otherRecognizer
{
    if (recognizer == pinchGestureRecognizer)
    {
        return otherRecognizer == rotationGestureRecognizer;
    }
    else if (recognizer == rotationGestureRecognizer)
    {
        return otherRecognizer == pinchGestureRecognizer;
    }
    else
    {
        return NO;
    }
}

- (BOOL) gestureRecognizerShouldBegin:(UIGestureRecognizer*)recognizer
{
    if (recognizer == pinchGestureRecognizer || recognizer == rotationGestureRecognizer)
    {
        return touchPoint != nil || [self touchPointFor:recognizer] != nil;
    }
    else if (recognizer == twoFingerPanGestureRecognizer)
    {
        UIPanGestureRecognizer* pgr = (UIPanGestureRecognizer*) recognizer;
        UIView* view = [recognizer view];

        NSUInteger numTouches = [pgr numberOfTouches];
        if (numTouches < 2)
        {
            return NO; // Do not recognize the gesture; not enough touches.
        }

        CGPoint touch1 = [pgr locationOfTouch:0 inView:view];
        CGPoint touch2 = [pgr locationOfTouch:1 inView:view];
        double slope = (touch2.y - touch1.y) / (touch2.x - touch1.x);
        if (fabs(slope) > TWO_FINGER_PAN_MAX_SLOPE)
        {
            return NO; // Do not recognize the gesture; touches do not represent two fingers placed horizontally.
        }
    }

    return YES;
}

- (void) beginTouchPointGesture:(UIGestureRecognizer*)recognizer
{
    if (touchPointGestures == 0)
    {
        WWGlobe* globe = [[[self view] sceneController] globe];

        touchPoint = [self touchPointFor:recognizer];
        touchPointNormal = [[WWVec4 alloc] initWithZeroVector];
        [globe surfaceNormalAtPoint:[touchPoint x] y:[touchPoint y] z:[touchPoint z] result:touchPointNormal];
        touchPointModelview = [[WWMatrix alloc] initWithIdentity];
        touchPointPinch = [[WWMatrix alloc] initWithIdentity];
        touchPointRotation = [[WWMatrix alloc] initWithIdentity];
        touchPointBeginState = [self currentState];
    }

    touchPointGestures++;
}

- (void) endTouchPointGesture:(UIGestureRecognizer*)recognizer
{
    touchPointGestures--;

    if (touchPointGestures == 0)
    {
        touchPoint = nil;
        touchPointNormal = nil;
        touchPointModelview = nil;
        touchPointPinch = nil;
        touchPointRotation = nil;
        touchPointBeginState = nil;
    }
}

- (void) applyTouchPointGestures
{
    [touchPointModelview setToMatrix:[touchPointBeginState modelview]];
    [touchPointModelview multiplyMatrix:touchPointPinch];
    [touchPointModelview multiplyMatrix:touchPointRotation];

    NSDictionary* params = [self viewingParametersForModelview:touchPointModelview rollDegrees:[self roll]];
    _eyePosition = [params objectForKey:WW_ORIGIN];
    [self setHeading:[[params objectForKey:WW_HEADING] doubleValue]];
    [self setTilt:[[params objectForKey:WW_TILT] doubleValue]];
    [self setRoll:[[params objectForKey:WW_ROLL] doubleValue]];
}

- (WWVec4*) touchPointFor:(UIGestureRecognizer*)recognizer
{
    id<WWNavigatorState> state = [self currentState];
    UIView* view = [recognizer view];
    CGPoint screenPoint = [recognizer locationInView:view];

    WWGlobe* globe = [[[self view] sceneController] globe];
    WWLine* ray = [state rayFromScreenPoint:screenPoint];
    WWVec4* modelPoint = [[WWVec4 alloc] initWithZeroVector];
    if ([globe intersectWithRay:ray result:modelPoint])
    {
        return modelPoint;
    }

    ray = [state forwardRay];
    if ([globe intersectWithRay:ray result:modelPoint])
    {
        return modelPoint;
    }

    return nil;
}

@end