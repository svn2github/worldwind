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
#define DEFAULT_HEADING 0
#define DEFAULT_TILT 0
#define MIN_NEAR_DISTANCE 1
#define MIN_FAR_DISTANCE 100

@implementation WWBasicNavigator

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

        self->animators = 0;

        self->_nearDistance = DEFAULT_NEAR_DISTANCE;
        self->_farDistance = DEFAULT_FAR_DISTANCE;
        self->_lookAt = [[WWLocation alloc] initWithDegreesLatitude:DEFAULT_LATITUDE longitude:DEFAULT_LONGITUDE];
        self->_range = DEFAULT_ALTITUDE;
        self->_heading = DEFAULT_HEADING;
        self->_tilt = DEFAULT_TILT;
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

    // Compute the current modelview matrix based on this Navigator's look-at location and range.
    WWMatrix* modelview = [[WWMatrix alloc] initWithIdentity];
    [modelview setLookAt:globe
          centerLatitude:[self->_lookAt latitude]
         centerLongitude:[self->_lookAt longitude]
          centerAltitude:0
           rangeInMeters:self->_range
                 heading:self->_heading
                    tilt:self->_tilt];

    // Compute the current near and far clip distances based on the current eye elevation relative to the globe. This
    // must be done after computing the modelview matrix, since the modelview matrix defines the eye position.
    WWMatrix* mvi = [[[WWMatrix alloc] initWithIdentity] invertTransformMatrix:modelview];
    WWPosition* eyePos = [[WWPosition alloc] initWithDegreesLatitude:0 longitude:0 altitude:0];
    [globe computePositionFromPoint:mvi->m[3] y:mvi->m[7] z:mvi->m[11] outputPosition:eyePos];

    self->_nearDistance = [WWMath perspectiveSizePreservingMaxNearDistance:viewportWidth
                                                            viewportHeight:viewportHeight
                                                          distanceToObject:[eyePos altitude]];
    if (self->_nearDistance < MIN_NEAR_DISTANCE)
        self->_nearDistance = MIN_NEAR_DISTANCE;

    self->_farDistance = [WWMath horizonDistance:globeRadius elevation:[eyePos altitude]];
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
        [self startAnimation];
    }
    else if (state == UIGestureRecognizerStateEnded || state == UIGestureRecognizerStateCancelled)
    {
        [self stopAnimation];
    }
    else if (state == UIGestureRecognizerStateChanged)
    {
        // Compute the translation in the view's local coordinate system.
        CGPoint panTranslation = [recognizer translationInView:self->view];
        double dx = panTranslation.x - self->lastPanTranslation.x;
        double dy = panTranslation.y - self->lastPanTranslation.y;
        self->lastPanTranslation = panTranslation;

        // Convert the translation from the view's local coordinate system to meters, assuming the translation is
        // intended for an object that is 'range' meters away form the eye position.
        CGRect viewport = [self->view viewport];
        double distance = MAX(1, self->_range);
        double metersPerPixel = [WWMath perspectiveSizePreservingMaxPixelSize:CGRectGetWidth(viewport)
                                                               viewportHeight:CGRectGetHeight(viewport)
                                                             distanceToObject:distance];
        double forwardMeters = dy * metersPerPixel;
        double sideMeters = -dx * metersPerPixel;

        // Convert the translation from meters to arc degrees. The globe's radius provides the necessary context to
        // perform this conversion.
        WWGlobe* globe = [[self->view sceneController] globe];
        double radius = MAX([globe equatorialRadius], [globe polarRadius]);
        double forwardDegrees = DEGREES(forwardMeters / radius);
        double sideDegrees = DEGREES(sideMeters / radius);
        double sideHeading = NormalizedDegreesHeading(self->_heading + 90);

        [self->_lookAt setRhumbEndLocation:self->_lookAt azimuth:self->_heading distance:forwardDegrees];
        [self->_lookAt setRhumbEndLocation:self->_lookAt azimuth:sideHeading distance:sideDegrees];
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
        self->beginRange = self->_range;
        [self startAnimation];
    }
    else if (state == UIGestureRecognizerStateEnded || state == UIGestureRecognizerStateCancelled)
    {
        [self stopAnimation];
    }
    else if (state == UIGestureRecognizerStateChanged)
    {
        // Ignore a scale of zero. This appears to be a bug in UIPinchGestureRecognzier's handling of the user changing
        // between two and three fingers while pinching.
        CGFloat scale = [recognizer scale];
        if (scale != 0)
            self->_range = self->beginRange / scale;
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
        self->beginHeading = self->_heading;
        [self startAnimation];
    }
    else if (state == UIGestureRecognizerStateEnded || state == UIGestureRecognizerStateCancelled)
    {
        [self stopAnimation];
    }
    else if (state == UIGestureRecognizerStateChanged)
    {
        double rotationInDegrees = DEGREES([recognizer rotation]);
        self->_heading = NormalizedDegreesHeading(self->beginHeading - rotationInDegrees);
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
        self->beginTilt = self->_tilt;
        [self startAnimation];
    }
    else if (state == UIGestureRecognizerStateEnded || state == UIGestureRecognizerStateCancelled)
    {
        [self stopAnimation];
    }
    else if (state == UIGestureRecognizerStateChanged)
    {
        CGPoint translation = [recognizer translationInView:self->view];
        CGRect bounds = [self->view bounds];
        double degrees = 90 * translation.y / CGRectGetHeight(bounds);
        self->_tilt = [WWMath clamp:self->beginTilt + degrees min:0 max:90];
    }
    else
    {
        WWLog(@"Unknown gesture recognizer state: %d", state);
    }
}

