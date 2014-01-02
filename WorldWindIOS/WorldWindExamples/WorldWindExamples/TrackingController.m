/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.

@version $Id$
 */

#import "TrackingController.h"
#import "WorldWind/Geometry/WWLocation.h"
#import "WorldWind/Geometry/WWPosition.h"
#import "WorldWind/Layer/WWLayerList.h"
#import "WorldWind/Navigate/WWNavigator.h"
#import "WorldWind/Render/WWDrawContext.h"
#import "WorldWind/Render/WWSceneController.h"
#import "WorldWind/Shapes/WWPath.h"
#import "WorldWind/Shapes/WWShapeAttributes.h"
#import "WorldWind/Shapes/WWSphere.h"
#import "WorldWind/Terrain/WWGlobe.h"
#import "WorldWind/Util/WWColor.h"
#import "WorldWind/WorldWindView.h"
#import "Worldwind/WorldWindConstants.h"

//--------------------------------------------------------------------------------------------------------------------//
//-- Location Services Controller --//
//--------------------------------------------------------------------------------------------------------------------//

#define LOCATION_REQUIRED_ACCURACY 100.0
#define LOCATION_REQUIRED_AGE 2.0

@implementation LocationServicesController

- (LocationServicesController*) init
{
    self = [super init];

    _mode = LocationServicesControllerModeDisabled;

    locationManager = [[CLLocationManager alloc] init];
    [locationManager setActivityType:CLActivityTypeOtherNavigation];
    [locationManager setDesiredAccuracy:kCLLocationAccuracyBestForNavigation];
    [locationManager setDelegate:self];

    return self;
}

- (void) setMode:(LocationServicesControllerMode)mode
{
    if (_mode == mode)
        return;

    if (mode == LocationServicesControllerModeDisabled)
    {
        if (_mode == LocationServicesControllerModeSignificantChanges)
        {
            [locationManager stopMonitoringSignificantLocationChanges];
        }
        else if (_mode == LocationServicesControllerModeAllChanges)
        {
            [locationManager stopUpdatingLocation];
        }
    }
    else if (mode == LocationServicesControllerModeSignificantChanges)
    {
        if (![CLLocationManager locationServicesEnabled])
            return;

        [locationManager startMonitoringSignificantLocationChanges];
    }
    else if (mode == LocationServicesControllerModeAllChanges)
    {
        if (![CLLocationManager locationServicesEnabled])
            return;

        [locationManager startUpdatingLocation];
    }

    _mode = mode;
}

- (void) locationManager:(CLLocationManager*)manager didUpdateLocations:(NSArray*)locations
{
    // Disable the controller if the Core Location service has been disabled while this application was in the
    // background.
    if (![CLLocationManager locationServicesEnabled])
    {
        [self setMode:LocationServicesControllerModeDisabled];
    }

    CLLocation* location = [locations lastObject]; // The last list item contains the most recent location.
    if ([self locationMeetsCriteria:location])
    {
        currentLocation = [location copy];
        [self postCurrentPosition];
    }
}

- (void) locationManager:(CLLocationManager*)manager didFailWithError:(NSError*)error
{
    // Disable the controller if this application has been denied access to location services. This can happen either
    // when the application first attempts to use Core Location services or while the application was in the
    // background.
    if ([error code] == kCLErrorDenied)
    {
        [self setMode:LocationServicesControllerModeDisabled];
    }
}

- (BOOL) locationMeetsCriteria:(CLLocation*)location
{
    if (_mode == LocationServicesControllerModeAllChanges)
    {
        return [location horizontalAccuracy] <= LOCATION_REQUIRED_ACCURACY
                && fabs([[location timestamp] timeIntervalSinceNow]) <= LOCATION_REQUIRED_AGE;
    }

    return YES;
}

- (void) postCurrentPosition
{
    [[NSNotificationCenter defaultCenter] postNotificationName:WWX_CURRENT_POSITION object:currentLocation];
}

@end

//--------------------------------------------------------------------------------------------------------------------//
//-- Current Position Layer --//
//--------------------------------------------------------------------------------------------------------------------//

#define MARKER_ALTITUDE_OFFSET (10.0)

@implementation CurrentPositionLayer

