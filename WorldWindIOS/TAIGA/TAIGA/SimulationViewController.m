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

// TODO: Handle changes in flight route displayName.
// TODO: Handle changes in flight route altitude.
// TODO: Handle changes in flight route waypoints.
// TODO: Handle flight route with 0 waypoints, or modified to have 0 waypoints.
// TODO: Handle flight route with 1 waypoint, or modified to have 1 waypoint.
// TODO: Handle flight route with redundant waypoints.
- (SimulationViewController*) initWithWorldWindView:(WorldWindView*)wwv
{
    self = [super initWithNibName:nil bundle:nil];

    _doneButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                                    target:self
                                                                    action:@selector(handleDoneButton)];
    [[self navigationItem] setRightBarButtonItem:_doneButtonItem];

    _wwv = wwv;

    aircraftLayer = aircraftLayer = [[WWRenderableLayer alloc] init];
    [[aircraftLayer userTags] setObject:@"" forKey:TAIGA_HIDDEN_LAYER];
    [[[_wwv sceneController] layers] addLayer:aircraftLayer];

    aircraftMarker = [[AircraftMarker alloc] init];
    [aircraftLayer addRenderable:aircraftMarker];

    return self;
}

- (void) setFlightRoute:(FlightRoute*)flightRoute
{
    if (_flightRoute == flightRoute)
        return;

    _flightRoute = flightRoute;

    // Set the navigator item title to flight route display name + " Simulation". Sets the title to nil if the flight
    // route is nil.
    NSString* title = [[_flightRoute displayName] stringByAppendingString:@" Simulation"];
    [[self navigationItem] setTitle:title];

    // Set the aircraft slider and aircraft marker to the beginning of the flight route. This has no effect on the
    // aircraft marker if the flight route is nil.
    [aircraftSlider setValue:0];
    [_flightRoute positionForPercent:0 result:[aircraftMarker position]]; // does nothing if flightRoute is nil

    // Enable the aircraft layer when the flight route is not nil.
    [aircraftLayer setEnabled:_flightRoute != nil];

    [[NSNotificationCenter defaultCenter] postNotificationName:WW_REQUEST_REDRAW object:self];
}

- (void) handleDoneButton
{
    [self setFlightRoute:nil];
}

- (void) handleSimulationSlider:(UISlider*)slider
{
    double pct = [slider value];
    [_flightRoute positionForPercent:pct result:[aircraftMarker position]];

    [[NSNotificationCenter defaultCenter] postNotificationName:WW_REQUEST_REDRAW object:self];
}

- (void) loadView
{
    UIView* view = [[UIView alloc] init];
    [view setAutoresizingMask:UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight];
    [view setBackgroundColor:[UIColor colorWithWhite:0.8 alpha:1]];
    [view setAlpha:0.95];
    [self setView:view];

    aircraftSlider = [[AircraftSlider alloc] init];
    [aircraftSlider addTarget:self action:@selector(handleSimulationSlider:) forControlEvents:UIControlEventValueChanged];
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
