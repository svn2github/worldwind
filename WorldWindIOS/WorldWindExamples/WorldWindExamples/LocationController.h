/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.

@version $Id$
 */

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import "WorldWind/WorldWindView.h"

typedef enum
{
    LocationControllerStateDisabled,
    LocationControllerStateShowInitial,
    LocationControllerStateForecast
} LocationControllerState;

@interface LocationController : NSObject <CLLocationManagerDelegate>

@property (nonatomic) WorldWindView* view;

@property (nonatomic) LocationControllerState state;

@end