- (CurrentPositionLayer*) init
{
    self = [super init];

    [self setDisplayName:@"Current Position"];
    [self setEnabled:NO]; // disable the marker until we have a valid aircraft position

    _marker = [self createMarker];
    [self addRenderable:_marker];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(currentPositionDidChange:)
                                                 name:WWX_CURRENT_POSITION object:nil];

    return self;
}

- (id) createMarker
{
    WWShapeAttributes* attrs = [[WWShapeAttributes alloc] init];
    [attrs setInteriorColor:[[WWColor alloc] initWithR:.24 g:.47 b:.99 a:1]];

    WWSphere* shape = [[WWSphere alloc] initWithPosition:[[WWPosition alloc] init] radiusInPixels:5];
    [shape setAttributes:attrs];

    return shape;
}

- (void) updateMarker:(id)marker withPosition:(WWPosition*)position
{
    if ([position altitude] == 0)
    {
        WWPosition* pos = [[WWPosition alloc] initWithLocation:position altitude:[position altitude] + MARKER_ALTITUDE_OFFSET];
        [(WWSphere*) marker setPosition:pos];
        [(WWSphere*) marker setAltitudeMode:WW_ALTITUDE_MODE_RELATIVE_TO_GROUND];
    }
    else
    {
        WWPosition* pos = [[WWPosition alloc] initWithLocation:position altitude:[position altitude]];
        [(WWSphere*) marker setPosition:pos];
        [(WWSphere*) marker setAltitudeMode:WW_ALTITUDE_MODE_ABSOLUTE];
    }
}

- (void) doRender:(WWDrawContext*)dc
{
    [self forecastCurrentLocationWithDate:[dc timestamp] onGlobe:[dc globe]];
    [self updateMarker:_marker withPosition:forecastPosition];

    [super doRender:dc];
}

- (void) currentPositionDidChange:(NSNotification*)notification
{
    if (![self enabled]) // display this layer once we have a fix on the current location
    {
        [self setEnabled:YES];
    }

    currentLocation = [notification object];
    [[NSNotificationCenter defaultCenter] postNotificationName:WW_REQUEST_REDRAW object:self];
}

- (void) forecastCurrentLocationWithDate:(NSDate*)date onGlobe:(WWGlobe*)globe
{
    if (forecastPosition == nil)
    {
        forecastPosition = [[WWPosition alloc] initWithZeroPosition];
    }

    [WWPosition forecastPosition:currentLocation forDate:date onGlobe:globe outputPosition:forecastPosition];
}

@end

//--------------------------------------------------------------------------------------------------------------------//
//-- Navigation Controller --//
//--------------------------------------------------------------------------------------------------------------------//

#define LOCATION_SMOOTHING_AMOUNT (0.1)

@implementation NavigationController

- (NavigationController*) initWithView:(WorldWindView*)wwv
{
    self = [super init];

    _wwv = wwv;

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(currentPositionDidChange:)
                                                 name:WWX_CURRENT_POSITION object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(navigatorDidChange)
                                                 name:WW_NAVIGATOR_CHANGED object:nil];

    return self;
}

- (void) setEnabled:(BOOL)enabled
{
    if (_enabled == enabled)
        return;

    _enabled = enabled;
    forecastPosition = nil;
    smoothedPosition = nil;
    followingPosition = NO;

    if (currentLocation == nil) // wait to start following until we have a location
        return;

    if (_enabled)
    {
        [self startFollowingCurrentPosition];
    }
    else if (!_enabled)
    {
        [[_wwv navigator] stopAnimations]; // interrupts animations performed by this controller
    }
}

- (void) currentPositionDidChange:(NSNotification*)notification
{
    BOOL isFirstLocation = (currentLocation == nil);
    currentLocation = [notification object];

    if (!isFirstLocation)
        return;

    if (_enabled)
    {
        [self startFollowingCurrentPosition];
    }
    else
    {
        [self centerOnCurrentLocation];
    }
}

- (void) navigatorDidChange
{
    if (!_enabled)
        return;

    if (followingPosition)
    {
        [self followCurrentPosition];
    }
    else
    {
        [self startFollowingCurrentPosition];
    }
}

