/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.

 @version $Id$
 */

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

#define WW_CURRENT_POSITION (@"gov.nasa.worldwind.currentposition")

typedef enum
{
    LocationServicesControllerModeDisabled,
    LocationServicesControllerModeSignificantChanges,
    LocationServicesControllerModeAllChanges
} LocationServicesControllerMode;

@interface LocationServicesController : NSObject<CLLocationManagerDelegate>
{
@protected
    CLLocationManager* locationManager;
    CLLocation* currentLocation;
}

@property (nonatomic) LocationServicesControllerMode mode;

- (LocationServicesController*) init;

@end