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
#import "WorldWind/Geometry/WWMatrix.h"
#import "WorldWind/WorldWindView.h"
#import "WorldWind/WWLog.h"

#define DEFAULT_FIELD_OF_VIEW 45
#define DEFAULT_NEAR_DISTANCE 1
#define DEFAULT_FAR_DISTANCE 1000000000
#define DEFAULT_LATITUDE 0
#define DEFAULT_LONGITUDE 0
#define DEFAULT_ALTITUDE 20000000

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

    self->_fieldOfView = DEFAULT_FIELD_OF_VIEW;
    self->_nearDistance = DEFAULT_NEAR_DISTANCE;
    self->_farDistance = DEFAULT_FAR_DISTANCE;
    self->_lookAt = [[WWLocation alloc] initWithDegreesLatitude:DEFAULT_LATITUDE longitude:DEFAULT_LONGITUDE];
    self->_range = DEFAULT_ALTITUDE;

    return self;
}

- (id<WWNavigatorState>) currentState
{
    // Compute the current projection matrix based on this Navigator's perspective properties and the UIView's
    // dimensions. We use UIView's bounds property instead of its frame property because the view's bounds are expressed
    // in its own coordinate system, and correctly accommodate device orientation changes.
    CGSize viewSize = [self->view bounds].size;
    WWMatrix* projection = [[WWMatrix alloc] initWithIdentity];
    [projection setPerspective:self->_fieldOfView
                 viewportWidth:viewSize.width
                viewportHeight:viewSize.height
                  nearDistance:self->_nearDistance
                   farDistance:self->_farDistance];

    // Compute the current modelview matrix based on this Navigator's look-at location and range.
    WWGlobe* globe = [[self->view sceneController] globe];
    WWMatrix* modelview = [[WWMatrix alloc] initWithIdentity];
    [modelview setLookAt:globe
          centerLatitude:[self->_lookAt latitude]
         centerLongitude:[self->_lookAt longitude]
          centerAltitude:0
           rangeInMeters:self->_range];

    return [[WWBasicNavigatorState alloc] initWithModelview:modelview projection:projection];
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
        double metersPerPixel = 2 * self->_range * tan(self->_fieldOfView / 2) / [self->view bounds].size.width;
        double yMeters = translation.y * metersPerPixel;
        double xMeters = translation.x * metersPerPixel;

        // Convert the translation from meters to arc degrees. The globe's radius provides the necessary information to
        // make this conversion reliably.
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
    // Apply the inverse of the pinch gesture's scale to this Navigator's range. Pinch-in gestures move the eye
    // position closer to the look-at position, while pinch-out gestures move the eye away from the look-at
    // position. There is no need to apply any additional scaling to the change in range based on eye position
    // because the nature of a pinch gesture already accomplishes this. Each pinch gesture applies a linear scale to
    // the current range. This scale value has a limited range - typically between 1/10 and 10 - due to the limited
    // size of the touch surface and an average user's hand. This means that large changes in range are
    // accomplished by multiple successive pinch gestures, rather than one continuous gesture. Since each gesture's
    // scale is applied to the current range, the resultant scaling is implicitly appropriate for the current eye
    // position.

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

- (void) updateView
{
    [self->view drawView];
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
