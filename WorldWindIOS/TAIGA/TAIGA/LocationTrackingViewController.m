/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.

 @version $Id$
 */

#import "LocationTrackingViewController.h"
#import "Settings.h"
#import "AppConstants.h"
#import "WorldWind/Geometry/WWLocation.h"
#import "WorldWind/Geometry/WWPosition.h"
#import "WorldWind/Navigate/WWFirstPersonNavigator.h"
#import "WorldWind/Navigate/WWLookAtNavigator.h"
#import "WorldWind/Render/WWSceneController.h"
#import "WorldWind/Util/WWMath.h"
#import "WorldWind/WorldWindView.h"

#define LOCATION_SMOOTHING_AMOUNT (0.8)
#define HEADING_SMOOTHING_AMOUNT (0.4)
#define VIEW_TAG_BUTTON 1

@implementation LocationTrackingViewController

- (LocationTrackingViewController*) initWithView:(WorldWindView*)wwv
{
    self = [super init];

    _mode = [Settings getObjectForName:TAIGA_LOCATION_TRACKING_MODE defaultValue:TAIGA_DEFAULT_LOCATION_TRACKING_MODE];
    _wwv = wwv;

    [self setupLocationTrackingNavigator];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(locationTrackingModeDidChange:)
                                                 name:TAIGA_SETTING_CHANGED object:TAIGA_LOCATION_TRACKING_MODE];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(aircraftPositionDidChange:)
                                                 name:TAIGA_CURRENT_AIRCRAFT_POSITION object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(simulationWillBegin:)
                                                 name:TAIGA_SIMULATION_WILL_BEGIN object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(simulationWillEnd:)
                                                 name:TAIGA_SIMULATION_WILL_END object:nil];

    return self;
}

- (void) setEnabled:(BOOL)enabled
{
    if (_enabled == enabled)
        return;

    _enabled = enabled;
    forecastPosition = nil;
    smoothedPosition = nil;
    smoothedHeading = DBL_MAX;
    trackingLocation = NO;

    if (_enabled)
    {
        [self startLocationTracking];
    }
    else
    {
        [self stopLocationTracking];
    }

    [self updateView];
}

//--------------------------------------------------------------------------------------------------------------------//
//-- Notifications --//
//--------------------------------------------------------------------------------------------------------------------//

- (void) locationTrackingModeDidChange:(NSNotification*)notification
{
    _mode = [Settings getObjectForName:TAIGA_LOCATION_TRACKING_MODE];
    currentHeading = [_mode isEqualToString:TAIGA_LOCATION_TRACKING_MODE_NORTH_UP] ? 0 : [currentLocation course];

    [self setupLocationTrackingNavigator]; // Setup a new navigator according ot the location tracking mode.

    if (_enabled)
    {
        [self resumeLocationTracking]; // Resume location tracking with the new navigator.
    }
}

- (void) aircraftPositionDidChange:(NSNotification*)notification
{
    CLLocation* oldLocation = currentLocation;
    CLLocation* newLocation = [notification object];
    currentLocation = newLocation;
    currentHeading = [_mode isEqualToString:TAIGA_LOCATION_TRACKING_MODE_NORTH_UP] ? 0 : [newLocation course];

    if (_enabled && oldLocation == nil)
    {
        [self resumeLocationTracking]; // We have an initial location fix; resume location tracking.
    }
}

- (void) simulationWillBegin:(NSNotification*)notification
{
    [self suspendLocationTracking]; // Suspend location tracking until we have a simulated location fix.
}

- (void) simulationWillEnd:(NSNotification*)notification
{
    [self suspendLocationTracking]; // Suspend location tracking until we have an actual location fix.
}

//--------------------------------------------------------------------------------------------------------------------//
//-- World Wind Navigation --//
//--------------------------------------------------------------------------------------------------------------------//

