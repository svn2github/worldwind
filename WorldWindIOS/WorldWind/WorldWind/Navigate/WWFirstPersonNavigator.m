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
#define DEFAULT_HEADING 0
#define DEFAULT_TILT 0
#define DEFAULT_ROLL 0

@implementation WWFirstPersonNavigator

//--------------------------------------------------------------------------------------------------------------------//
//-- Initializing Navigators --//
//--------------------------------------------------------------------------------------------------------------------//

- (WWFirstPersonNavigator*) initWithView:(WorldWindView*)viewToNavigate
{
    self = [super initWithView:viewToNavigate]; // Superclass validates the viewToNavigate argument.

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

    UIView* view = [self view];
    [view addGestureRecognizer:panGestureRecognizer];
    [view addGestureRecognizer:pinchGestureRecognizer];
    [view addGestureRecognizer:rotationGestureRecognizer];
    [view addGestureRecognizer:twoFingerPanGestureRecognizer];

    WWPosition* lastKnownPosition = [self lastKnownPosition];
    _eyePosition = [[WWPosition alloc] initWithLocation:lastKnownPosition altitude:DEFAULT_ALTITUDE]; // TODO: Compute initial altitude to fit globe in viewport.
    _heading = DEFAULT_HEADING;
    _tilt = DEFAULT_TILT;
    _roll = DEFAULT_ROLL;

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

//--------------------------------------------------------------------------------------------------------------------//
//-- Navigator Protocol --//
//--------------------------------------------------------------------------------------------------------------------//

- (id<WWNavigatorState>) currentState
{
    // Compute the current modelview matrix based on this navigator's eye position, heading, and tilt.
    WWGlobe* globe = [[[self view] sceneController] globe];
    WWMatrix* modelview = [[WWMatrix alloc] initWithIdentity];
    [modelview multiplyByFirstPersonModelview:_eyePosition
                               headingDegrees:_heading
                                  tiltDegrees:_tilt
                                  rollDegrees:_roll
                                      onGlobe:globe];

    return [self currentStateForModelview:modelview];
}

- (NSDictionary*) extractFirstPersonParams:(WWMatrix*)modelview forRollDegrees:(double)roll
{
    WWVec4* eyePoint = [modelview extractEyePoint];
    WWGlobe* globe = [[[self view] sceneController] globe];

    return [modelview extractViewingParameters:eyePoint forRollDegrees:roll onGlobe:globe];
}

- (void) setWithModelview:(WWMatrix*)modelview rollDegrees:(double)roll
{
    NSDictionary* params = [self extractFirstPersonParams:modelview forRollDegrees:roll];

    WWVec4* eyePoint = [params objectForKey:WW_ORIGIN];
    WWGlobe* globe = [[[self view] sceneController] globe];
    [globe computePositionFromPoint:[eyePoint x] y:[eyePoint y] z:[eyePoint z] outputPosition:_eyePosition];

    _heading = [[params objectForKey:WW_HEADING] doubleValue];
    _tilt = [[params objectForKey:WW_TILT] doubleValue];
    _roll = [[params objectForKey:WW_ROLL] doubleValue];
}

- (void) gotoLocation:(WWLocation*)location overDuration:(NSTimeInterval)duration
{
}

- (void) gotoLookAt:(WWLocation*)lookAt range:(double)range overDuration:(NSTimeInterval)duration
{
}

- (void) gotoRegionWithCenter:(WWLocation*)center radius:(double)radius overDuration:(NSTimeInterval)duration
{
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

        // Convert the translation from the view's local coordinate system to meters, assuming the translation is
        // intended for an object that is 'eye altitude' meters away form the eye position. Convert from change in
        // screen relative coordinates to change in model relative coordinates by inverting the change in X. There is no
        // need to invert the change in Y because the Y axis coordinates are already inverted.
        CGRect viewport = [[self view] viewport];
        double distance = MAX(1, [_eyePosition altitude]);
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
        double newLat = [WWMath clampValue:([_eyePosition latitude] + latDegrees) min:-90 max:90];
        double newLon = NormalizedDegreesLongitude([_eyePosition longitude] + lonDegrees);
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
        gestureBeginHeading = _heading;
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

        double headingDegrees = 90 * -translation.x / CGRectGetWidth(bounds);
        double tiltDegrees = 90 * translation.y / CGRectGetHeight(bounds);
        _heading = NormalizedDegreesHeading(gestureBeginHeading + headingDegrees);
        _tilt = [WWMath clampValue:gestureBeginTilt + tiltDegrees min:0 max:90];
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
        if (fabs(slope) > 1)
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

    [self setWithModelview:touchPointModelview rollDegrees:_roll];
}

- (WWVec4*) touchPointFor:(UIGestureRecognizer*)recognizer
{
    UIView* view = [recognizer view];
    CGPoint uiScreenPoint = [recognizer locationInView:view];
    double x = uiScreenPoint.x;
    double y = CGRectGetHeight([view bounds]) - uiScreenPoint.y;

    id<WWNavigatorState> state = [self currentState];
    WWGlobe* globe = [[[self view] sceneController] globe];
    WWVec4* point = [[WWVec4 alloc] initWithZeroVector];

    WWLine* ray = [state rayFromScreenPoint:x y:y];
    if ([globe intersectWithRay:ray result:point])
    {
        return point;
    }

    ray = [state forwardRay];
    if ([globe intersectWithRay:ray result:point])
    {
        return point;
    }

    return nil;
}

@end