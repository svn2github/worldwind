/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.

@version $Id$
 */

#import "TrackingController.h"
#import "WorldWind/Geometry/WWLocation.h"
#import "WorldWind/Geometry/WWPosition.h"
#import "WorldWind/Layer/WWLayerList.h"
#import "WorldWind/Layer/WWRenderableLayer.h"
#import "WorldWind/Navigate/WWNavigator.h"
#import "WorldWind/Render/WWSceneController.h"
#import "WorldWind/Shapes/WWPath.h"
#import "WorldWind/Shapes/WWShapeAttributes.h"
#import "WorldWind/Shapes/WWSphere.h"
#import "WorldWind/Terrain/WWGlobe.h"
#import "WorldWind/Util/WWColor.h"
#import "WorldWind/WorldWindConstants.h"

#define DISPLAY_LINK_FRAME_INTERVAL 3
#define FIRST_LOCATION_DURATION 1.0
#define FOLLOW_LOCATION_SMOOTHING 0.1
#define LOCATION_REQUIRED_ACCURACY 100.0
#define LOCATION_REQUIRED_AGE 2.0
#define MARKER_VERTICAL_OFFSET 10.0
#define NAVIGATOR_REGION_RADIUS 1000.0

typedef enum
{
    TrackingControllerStateFirstLocation,
    TrackingControllerStateAnimating,
    TrackingControllerStateFollowLocation,
} TrackingControllerState;

@implementation TrackingController
{
    TrackingControllerState state;
    BOOL updatingLocation;
    BOOL observingNavigator;

    CLLocation* mostRecentLocation;
    CLLocationManager* locationManager;
    CADisplayLink* displayLink;

    WWPosition* forecastPosition;
    WWPosition* currentPosition;

    WWSphere* marker;
    WWRenderableLayer* layer;
}

- (TrackingController*) initWithView:(WorldWindView*)view
{
    self = [super init];

    state = TrackingControllerStateFirstLocation;

    forecastPosition = [[WWPosition alloc] init];
    currentPosition = [[WWPosition alloc] init];

    WWShapeAttributes* attributes = [[WWShapeAttributes alloc] init];
    [attributes setInteriorColor:[[WWColor alloc] initWithR:.24 g:.47 b:.99 a:1]];
    marker = [[WWSphere alloc] initWithPosition:[[WWPosition alloc] init] radiusInPixels:5];
    [marker setDisplayName:@"Tracking Sphere"];
    [marker setAttributes:attributes];

    layer = [[WWRenderableLayer alloc] init];
    [layer setDisplayName:@"Location Marker"];
    [layer addRenderable:marker];
    [[[view sceneController] layers] addLayer:layer];

    _view = view;

    [self startAll];

    return self;
}

- (void) setEnabled:(BOOL)enabled
{
    if (_enabled == enabled)
    {
        return;
    }

    if (enabled)
    {
        if (![CLLocationManager locationServicesEnabled])
        {
            return;
        }

        state = TrackingControllerStateFirstLocation; // Reset the internal tracking controller state.
        [self startAll];
    }
    else
    {
        [self stopAll];
    }

    _enabled = enabled;
}

- (void) startAll
{
    [self startUpdatingLocation];
    [self startObservingNavigator];
}

- (void) stopAll
{
    [self stopUpdatingLocation];
    [self stopObservingNavigator];
}

- (void) forecastPosition:(CLLocation*)location forDate:(NSDate*)date
{
    if (currentPosition == nil)
    {
        // Set the current location to the initial location determined by Core Location, ignoring the CLLocation's
        // altitude.
        currentPosition = [[WWPosition alloc] initWithCLLocation:location altitude:0];
    }
    else
    {
        // Forecast the current location from the most recent location. Forecasting in a display link enables generation
        // of intermediate locations at sub-second intervals between Core Location's 1-2 second updates.
        WWGlobe* globe = [[_view sceneController] globe];
        [WWPosition forecastPosition:location forDate:date onGlobe:globe outputPosition:forecastPosition];

        // Smooth the forecast position by interpolating a fraction of the distance between the last position and the
        // forecast position.
        [WWPosition greatCircleInterpolate:currentPosition
                               endLocation:forecastPosition
                                    amount:FOLLOW_LOCATION_SMOOTHING
                            outputLocation:currentPosition]; // Input position can be reused to store the output.
    }
}

- (void) updateView:(WWPosition*)position
{
    if (state == TrackingControllerStateFirstLocation)
    {
        [self animateNavigatorToPosition:position];
    }
    else if (state == TrackingControllerStateFollowLocation)
    {
        // Update the navigator to show the current position. This change is applied without animation, and does not
        // affect the navigator's distance to the current position.
        [self setNavigatorToPosition:position];
    }

    // Update the marker to reflect the current position. Set the marker's latitude and longitude to the current
    // position's and set its altitude to a constant offset above the surface.
    [[marker position] setLocation:position altitude:MARKER_VERTICAL_OFFSET];
    [marker setAltitudeMode:WW_ALTITUDE_MODE_RELATIVE_TO_GROUND];

    // Avoid redundant drawView calls while the navigator is animating.
    if (state != TrackingControllerStateAnimating)
    {
        [_view drawView];
    }
}