- (void) startLocationTracking
{
    if (currentLocation == nil) // Wait to start tracking until we have a location fix.
        return;

    // Animate the navigator to the most recent location. During this animation the location continues to update, but
    // this makes no additional changes to the navigator until the animation completes.
    [[_wwv navigator] animateWithDuration:WWNavigatorDurationAutomatic animations:^
    {
        NSDate* now = [NSDate date];
        [self doTrackLocationWithDate:now];
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
        [self trackLocation];
    }];
}

- (void) stopLocationTracking
{
    [[_wwv navigator] stopAnimations]; // interrupts animations performed by this controller
}

- (void) suspendLocationTracking
{
    currentLocation = nil;
    forecastPosition = nil;
    smoothedPosition = nil;
    currentHeading = 0;
    smoothedHeading = DBL_MAX;
    trackingLocation = NO;
}

- (void) resumeLocationTracking
{
    if (trackingLocation)
    {
        [self trackLocation];
    }
    else
    {
        [self startLocationTracking];
    }
}

- (void) trackLocation
{
    // Animate the navigator to the current position until the animation is interrupted either by this controller
    // changing modes, another object initiating an animation, or by the user performing a navigation gesture.
    trackingLocation = YES;
    [[_wwv navigator] animateWithBlock:^(NSDate* timestamp, BOOL* stop)
    {
        // Stop animating when this controller is disabled or location tracking has been suspended.
        *stop = !_enabled || !trackingLocation;
        if (!*stop)
        {
            [self doTrackLocationWithDate:timestamp];
        }
    } completion:^(BOOL finished)
    {
        trackingLocation = NO;

        // Disable this controller when its navigator animation is interrupted. The user has performed a navigation
        // gesture, or another object has initiated an animation at the user's request.
        if (!finished)
        {
            [self setEnabled:NO];
        }
    }];
}

- (void) doTrackLocationWithDate:(NSDate*)date
{
    // Forecast the current location from the most recent location, then smooth the forecast location and smooth the
    // current heading. Forecasting and smoothing in an animation block enables generation of intermediate locations
    // and headings at sub-second intervals between location updates and eliminates jarring navigator changes.
    [self forecastCurrentLocationWithDate:date];
    [self smoothForecastLocation];

    if ([_mode isEqualToString:TAIGA_LOCATION_TRACKING_MODE_COCKPIT])
    {
        [(WWFirstPersonNavigator*) [_wwv navigator] setEyePosition:smoothedPosition];
        [[_wwv navigator] setHeading:smoothedHeading];
        [[_wwv navigator] setTilt:75];
        [[_wwv navigator] setRoll:0];
    }
    else
    {
        double radius = 1000 + [smoothedPosition altitude];
        [[_wwv navigator] setCenterLocation:smoothedPosition radius:radius];
        [[_wwv navigator] setHeading:smoothedHeading];
        [[_wwv navigator] setTilt:0];
        [[_wwv navigator] setRoll:0];
    }
}

- (void) setupLocationTrackingNavigator
{
    id<WWNavigator> oldNavigator = [_wwv navigator];
    id<WWNavigator> newNavigator = [_mode isEqualToString:TAIGA_LOCATION_TRACKING_MODE_COCKPIT] ?
            [[WWFirstPersonNavigator alloc] initWithView:_wwv navigatorToMatch:oldNavigator] :
            [[WWLookAtNavigator alloc] initWithView:_wwv navigatorToMatch:oldNavigator];
    [oldNavigator dispose];
    [_wwv setNavigator:newNavigator];
    [WorldWindView requestRedraw];
}

//--------------------------------------------------------------------------------------------------------------------//
//-- Location Forecasting --//
//--------------------------------------------------------------------------------------------------------------------//

- (void) forecastCurrentLocationWithDate:(NSDate*)date
{
    if (forecastPosition == nil)
    {
        forecastPosition = [[WWPosition alloc] initWithZeroPosition];
    }

    WWGlobe* globe = [[_wwv sceneController] globe];
    [WWPosition forecastPosition:currentLocation forDate:date onGlobe:globe outputPosition:forecastPosition];
}

