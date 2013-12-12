/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.

 @version $Id$
 */

#import "SimulationViewController.h"
#import "AircraftMarker.h"
#import "AppConstants.h"
#import "FlightRoute.h"
#import "WorldWind/Render/WWSceneController.h"
#import "WorldWind/Layer/WWLayerList.h"
#import "WorldWind/Layer/WWRenderableLayer.h"
#import "WorldWind/WorldWindConstants.h"
#import "WorldWind/WorldWindView.h"

//--------------------------------------------------------------------------------------------------------------------//
//-- AircraftSlider --//
//--------------------------------------------------------------------------------------------------------------------//

static const CGFloat AircraftSliderHeight = 4;

@interface AircraftSlider : UISlider
@end

@implementation AircraftSlider

- (CGRect) trackRectForBounds:(CGRect)bounds
{
    CGRect rect = [super trackRectForBounds:bounds];
    CGFloat dh = AircraftSliderHeight - CGRectGetHeight(rect);
    rect.size.height = AircraftSliderHeight;
    rect.origin.y -= dh / 2;

    return rect;
}

@end

//--------------------------------------------------------------------------------------------------------------------//
//-- SimulationViewController --//
//--------------------------------------------------------------------------------------------------------------------//

@implementation SimulationViewController

//--------------------------------------------------------------------------------------------------------------------//
//-- Initializing SimulationViewController --//
//--------------------------------------------------------------------------------------------------------------------//

// TODO: Handle fight route deleted.
- (SimulationViewController*) initWithWorldWindView:(WorldWindView*)wwv
{
    self = [super initWithNibName:nil bundle:nil];

    _doneButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                                    target:self
                                                                    action:@selector(handleDoneButton)];
    [[self navigationItem] setRightBarButtonItem:_doneButtonItem];

    _wwv = wwv;

    simulationLayer = simulationLayer = [[WWRenderableLayer alloc] init];
    [[simulationLayer userTags] setObject:@"" forKey:TAIGA_HIDDEN_LAYER];
    [simulationLayer setEnabled:NO];
    [[[_wwv sceneController] layers] addLayer:simulationLayer];

    aircraftMarker = [[AircraftMarker alloc] init];
    [simulationLayer addRenderable:aircraftMarker];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleFlightRouteNotification:)
                                                 name:TAIGA_FLIGHT_ROUTE_CHANGED object:nil];

    return self;
}

//--------------------------------------------------------------------------------------------------------------------//
//-- Flight Route --//
//--------------------------------------------------------------------------------------------------------------------//

- (void) setFlightRoute:(FlightRoute*)flightRoute
{
    if (_flightRoute == flightRoute)
        return;

    _flightRoute = flightRoute;

    // Set the aircraft slider to the beginning of the flight route and update the simulation UI elements to match the
    // new flight route.
    [aircraftSlider setValue:0];
    [self handleFightRouteChanged];
}

- (void) handleFlightRouteNotification:(NSNotification*)notification
{
    FlightRoute* flightRoute = [notification object];
    if (flightRoute == _flightRoute)
    {
        [self handleFightRouteChanged];
    }
}

//--------------------------------------------------------------------------------------------------------------------//
//-- View Control Events --//
//--------------------------------------------------------------------------------------------------------------------//

- (void) handleDoneButton
{
}

- (void) handleAircraftSlider
{
    double pct = [aircraftSlider value];
    [_flightRoute positionForPercent:pct result:[aircraftMarker position]];

    [[NSNotificationCenter defaultCenter] postNotificationName:WW_REQUEST_REDRAW object:self];
}

- (void) handleFightRouteChanged
{
    // Set the navigator item title to flight route display name + " Simulation". This sets the title to nil if the
    // flight route is nil.
    NSString* title = [[_flightRoute displayName] stringByAppendingString:@" Simulation"];
    [[self navigationItem] setTitle:title];

    // Set the aircraft marker's position to the percentage along the flight route corresponding to the current aircraft
    // slider value. This has no effect on the aircraft marker if the flight route is nil. Disable the simulation layer
    // if the flight route is nil or has no waypoints.
    [_flightRoute positionForPercent:[aircraftSlider value] result:[aircraftMarker position]];
    [simulationLayer setEnabled:_flightRoute != nil && [_flightRoute waypointCount] > 0];

    [[NSNotificationCenter defaultCenter] postNotificationName:WW_REQUEST_REDRAW object:self];
}

//--------------------------------------------------------------------------------------------------------------------//
//-- View Layout --//
//--------------------------------------------------------------------------------------------------------------------//

- (void) loadView
{
    UIView* view = [[UIView alloc] init];
    [view setAutoresizingMask:UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight];
    [view setBackgroundColor:[UIColor colorWithWhite:0.8 alpha:1]];
    [view setAlpha:0.95];
    [self setView:view];

    aircraftSlider = [[AircraftSlider alloc] init];
    [aircraftSlider addTarget:self action:@selector(handleAircraftSlider) forControlEvents:UIControlEventValueChanged];
    [aircraftSlider setMinimumTrackTintColor:[UIColor whiteColor]];
    [aircraftSlider setMaximumTrackTintColor:[UIColor blackColor]];
    [aircraftSlider setMinimumValueImage:[UIImage imageNamed:@"route-begin"]];
    [aircraftSlider setMaximumValueImage:[UIImage imageNamed:@"route-end"]];
    [view addSubview:aircraftSlider];

    [self layout];
}

- (void) layout
{
    UIView* view = [self view];
    id topGuide = [self topLayoutGuide];
    NSDictionary* viewsDictionary = NSDictionaryOfVariableBindings(aircraftSlider, topGuide);

    // Disable automatic translation of autoresizing mask into constraints. We're using explicit layout constraints
    // below.
    [aircraftSlider setTranslatesAutoresizingMaskIntoConstraints:NO];
    [view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-100-[aircraftSlider]-100-|"
                                                                 options:0 metrics:nil views:viewsDictionary]];
    [view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[topGuide]-20-[aircraftSlider]"
                                                                 options:0 metrics:nil views:viewsDictionary]];
}

@end