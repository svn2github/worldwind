/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.

@version $Id$
 */

#import "LocationTrackingController.h"
#import "LocationServicesController.h"
#import "WorldWind/Geometry/WWLocation.h"
#import "WorldWind/Geometry/WWPosition.h"
#import "WorldWind/Navigate/WWNavigator.h"
#import "WorldWind/Render/WWSceneController.h"
#import "WorldWind/Terrain/WWGlobe.h"
#import "WorldWind/WorldWindView.h"
#import "Worldwind/WorldWindConstants.h"

#define LOCATION_SMOOTHING_AMOUNT (0.1)

@implementation LocationTrackingController

- (LocationTrackingController*) initWithView:(WorldWindView*)wwv
{
    self = [super init];

    _wwv = wwv;

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(currentPositionDidChange:)
                                                 name:WW_CURRENT_POSITION object:nil];
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
    [[_wwv navigator] animateWithDuration:WWNavigatorDurationAutomatic animations:^
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