- (void) animateNavigatorToPosition:(WWPosition*)position
{
    if (_enabled)
    {
        // Animate the navigator to the first location, zooming in if necessary. During this animation the location
        // continues to update and the marker position changes. This makes no additional changes to the navigator until
        // after the animation completes, and the state changes to TrackingControllerStateFollowing. Suppress navigator
        // notifications while initiating the animation to distinguish between this animation and animations started by
        // another component.
        [self stopObservingNavigator];
        [[_view navigator] animateToRegionWithCenter:position
                                              radius:NAVIGATOR_REGION_RADIUS
                                        overDuration:WWNavigatorDurationDefault];
        [self startObservingNavigator];

        // Designate that the tracking controller is waiting to start following.
        state = TrackingControllerStateAnimating;
    }
    else
    {
        // Animate the navigator to the first location without zooming in, and stop subsequent location updates. This
        // provides an initial location for the marker and the navigator.
        [self stopUpdatingLocation];
        [self stopObservingNavigator];
        [[_view navigator] animateToPosition:position overDuration:FIRST_LOCATION_DURATION];
    }
}

- (void) setNavigatorToPosition:(WWPosition*)position
{
    [[_view navigator] setToRegionWithCenter:position radius:NAVIGATOR_REGION_RADIUS];
}

//--------------------------------------------------------------------------------------------------------------------//
//-- Core Location Interface --//
//--------------------------------------------------------------------------------------------------------------------//

- (void) startUpdatingLocation
{
    if (!updatingLocation)
    {
        locationManager = [[CLLocationManager alloc] init];
        [locationManager setActivityType:CLActivityTypeOtherNavigation];
        [locationManager setDesiredAccuracy:kCLLocationAccuracyBestForNavigation];
        [locationManager setDelegate:self];
        [locationManager startUpdatingLocation];

        displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(displayLinkDidFire:)];
        [displayLink setFrameInterval:DISPLAY_LINK_FRAME_INTERVAL];
        [displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];

        mostRecentLocation = nil;
        currentPosition = nil;
        updatingLocation = YES;
    }
}

- (void) stopUpdatingLocation
{
    if (updatingLocation)
    {
        [locationManager setDelegate:nil]; // Suppress location updates in the queue that have not been delivered.
        [locationManager stopUpdatingLocation];
        locationManager = nil;

        [displayLink invalidate];
        displayLink = nil;

        updatingLocation = NO;
    }
}

- (void) locationManager:(CLLocationManager*)manager didUpdateLocations:(NSArray*)locations
{
    if ([CLLocationManager locationServicesEnabled])
    {
        CLLocation* location = [locations lastObject]; // The last list item contains the most recent location.
        if ([location horizontalAccuracy] <= LOCATION_REQUIRED_ACCURACY
            && -[[location timestamp] timeIntervalSinceNow] <= LOCATION_REQUIRED_AGE)
        {
            mostRecentLocation = [location copy];
        }
    }
    else
    {
        // The Core Location service has been disabled while this application has been in the background. Disable the
        // controller in order to stop attempting to use Core Location services.
        [self setEnabled:NO];
        [self stopAll]; // Stop all services explicitly if we're getting an initial location.
    }
}

- (void) locationManager:(CLLocationManager*)manager didFailWithError:(NSError*)error
{
    if ([error code] == kCLErrorDenied)
    {
        // This application has been denied access to location services. This can happen either when the application
        // first attempts to use Core Location services, or while the application was in the background. In either case
        // disable the controller in order to stop attempting to use Core Location services.
        [self setEnabled:NO];
        [self stopAll]; // Stop all services explicitly if we're getting an initial location.
    }
}

- (void) displayLinkDidFire:(CADisplayLink*)notifyingDisplayLink
{
    if ([CLLocationManager locationServicesEnabled])
    {
        if (mostRecentLocation != nil)
        {
            NSDate* now = [NSDate date];
            [self forecastPosition:mostRecentLocation forDate:now];
            [self updateView:currentPosition];
        }
    }
    else
    {
        // The Core Location service has been disabled while this application has been in the background. Disable the
        // controller in order to stop attempting to use Core Location services.
        [self setEnabled:NO];
        [self stopAll]; // Stop all services explicitly if we're getting an initial location.
    }
}

//--------------------------------------------------------------------------------------------------------------------//
//-- Navigator Notification Interface --//
//--------------------------------------------------------------------------------------------------------------------//

- (void) startObservingNavigator
{
    if (!observingNavigator)
    {
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(handleNavigatorNotification:)
                                                     name:nil
                                                   object:nil];
        observingNavigator = YES;
    }
}

- (void) stopObservingNavigator
{
    if (observingNavigator)
    {
        [[NSNotificationCenter defaultCenter] removeObserver:self];
        observingNavigator = NO;
    }
}

- (void) handleNavigatorNotification:(NSNotification*)notification
{
    NSString* name = [notification name];

    if ([name isEqualToString:WW_NAVIGATOR_CHANGED])
    {
        [self navigatorChanged];
    }
    else if ([[notification name] isEqualToString:WW_NAVIGATOR_ANIMATION_ENDED])
    {
        [self navigatorAnimationEnded];
    }
    else if ([[notification name] isEqualToString:WW_NAVIGATOR_ANIMATION_BEGAN]
            || [[notification name] isEqualToString:WW_NAVIGATOR_ANIMATION_CANCELLED]
            || [[notification name] isEqualToString:WW_NAVIGATOR_GESTURE_RECOGNIZED])
    {
        [self navigatorInterrupted];
    }
}

- (void) navigatorChanged
{
    if (state == TrackingControllerStateAnimating)
    {
        [self animateNavigatorToPosition:currentPosition];
    }
}

- (void) navigatorAnimationEnded
{
    if (state == TrackingControllerStateAnimating)
    {
        state = TrackingControllerStateFollowLocation;
    }
}

- (void) navigatorInterrupted
{
    [self setEnabled:NO];
    [self stopAll]; // Stop all services explicitly if we're getting an initial location.
}

@end