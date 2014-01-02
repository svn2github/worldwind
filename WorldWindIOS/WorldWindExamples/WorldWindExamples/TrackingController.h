/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.

@version $Id$
 */

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import "WorldWind/Layer/WWRenderableLayer.h"

@class WWPosition;
@class WorldWindView;

#define WWX_CURRENT_POSITION (@"gov.nasa.worldwindx.currentposition")

//--------------------------------------------------------------------------------------------------------------------//
//-- Location Services Controller --//
//--------------------------------------------------------------------------------------------------------------------//

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

//--------------------------------------------------------------------------------------------------------------------//
//-- Current Position Layer --//
//--------------------------------------------------------------------------------------------------------------------//

@interface CurrentPositionLayer : WWRenderableLayer
{
@protected
    CLLocation* currentLocation;
    WWPosition* forecastPosition;
}

@property (nonatomic, readonly) id marker;

- (CurrentPositionLayer*) init;

@end

//--------------------------------------------------------------------------------------------------------------------//
//-- Navigation Controller --//
//--------------------------------------------------------------------------------------------------------------------//

@interface NavigationController : NSObject
{
@protected
    CLLocation* currentLocation;
    WWPosition* forecastPosition;
    WWPosition* smoothedPosition;
    BOOL followingPosition;
}

@property (nonatomic, readonly) WorldWindView* wwv;

@property (nonatomic) BOOL enabled;

- (NavigationController*) initWithView:(WorldWindView*)wwv;

@end

//--------------------------------------------------------------------------------------------------------------------//
//-- Tracking Controller --//
//--------------------------------------------------------------------------------------------------------------------//

@interface TrackingController : NSObject

@property (nonatomic, readonly) WorldWindView* wwv;

@property (nonatomic) BOOL enabled;

- (TrackingController*) initWithView:(WorldWindView*)wwv;

@end