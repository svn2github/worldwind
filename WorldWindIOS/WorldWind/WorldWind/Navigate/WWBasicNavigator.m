/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.

 @version $Id$
 */

#import "WorldWind/Navigate/WWBasicNavigator.h"
#import "WorldWind/Navigate/WWBasicNavigatorState.h"
#import "WorldWind/Render/WWSceneController.h"
#import "WorldWind/Terrain/WWGlobe.h"
#import "WorldWind/Geometry/WWAngle.h"
#import "WorldWind/Geometry/WWLocation.h"
#import "WorldWind/Geometry/WWPosition.h"
#import "WorldWind/Geometry/WWMatrix.h"
#import "WorldWind/Util/WWMath.h"
#import "WorldWind/WorldWindView.h"
#import "WorldWind/WWLog.h"

#define DEFAULT_NEAR_DISTANCE 1
#define DEFAULT_FAR_DISTANCE 1000000000
#define DEFAULT_LATITUDE 0
#define DEFAULT_LONGITUDE 0
#define DEFAULT_ALTITUDE 20000000
#define MIN_NEAR_DISTANCE 1
#define MIN_FAR_DISTANCE 100

@implementation WWBasicNavigator

- (WWBasicNavigator*) initWithView:(WorldWindView*)viewToNavigate
{
    self = [super init];

    if (viewToNavigate == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"View is invalid")
    }

    self->view = viewToNavigate;
    self->panGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePanFrom:)];
    self->pinchGestureRecognizer = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(handlePinchFrom:)];
    [self->panGestureRecognizer setDelegate:self];
    [self->pinchGestureRecognizer setDelegate:self];
    [self->view addGestureRecognizer:self->panGestureRecognizer];
    [self->view addGestureRecognizer:self->pinchGestureRecognizer];

    self->beginLookAt = [[WWLocation alloc] initWithDegreesLatitude:0 longitude:0];
    self->beginRange = 0;

    self->_nearDistance = DEFAULT_NEAR_DISTANCE;
    self->_farDistance = DEFAULT_FAR_DISTANCE;
    self->_lookAt = [[WWLocation alloc] initWithDegreesLatitude:DEFAULT_LATITUDE longitude:DEFAULT_LONGITUDE];
    self->_range = DEFAULT_ALTITUDE;

    return self;
}

- (id<WWNavigatorState>) currentState
{
    WWGlobe* globe = [[self->view sceneController] globe];
    double globeRadius = MAX([globe equatorialRadius], [globe polarRadius]);

    CGRect viewport = [self->view viewport];
    double viewportWidth = CGRectGetWidth(viewport);
    double viewportHeight = CGRectGetHeight(viewport);

    // Compute the current modelview matrix based on this Navigator's look-at location and range.
    WWMatrix* modelview = [[WWMatrix alloc] initWithIdentity];
    [modelview setLookAt:globe
          centerLatitude:[self->_lookAt latitude]
         centerLongitude:[self->_lookAt longitude]
          centerAltitude:0
           rangeInMeters:self->_range];

    // Compute the current near and far clip distances based on the current eye elevation relative to the globe. This
    // must be done after computing the modelview matrix, since the modelview matrix defines the eye position.
    WWMatrix* mvi = [[[WWMatrix alloc] initWithIdentity] invertTransformMatrix:modelview];
    WWPosition* eyePos = [[WWPosition alloc] initWithDegreesLatitude:0 longitude:0 elevation:0];
    [globe computePositionFromPoint:mvi->m[3] y:mvi->m[7] z:mvi->m[11] outputPosition:eyePos];

    self->_nearDistance = perspectiveSizePreservingMaxNearDistance(viewportWidth, viewportHeight, [eyePos elevation]);
    if (self->_nearDistance < MIN_NEAR_DISTANCE)
        self->_nearDistance = MIN_NEAR_DISTANCE;

    self->_farDistance = horizonDistance(globeRadius, [eyePos elevation]);
    if (self->_farDistance < MIN_FAR_DISTANCE)
        self->_farDistance = MIN_FAR_DISTANCE;

    // Compute the current projection matrix based on this Navigator's perspective properties and the current OpenGL
    // viewport. We use the WorldWindView's OpenGL viewport instead of its bounds because the viewport contains the
    // actual render buffer dimension, whereas the bounds contain the view's dimension in screen points.
    WWMatrix *projection = [[WWMatrix alloc] initWithIdentity];
    [projection setPerspectiveSizePreserving:viewportWidth
                              viewportHeight:viewportHeight
                                nearDistance:self->_nearDistance
                                 farDistance:self->_farDistance];

    return [[WWBasicNavigatorState alloc] initWithModelview:modelview projection:projection];
}

- (void) updateView
{
    [self->view drawView];
}

- (void) handlePanFrom:(UIPanGestureRecognizer*)recognizer
{
    // Apply the translation of the pan gesture to this Navigator's look-at location. Horizontal pan gestures translate
    // the look-at's longitude, while vertical pan gestures translate the look-at's latitude. We convert the pan
    // translation from screen pixels to arc degrees in order to provide a translation that is appropriate for the
    // current eye position. In order to convert from pixels to arc degrees we assume that this Navigator's range
    // represents the distance that the gesture is intended for.

    UIGestureRecognizerState state = [recognizer state];

    if (state == UIGestureRecognizerStateBegan)
    {
        [self->beginLookAt set:self->_lookAt];
    }
    else if (state == UIGestureRecognizerStateEnded || state == UIGestureRecognizerStateCancelled)
    {
        [self->beginLookAt setDegreesLatitude:0 longitude:0];
    }
    else if (state == UIGestureRecognizerStateChanged)
    {
        // Compute the translation in the view's local coordinate system.
        CGPoint translation = [recognizer translationInView:self->view];

        // Convert the translation from the view's local coordinate system to meters, assuming the translation is
        // intended for an object that is 'range' meters away form the eye position.
        CGRect viewport = [self->view viewport];
        double distance = MAX(1, self->_range);
        double metersPerPixel = perspectiveSizePreservingMaxPixelSize(CGRectGetWidth(viewport), CGRectGetHeight(viewport), distance);
        double yMeters = translation.y * metersPerPixel;
        double xMeters = translation.x * metersPerPixel;

        // Convert the translation from meters to arc degrees. The globe's radius provides the necessary context to
        // perform this conversion.
        WWGlobe* globe = [[self->view sceneController] globe];
        double radius = MAX([globe equatorialRadius], [globe polarRadius]);
        double yDegrees = DEGREES(yMeters / radius);
        double xDegrees = DEGREES(xMeters / radius);

        [self->_lookAt setDegreesLatitude:NormalizedDegreesLatitude([self->beginLookAt latitude] + yDegrees)
                                longitude:NormalizedDegreesLongitude([self->beginLookAt longitude] - xDegrees)];
        [self updateView];
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
        self->beginRange = self->_range;
    }
    else if (state == UIGestureRecognizerStateEnded || state == UIGestureRecognizerStateCancelled)
    {
        self->beginRange = 0;
    }
    else if (state == UIGestureRecognizerStateChanged)
    {
        self->_range = self->beginRange / [recognizer scale];
        [self updateView];
    }
}

- (BOOL) gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    if (gestureRecognizer == self->panGestureRecognizer)
        return otherGestureRecognizer == self->pinchGestureRecognizer;
    else if (gestureRecognizer == self->pinchGestureRecognizer)
        return otherGestureRecognizer == self->panGestureRecognizer;
    else
        return NO;
}

@end
