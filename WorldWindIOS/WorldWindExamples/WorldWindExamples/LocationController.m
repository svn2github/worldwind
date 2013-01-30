/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.

@version $Id$
 */

#import "LocationController.h"
#import "WorldWind/Navigate/WWBasicNavigator.h"
#import "WorldWind/Render/WWSceneController.h"
#import "WorldWind/Terrain/WWGlobe.h"
#import "WorldWind/Util/WWMath.h"
#import "WorldWind/WWLog.h"

#define LOCATION_MIN_ACCURACY 10000.0
#define INITIAL_LOCATION_MAX_TIME 2.0
#define DISPLAY_LINK_FRAME_INTERVAL 3
#define NAVIGATOR_INITIAL_DURATION 0.5
#define NAVIGATOR_FORECAST_INTERPOLANT 0.1
#define NAVIGATOR_FORECAST_RANGE_MIN 1000

@implementation LocationController

- (LocationController*) init
{
    self = [super init];

    if (self != nil)
    {
        self->locationManager = [[CLLocationManager alloc] init];
        [self->locationManager setDesiredAccuracy:kCLLocationAccuracyBestForNavigation];

        // Copy the NSLocationUsageDescription key from the application's Info.plist file to the CLLocationManager's
        // purpose property. This provides compatibility with iOS 5.1 while making correct usage of the
        // NSLocationUsageDescription property for iOS 6.0.
        NSString* bundleValue = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"NSLocationUsageDescription"];
        if (bundleValue != nil)
        {
            [self->locationManager setPurpose:bundleValue];
        }

        self->forecastLocation = [[WWLocation alloc] initWithDegreesLatitude:0 longitude:0];
    }

    return self;
}

- (void) setState:(LocationControllerState)state
{
    if (_state == state)
        return;

    if (![CLLocationManager locationServicesEnabled] && state != LocationControllerStateDisabled)
        return;

    if (state == LocationControllerStateDisabled)
    {
        [self stopLocationManager];
        [self stopDisplayLink];
    }
    else if (state == LocationControllerStateShowInitial)
    {
        [self startLocationManager];
    }
    else if (state == LocationControllerStateForecast)
    {
        [self startLocationManager];
        [self startDisplayLink];
    }
    else
    {
        WWLog(@"Unknown location controller state: %d", state);
    }

    _state = state;
}

- (void) updateViewWithInitialLocation:(CLLocation*)location
{
    if (_view == nil || [_view navigator] == nil)
    {
        return;
    }

    NSTimeInterval elapsedTime = -[self->locationManagerStartDate timeIntervalSinceNow];

    if ([self locationMeetsCriteria:location] || elapsedTime >= INITIAL_LOCATION_MAX_TIME)
    {
        // This controller has a last known location that meets its accuracy criteria, or enough time has passed that
        // we use the last known location anyway. Start a smooth animation that takes the navigator from its current
        // location to the last known location, without changing its distance from the globe. Additionally, set this
        // controller's state to disabled to suppress any additional initial location calls.
        WWBasicNavigator* navigator = (WWBasicNavigator*) [_view navigator];
        WWLocation* wwLocation = [[WWLocation alloc] initWithCLLocation:location];
        [navigator gotoLocation:wwLocation overDuration:NAVIGATOR_INITIAL_DURATION];
        [self setState:LocationControllerStateDisabled];
    }
}

- (void) updateViewWithForecastLocation:(WWLocation*)location
{
    if (_view == nil || [_view navigator] == nil)
    {
        return;
    }

    // This controller has a forecast location generated form a display link. We smooth the forecast locations by
    // navigating a fraction of the distance between the navigator's current location and distance from the globe.

    WWBasicNavigator* navigator = (WWBasicNavigator*) [_view navigator];
    double interpolant = NAVIGATOR_FORECAST_INTERPOLANT;

    WWLocation* beginLocation = [navigator lookAt];
    WWLocation* interpolatedLocation = [[WWLocation alloc] initWithDegreesLatitude:0 longitude:0];
    [WWLocation greatCircleInterpolate:beginLocation
                           endLocation:location
                                amount:interpolant
                        outputLocation:interpolatedLocation];

    double beginRange = [navigator range];
    double endRange = MIN(beginRange, NAVIGATOR_FORECAST_RANGE_MIN);
    double interpolatedRange = [WWMath interpolateValue1:beginRange value2:endRange amount:interpolant];

    [navigator gotoLocation:interpolatedLocation fromRange:interpolatedRange overDuration:0];
}

