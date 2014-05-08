/*
 Copyright (C) 2014 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import <CoreLocation/CoreLocation.h>
#import "LocationServicesController.h"
#import "AppConstants.h"

#define LOCATION_REQUIRED_ACCURACY (100.0)
#define LOCATION_REQUIRED_AGE (2.0)

@implementation LocationServicesController

- (LocationServicesController*) init
{
    self = [super init];

    _mode = LocationServicesControllerModeDisabled;

    locationManager = [[CLLocationManager alloc] init];
    [locationManager setActivityType:CLActivityTypeOtherNavigation];
    [locationManager setDesiredAccuracy:kCLLocationAccuracyBestForNavigation];
    [locationManager setDelegate:self];

    [self setMode:LocationServicesControllerModeSignificantChanges];

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
    [[NSNotificationCenter defaultCenter] postNotificationName:TAIGA_CURRENT_AIRCRAFT_POSITION object:currentLocation];
}

@end