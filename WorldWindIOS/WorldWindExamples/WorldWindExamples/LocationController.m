/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.

@version $Id$
 */

#import "LocationController.h"
#import "WorldWind/Geometry/WWLocation.h"
#import "WorldWind/Navigate/WWNavigator.h"

#define NON_REPEAT_ACCURACY 1000.0
#define NON_REPEAT_TIMEOUT 2.0

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
    }

    return self;
}

- (void) startUpdatingLocation
{
    if (!_updatingLocation && [CLLocationManager locationServicesEnabled])
    {
        [self->locationManager setDelegate:self];
        [self->locationManager startUpdatingLocation];
        self->startTime = [NSDate timeIntervalSinceReferenceDate];
        _updatingLocation = YES;
    }
}

- (void) stopUpdatingLocation
{
    if (_updatingLocation)
    {
        [self->locationManager setDelegate:nil]; // Suppress location updates in the queue that have not been delivered.
        [self->locationManager stopUpdatingLocation];
        _updatingLocation = NO;
    }
}

- (void) updateViewWithLocation:(WWLocation*)location
{
    if (_view != nil && [_view navigator] != nil) // Ignore a nil view or navigator to avoid unnecessary redraws.
    {
        [[_view navigator] gotoLocation:location];
    }
}

- (void) locationManager:(CLLocationManager*)manager didUpdateLocations:(NSArray*)locations
{
    // We have received a location update from iOS Location Services. If this controller is configured to repeat just
    // update the view with this location. Otherwise, determine whether the location meets either the desired accuracy
    // for an initial fix or enough time has passed that we will use the current location without further updates. In
    // either case we stop updating and update the view with the initial fix.

    CLLocation* clLocation = [locations lastObject];
    WWLocation* wwLocation = [[WWLocation alloc] initWithCLLocation:clLocation];
    NSTimeInterval elapsedTime = [NSDate timeIntervalSinceReferenceDate] - self->startTime;

    if (_repeats)
    {
        [self updateViewWithLocation:wwLocation];
    }
    else if ([clLocation horizontalAccuracy] <= NON_REPEAT_ACCURACY || elapsedTime >= NON_REPEAT_TIMEOUT)
    {
        [self updateViewWithLocation:wwLocation];
        [self stopUpdatingLocation];
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
    // This application has been denied access to location services.
    if ([error code] == kCLErrorDenied)
    {
        [self stopUpdatingLocation];
    }
}

@end