- (BOOL) gestureRecognizerShouldBegin:(UIGestureRecognizer*)gestureRecognizer
{
    // Note: the view property is a weak reference, so it may have been de-allocated. In this case the contents of the
    // CG structures below will be undefined. However, the view's gesture recognizers will not be sent any messages
    // after the view itself is de-allocated.

    // Determine whether the vertical pan gesture recognizer should recognizer its gesture. This gesture recognizer is
    // a UIPanGestureRecognizer configured with two or more touches. In order to limit its recognition to a vertical pan
    // gesture, we place additional limitations on its recognition in this delegate.
    if (gestureRecognizer == self->verticalPanGestureRecognizer)
    {
        UIPanGestureRecognizer* pgr = (UIPanGestureRecognizer*) gestureRecognizer;

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

- (BOOL) gestureRecognizer:(UIGestureRecognizer*)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer*)otherGestureRecognizer
{
    if (gestureRecognizer == self->panGestureRecognizer)
    {
        return otherGestureRecognizer == self->pinchGestureRecognizer
            || otherGestureRecognizer == self->rotationGestureRecognizer;
    }
    else if (gestureRecognizer == self->pinchGestureRecognizer)
    {
        return otherGestureRecognizer == self->panGestureRecognizer
            || otherGestureRecognizer == self->rotationGestureRecognizer;
    }
    else if (gestureRecognizer == self->rotationGestureRecognizer)
    {
        return otherGestureRecognizer == self->panGestureRecognizer
            || otherGestureRecognizer == self->pinchGestureRecognizer;
    }
    else
    {
        return NO;
    }
}

// TODO: Consider adding a capability similar to startAnimation/stopAnimation to WorldWindView.
// This would enable multiple components to synchronize their requests for a redraw, and avoid duplicate redraws.
- (void) startAnimation
{
    if (self->animators == 0)
    {
        self->displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(drawView)];
        [self->displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    }

    self->animators++;
}

- (void) stopAnimation
{
    self->animators--;

    if (self->animators == 0)
    {
        [self->displayLink invalidate];
        self->displayLink = nil;
    }
}

- (void) drawView
{
    // The view is a weak reference, so it may have been de-allocated.
    if (self->view != nil)
    {
        [self->view drawView];
    }
}

@end