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
#import "WorldWind/Util/WWMath.h"
#import "WorldWind/WorldWindView.h"

#define BUTTON_VIEW_TAG (1)
#define COCKPIT_DEFAULT_TILT (70)
#define COCKPIT_MIN_TILT (65)
#define COCKPIT_MAX_TILT (90)
#define HEADING_SMOOTHING_AMOUNT (0.4)
#define MIN_RANGE (1)
#define MAX_RANGE (6000000)
#define TRACK_UP_MIN_TILT (0)
#define TRACK_UP_MAX_TILT (45)

@implementation LocationTrackingViewController

- (LocationTrackingViewController*) initWithView:(WorldWindView*)wwv
{
    self = [super init];

    _mode = [Settings getObjectForName:TAIGA_LOCATION_TRACKING_MODE defaultValue:TAIGA_DEFAULT_LOCATION_TRACKING_MODE];
    _wwv = wwv;

    [self setupTrackingNavigator];

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

    if (_enabled)
    {
        [self captureTrackingNavigatorState];
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
    [self setupTrackingNavigator]; // Setup a new navigator according ot the location tracking mode.

    if (_enabled)
    {
        [self startLocationTracking]; // Restart location tracking with the new navigator.
    }
}

- (void) aircraftPositionDidChange:(NSNotification*)notification
{
    currentLocation = [notification object];

    if (_enabled && !trackingLocation)
    {
        [self startLocationTracking]; // We have been waiting for an initial location fix to start location tracking.
    }
}

- (void) simulationWillBegin:(NSNotification*)notification
{
    currentLocation = nil; // Forget the current actual location.
    [self suspendLocationTracking]; // Suspend location tracking until we have a simulated location fix.
}

- (void) simulationWillEnd:(NSNotification*)notification
{
    currentLocation = nil; // Forget the current simulated location.
    [self suspendLocationTracking]; // Suspend location tracking until we have an actual location fix.
}

//--------------------------------------------------------------------------------------------------------------------//
//-- World Wind Navigation --//
//--------------------------------------------------------------------------------------------------------------------//

- (void) startLocationTracking
{
    [[NSNotificationCenter defaultCenter] postNotificationName:TAIGA_LOCATION_TRACKING_ENABLED object:[NSNumber
            numberWithBool:YES]];

    if (currentLocation == nil) // Wait to start tracking until we have a location fix.
        return;

    // Animate the navigator to the most recent location. During this animation the location continues to update, but
    // this makes no additional changes to the navigator until the animation completes.
    trackingLocation = YES;
    [[_wwv navigator] animateWithDuration:WWNavigatorDurationAutomatic animations:^
    {
        [self doStartLocationTracking];
    }                          completion:^(BOOL finished)
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

    [[NSNotificationCenter defaultCenter] postNotificationName:TAIGA_LOCATION_TRACKING_ENABLED object:[NSNumber
            numberWithBool:NO]];

    [[_wwv navigator] stopAnimations]; // interrupts animations performed by this controller
    trackingLocation = NO;
}

- (void) suspendLocationTracking
{
    trackingLocation = NO;
}

- (void) trackLocation
{
    // Animate the navigator to the current position until the animation is interrupted either by this controller
    // changing modes, another object initiating an animation, or by the user performing a navigation gesture.
    [[_wwv navigator] animateWithBlock:^(NSDate* timestamp, BOOL* stop)
    {
        // Stop animating when this controller is disabled or location tracking has been suspended.
        *stop = !_enabled || !trackingLocation;
        if (!*stop)
        {
            [self doTrackLocation];
        }
    }                       completion:^(BOOL finished)
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

- (void) doStartLocationTracking
{
    if ([_mode isEqualToString:TAIGA_LOCATION_TRACKING_MODE_COCKPIT])
    {
        WWPosition* eyePosition = [[WWPosition alloc] initWithCLPosition:currentLocation];
        [(WWFirstPersonNavigator*) [_wwv navigator] setEyePosition:eyePosition];
        [(WWFirstPersonNavigator*) [_wwv navigator] setHeading:[currentLocation course]];
        [(WWFirstPersonNavigator*) [_wwv navigator] setTilt:currentCockpitTilt];
    }
    else if ([_mode isEqualToString:TAIGA_LOCATION_TRACKING_MODE_NORTH_UP])
    {
        WWLocation* centerLocation = [[WWLocation alloc] initWithCLLocation:currentLocation];
        [(WWLookAtNavigator*) [_wwv navigator] setCenterLocation:centerLocation];
        [(WWLookAtNavigator*) [_wwv navigator] setRange:currentRange];
        [(WWLookAtNavigator*) [_wwv navigator] setHeading:0];
        [(WWLookAtNavigator*) [_wwv navigator] setTilt:0];
    }
    else if ([_mode isEqualToString:TAIGA_LOCATION_TRACKING_MODE_TRACK_UP])
    {
        WWLocation* centerLocation = [[WWLocation alloc] initWithCLLocation:currentLocation];
        [(WWLookAtNavigator*) [_wwv navigator] setCenterLocation:centerLocation];
        [(WWLookAtNavigator*) [_wwv navigator] setRange:currentRange];
        [(WWLookAtNavigator*) [_wwv navigator] setHeading:[currentLocation course]];
        [(WWLookAtNavigator*) [_wwv navigator] setTilt:currentTrackUpTilt];
    }
}

- (void) doTrackLocation
{
    double smoothedHeading = [currentLocation course] < 0 ? [[_wwv navigator] heading] :
            [WWMath interpolateDegrees1:[[_wwv navigator] heading]
                               degrees2:[currentLocation course]
                                 amount:HEADING_SMOOTHING_AMOUNT];

    if ([_mode isEqualToString:TAIGA_LOCATION_TRACKING_MODE_COCKPIT])
    {
        WWPosition* eyePosition = [[WWPosition alloc] initWithCLPosition:currentLocation];
        [(WWFirstPersonNavigator*) [_wwv navigator] setEyePosition:eyePosition];
        [(WWFirstPersonNavigator*) [_wwv navigator] setHeading:smoothedHeading];
    }
    else if ([_mode isEqualToString:TAIGA_LOCATION_TRACKING_MODE_NORTH_UP])
    {
        WWLocation* centerLocation = [[WWLocation alloc] initWithCLLocation:currentLocation];
        [[_wwv navigator] setCenterLocation:centerLocation];
        [[_wwv navigator] setHeading:0];
    }
    else if ([_mode isEqualToString:TAIGA_LOCATION_TRACKING_MODE_TRACK_UP])
    {
        WWLocation* centerLocation = [[WWLocation alloc] initWithCLLocation:currentLocation];
        [[_wwv navigator] setCenterLocation:centerLocation];
        [[_wwv navigator] setHeading:smoothedHeading];
    }
}

- (void) setupTrackingNavigator
{
    id <WWNavigator> oldNavigator = [_wwv navigator];
    id <WWNavigator> newNavigator = [_mode isEqualToString:TAIGA_LOCATION_TRACKING_MODE_COCKPIT] ?
            [[WWFirstPersonNavigator alloc] initWithView:_wwv navigatorToMatch:oldNavigator] :
            [[WWLookAtNavigator alloc] initWithView:_wwv navigatorToMatch:oldNavigator];
    [oldNavigator dispose];
    [_wwv setNavigator:newNavigator];
    [WorldWindView requestRedraw];
}

- (void) captureTrackingNavigatorState
{
    if ([_mode isEqualToString:TAIGA_LOCATION_TRACKING_MODE_COCKPIT])
    {
        currentCockpitTilt = WWCLAMP([[_wwv navigator] tilt], COCKPIT_MIN_TILT, COCKPIT_MAX_TILT);
        currentTrackUpTilt = 0;
        currentRange = [[(WWFirstPersonNavigator*) [_wwv navigator] eyePosition] altitude] * 2;
    }
    else if ([_mode isEqualToString:TAIGA_LOCATION_TRACKING_MODE_NORTH_UP])
    {
        currentCockpitTilt = COCKPIT_DEFAULT_TILT;
        currentTrackUpTilt = 0;
        currentRange = WWCLAMP([(WWLookAtNavigator*) [_wwv navigator] range], MIN_RANGE, MAX_RANGE);
    }
    else if ([_mode isEqualToString:TAIGA_LOCATION_TRACKING_MODE_TRACK_UP])
    {
        currentCockpitTilt = COCKPIT_DEFAULT_TILT;
        currentTrackUpTilt = WWCLAMP([[_wwv navigator] tilt], TRACK_UP_MIN_TILT, TRACK_UP_MAX_TILT);
        currentRange = WWCLAMP([(WWLookAtNavigator*) [_wwv navigator] range], MIN_RANGE, MAX_RANGE);
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
    [button setTag:BUTTON_VIEW_TAG];
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
    [(UIButton*) [[self view] viewWithTag:BUTTON_VIEW_TAG] setImage:buttonImage forState:UIControlStateNormal];
}

- (void) buttonTapped
{
    [self setEnabled:!_enabled];
}

@end