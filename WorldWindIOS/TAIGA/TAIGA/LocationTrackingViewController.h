/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.

 @version $Id$
 */

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

@class WorldWindView;
@class WWPosition;

@interface LocationTrackingViewController : UIViewController
{
@protected
    // Location tracking properties.
    BOOL trackingLocation;
    CLLocation* currentLocation;
    double currentCockpitTilt;
    double currentTrackUpTilt;
    double currentRange;
    // View properties
    UIImage* enabledImage;
    UIImage* disabledImage;
}

@property (nonatomic) BOOL enabled;

@property (nonatomic, readonly) id mode;

@property (nonatomic, readonly) WorldWindView* wwv;

- (LocationTrackingViewController*) initWithView:(WorldWindView*)wwv;

@end