/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.

@version $Id$
 */

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import "WorldWind/WorldWindView.h"

extern NSString* const TRACKING_CONTROLLER_STATE_CHANGED;

@interface TrackingController : NSObject <CLLocationManagerDelegate>

@property (nonatomic, readonly) WorldWindView* view;

@property (nonatomic, getter=isEnabled) BOOL enabled;

- (TrackingController*) initWithView:(WorldWindView*)view;

@end