- (void) startFollowingCurrentPosition
{
    // Animate the navigator to the most recent location. During this animation the location continues to update, but
    // this makes no additional changes to the navigator until the animation completes.
    [[_wwv navigator] animateWithDuration:WWNavigatorDurationAutomatic animations:^
    {
        WWLocation* location = [[WWLocation alloc] initWithCLLocation:currentLocation];
        double radius = 250;
        [[_wwv navigator] setCenterLocation:location radius:radius];
    } completion:^(BOOL finished)
    {
        // Disable this controller when its navigator animation is interrupted. The user has performed a navigation
        // gesture, or another object has initiated an animation at the user's request.
        if (!finished)
        {
            [self setEnabled:NO];
            return;
        }

        // Start an animation to keep the current location in view until this controller is disabled or interrupted.
        [self followCurrentPosition];
    }];
}

- (void) followCurrentPosition
{
    // Animate the navigator to the current position until the animation is interrupted either by this controller
    // changing modes, another object initiating an animation, or by the user performing a navigation gesture.
    followingPosition = YES;
    [[_wwv navigator] animateWithBlock:^(NSDate* timestamp, BOOL* stop)
    {
        // Forecast the current location from the most recent location, then smooth the forecast location. Forecasting
        // and smoothing in a display link enables generation of intermediate locations at sub-second intervals between
        // Core Location's 1-2 second updates and eliminates jarring navigator changes.
        [self forecastCurrentLocationWithDate:timestamp];
        [self smoothForecastLocationWithAmount:LOCATION_SMOOTHING_AMOUNT];
        [[_wwv navigator] setCenterLocation:smoothedPosition];
        *stop = NO;
    } completion:^(BOOL finished)
    {
        // Disable this controller when its navigator animation is interrupted. The user has performed a navigation
        // gesture, or another object has initiated an animation at the user's request.
        [self setEnabled:NO];
    }];
}

- (void) centerOnCurrentLocation
{
    // Animate the navigator to the most recent location without zooming in.
    [[_wwv navigator] animateWithDuration:1 animations:^
    {
        WWLocation* location = [[WWLocation alloc] initWithCLLocation:currentLocation];
        [[_wwv navigator] setCenterLocation:location];
    }];
}

- (void) forecastCurrentLocationWithDate:(NSDate*)date
{
    if (forecastPosition == nil)
    {
        forecastPosition = [[WWPosition alloc] initWithZeroPosition];
    }

    WWGlobe* globe = [[_wwv sceneController] globe];
    [WWPosition forecastPosition:currentLocation forDate:date onGlobe:globe outputPosition:forecastPosition];
}

- (void) smoothForecastLocationWithAmount:(double)amount
{
    if (smoothedPosition == nil)
    {
        smoothedPosition = [[WWPosition alloc] initWithPosition:forecastPosition];
        return;
    }

    [WWPosition greatCircleInterpolate:smoothedPosition
                           endLocation:forecastPosition
                                amount:amount
                        outputLocation:smoothedPosition]; // Input position can be reused to store the output.
}

@end

//--------------------------------------------------------------------------------------------------------------------//
//-- Tracking Controller --//
//--------------------------------------------------------------------------------------------------------------------//

@implementation TrackingController
{
@protected
    LocationServicesController* locationServicesController;
    NavigationController* navigationController;
    CurrentPositionLayer* currentPositionLayer;
}

- (TrackingController*) initWithView:(WorldWindView*)wwv
{
    self = [super init];

    _wwv = wwv;

    locationServicesController = [[LocationServicesController alloc] init];
    [locationServicesController setMode:LocationServicesControllerModeSignificantChanges];

    navigationController = [[NavigationController alloc] initWithView:_wwv];
    [navigationController addObserver:self forKeyPath:@"enabled"
                              options:NSKeyValueObservingOptionInitial|NSKeyValueObservingOptionNew context:NULL];

    currentPositionLayer = [[CurrentPositionLayer alloc] init];
    [[[_wwv sceneController] layers] addLayer:currentPositionLayer];

    return self;
}

- (void) setEnabled:(BOOL)enabled
{
    if (_enabled == enabled)
        return;

    _enabled = enabled;
    [locationServicesController setMode:enabled ? LocationServicesControllerModeAllChanges : LocationServicesControllerModeSignificantChanges];
    [navigationController setEnabled:enabled];
}

- (void) observeValueForKeyPath:(NSString*)keyPath
                       ofObject:(id)object
                         change:(NSDictionary*)change
                        context:(void*)context
{
    BOOL enabled = [[change objectForKey:NSKeyValueChangeNewKey] boolValue];
    [self setEnabled:enabled];
}

@end