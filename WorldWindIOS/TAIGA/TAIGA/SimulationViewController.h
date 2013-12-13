/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.

 @version $Id$
 */

#import <Foundation/Foundation.h>

@class AircraftMarker;
@class FlightRoute;
@class RedrawingSlider;
@class WWPosition;
@class WWRenderableLayer;
@class WorldWindView;

@interface SimulationViewController : UIViewController
{
@protected
    UIButton* doneButton;
    UILabel* titleLabel;
    UISlider* aircraftSlider;
    AircraftMarker* aircraftMarker;
    WWRenderableLayer* simulationLayer;
}

@property (nonatomic, readonly) UIControl* doneControl;

@property (nonatomic, readonly) WorldWindView* wwv;

@property (nonatomic) FlightRoute* flightRoute;

- (SimulationViewController*) initWithWorldWindView:(WorldWindView*)wwv;

@end