/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.

 @version $Id$
 */

#import <Foundation/Foundation.h>

@class AircraftMarker;
@class FlightRoute;
@class WWPosition;
@class WorldWindView;
@class WWRenderableLayer;

@interface SimulationViewController : UIViewController
{
@protected
    UISlider* aircraftSlider;
    WWRenderableLayer* aircraftLayer;
    AircraftMarker* aircraftMarker;
}

@property (nonatomic, readonly) UIBarButtonItem* doneButtonItem;

@property (nonatomic, readonly) WorldWindView* wwv;

@property (nonatomic) FlightRoute* flightRoute;

- (SimulationViewController*) initWithWorldWindView:(WorldWindView*)wwv;

@end