- (void) smoothForecastLocation
{
    if (smoothedPosition == nil)
    {
        smoothedPosition = [[WWPosition alloc] initWithPosition:forecastPosition];
        smoothedHeading = currentHeading;
    }
    else
    {
        [WWPosition greatCircleInterpolate:smoothedPosition
                               endLocation:forecastPosition
                                    amount:LOCATION_SMOOTHING_AMOUNT
                            outputLocation:smoothedPosition]; // Input position can be reused to store the output.
        [smoothedPosition setAltitude:[WWMath interpolateValue1:[smoothedPosition altitude]
                                                         value2:[forecastPosition altitude]
                                                         amount:LOCATION_SMOOTHING_AMOUNT]];
        smoothedHeading = [WWMath interpolateDegrees1:smoothedHeading
                                             degrees2:currentHeading
                                               amount:HEADING_SMOOTHING_AMOUNT];
    }
}

//--------------------------------------------------------------------------------------------------------------------//
//-- View Layout --//
//--------------------------------------------------------------------------------------------------------------------//

- (void) loadView
{
    UIView* view = [[UIView alloc] init];
    [view setBackgroundColor:[UIColor colorWithWhite:0.8 alpha:1]];
    [view setAlpha:0.95];
    [self setView:view];

    // Provide a resizable rounded rectangle background image. This image will be stretched to fill the view's bounds
    // while keeping the 5 pixel rounded corners intact.
    UIImage* backgroundImage = [[[UIImage imageNamed:@"rounded-rect.png"]
            resizableImageWithCapInsets:UIEdgeInsetsMake(5, 5, 5, 5) resizingMode:UIImageResizingModeStretch]
            imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    UIImageView* backgroundView = [[UIImageView alloc] initWithImage:backgroundImage];
    [backgroundView setTintColor:[UIColor colorWithWhite:0.8 alpha:1]];
    [view addSubview:backgroundView];

    enabledImage = [[UIImage imageNamed:@"193-location-arrow"]
            imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    disabledImage = [[UIImage imageNamed:@"193-location-arrow-outline"]
            imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    UIImage* buttonImage = _enabled ? enabledImage : disabledImage;
    UIButton* button = [[UIButton alloc] init];
    [button setTag:VIEW_TAG_BUTTON];
    [button setContentEdgeInsets:UIEdgeInsetsMake(10, 10, 10, 10)];
    [button setImage:buttonImage forState:UIControlStateNormal];
    [button addTarget:self action:@selector(buttonTapped) forControlEvents:UIControlEventTouchUpInside];
    [view addSubview:button];

    NSDictionary* viewsDictionary = NSDictionaryOfVariableBindings(backgroundView, button);
    [backgroundView setTranslatesAutoresizingMaskIntoConstraints:NO];
    [button setTranslatesAutoresizingMaskIntoConstraints:NO];

    [view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[backgroundView(==button)]|" options:0 metrics:nil views:viewsDictionary]];
    [view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[backgroundView(==button)]|" options:0 metrics:nil views:viewsDictionary]];
    [view addConstraint:[NSLayoutConstraint constraintWithItem:button attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual
                                                        toItem:view attribute:NSLayoutAttributeCenterX multiplier:1 constant:0]];
    [view addConstraint:[NSLayoutConstraint constraintWithItem:button attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual
                                                        toItem:view attribute:NSLayoutAttributeCenterY multiplier:1 constant:0]];
}

- (void) updateView
{
    UIImage* buttonImage = _enabled ? enabledImage : disabledImage;
    [(UIButton*) [[self view] viewWithTag:VIEW_TAG_BUTTON] setImage:buttonImage forState:UIControlStateNormal];
}

- (void) buttonTapped
{
    [self setEnabled:!_enabled];
}

@end