/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.

@version $Id$
 */

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import "WorldWind/WorldWindView.h"

@interface LocationController : NSObject <CLLocationManagerDelegate>
{
@protected
    CLLocationManager* locationManager;
    NSTimeInterval startTime;
}

@property (nonatomic) WorldWindView* view;

@property (nonatomic, getter=isUpdatingLocation) BOOL updatingLocation;

@property (nonatomic, getter=isRepeats) BOOL repeats;

- (void) startUpdatingLocation;

- (void) stopUpdatingLocation;

@end