- (BOOL) locationMeetsCriteria:(CLLocation*)location
{
    return [location horizontalAccuracy] <= LOCATION_MIN_ACCURACY;
}

- (void) startLocationManager
{
    if (!self->locationManagerActive)
    {
        [self->locationManager setDelegate:self];
        [self->locationManager startUpdatingLocation];
        self->locationManagerStartDate = [NSDate date]; // Current date and time.
        self->locationManagerActive = YES;
    }
}

- (void) stopLocationManager
{
    if (self->locationManagerActive)
    {
        [self->locationManager setDelegate:nil]; // Suppress location updates in the queue that have not been delivered.
        [self->locationManager stopUpdatingLocation];
        self->locationManagerActive = NO;
    }
}

- (void) locationManager:(CLLocationManager*)manager didUpdateLocations:(NSArray*)locations
{
    if ([CLLocationManager locationServicesEnabled])
    {
        CLLocation* location = [locations lastObject];
        self->lastLocation = [location copyWithZone:NULL];

        if (_state == LocationControllerStateShowInitial)
        {
            // When this controller is in the show initial location state, attempt to forward the last known location
            // to updateViewWithForecastLocation until the accuracy criteria are met or enough time has passed. Once
            // either of these two criteria pass, updateViewWithForecastLocation sets this controller's state to
            // disabled.
            [self updateViewWithInitialLocation:self->lastLocation];
        }
    }
    else
    {
        [self setState:LocationControllerStateDisabled];
    }
}

- (void) locationManager:(CLLocationManager*)manager didUpdateToLocation:(CLLocation*)newLocation fromLocation:(CLLocation*)oldLocation
{
    // Forward the iOS 5.1 location manager delegate message locationManager:didUpdateToLocation:fromLocation to the
    // iOS 6.0 message locationManager:didUpdateLocations. This provides compatibility with iOS 5.1 while making correct
    // usage of the location manager delegate messages for iOS 6.0.

    NSArray* locations = [NSArray arrayWithObject:newLocation];
    [self locationManager:manager didUpdateLocations:locations];
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error
{
    if ([error code] == kCLErrorDenied)
    {
        // This application has been denied access to location services. This can happen either when the application
        // first attempts to use Core Location services, or while the application has been in the background. In either
        // case set this controller's state to disabled in order to stop attempting to use Core Location services.
        [self setState:LocationControllerStateDisabled];
    }
}

- (void) startDisplayLink
{
    if (!self->displayLinkActive)
    {
        self->displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(displayLinkDidFire)];
        [self->displayLink setFrameInterval:DISPLAY_LINK_FRAME_INTERVAL];
        [self->displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
        self->displayLinkActive = YES;
    }
}

- (void) stopDisplayLink
{
    if (self->displayLinkActive)
    {
        [self->displayLink invalidate];
        self->displayLink = nil;
        self->displayLinkActive = NO;
    }
}

- (void) displayLinkDidFire
{
    if ([CLLocationManager locationServicesEnabled])
    {
        if (_state == LocationControllerStateForecast && _view != nil && self->lastLocation != nil
                && [self locationMeetsCriteria:self->lastLocation])
        {
            // This controller has a last known location that meets its accuracy criteria. Forecast the current location
            // from the last known location, then forward the forecast location to updateViewWithForecastLocation.
            // Forecasting in a display link enables the controller to generate intermediate locations at sub-second
            // intervals between Core Location service's 1-2 second updates.
            NSDate* now = [NSDate date];
            WWGlobe* globe = [[_view sceneController] globe];
            [WWLocation forecastLocation:self->lastLocation forDate:now withGobe:globe outputLocation:self->forecastLocation];
            [self updateViewWithForecastLocation:self->forecastLocation];
        }
    }
    else
    {
        // The Core Location service has been disabled while this application has been in the background. In either case
        // set this controller's state to disabled in order to stop attempting to use Core Location services.
        [self setState:LocationControllerStateDisabled];
    }
}

@end