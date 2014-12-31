/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import "MovingMapViewController.h"
#import "WorldWind.h"
#import "WorldWindView.h"
#import "WWLayerList.h"
#import "WWRenderableLayer.h"
#import "WWSceneController.h"
#import "WWBMNGLandsatCombinedLayer.h"
#import "LayerListController.h"
#import "AppConstants.h"
#import "WWElevationShadingLayer.h"
#import "Settings.h"
#import "ButtonWithImageAndText.h"
#import "METARLayer.h"
#import "WWPointPlacemark.h"
#import "WWPosition.h"
#import "METARDataViewController.h"
#import "WWPickedObject.h"
#import "WWPickedObjectList.h"
#import "PIREPLayer.h"
#import "PIREPDataViewController.h"
#import "WWNavigator.h"
#import "CompassLayer.h"
#import "ScaleBarView.h"
#import "ChartViewController.h"
#import "WWUtil.h"
#import "ChartsTableController.h"
#import "WeatherCamLayer.h"
#import "WeatherCamViewController.h"
#import "Waypoint.h"
#import "WaypointLayer.h"
#import "FlightRoute.h"
#import "FlightRouteController.h"
#import "SimulationViewController.h"
#import "TerrainProfileView.h"
#import "ViewSelectionController.h"
#import "TerrainProfileController.h"
#import "AircraftLayer.h"
#import "AircraftTrackLayer.h"
#import "TerrainAltitudeLayer.h"
#import "LocationTrackingViewController.h"
#import "WWDAFIFLayer.h"
#import "WWBingLayer.h"
#import "AddWaypointPopoverController.h"
#import "EditWaypointPopoverController.h"
#import "UIPopoverController+TAIGAAdditions.h"
#import "FAASectionalsLayer.h"
#import "DAFIFLayer.h"
#import "SUALayer.h"
#import "SUADataViewController.h"
#import "DataBarViewController.h"

@implementation MovingMapViewController
{
    CGRect myFrame;
    NSArray* showSplitViewConstraints;
    NSArray* hideSplitViewConstraints;
    NSArray* showRouteViewConstraints;
    NSArray* hideRouteViewConstraints;
    NSArray* showSimulationViewConstraints;
    NSArray* hideSimulationViewConstraints;
    NSArray* showTerrainProfileConstraints;
    NSArray* hideTerrainProfileConstraints;
    BOOL isShowSplitView;
    BOOL isShowRouteView;

    UIToolbar* topToolBar;
    DataBarViewController* dataBar;
    UIBarButtonItem* connectivityButton;
    UIBarButtonItem* overlaysButton;
    UIBarButtonItem* quickViewsButton;
    UIBarButtonItem* splitViewButton;
    UIBarButtonItem* routeViewButton;

    bool trackingLocation;
    UILabel* noGPSLabel;

    LocationTrackingViewController* locationTrackingViewController;
    ScaleBarView* scaleBarView;
    LayerListController* layerListController;
    UIPopoverController* layerListPopoverController;
    ViewSelectionController* viewSelectionController;
    UIPopoverController* viewSelectionPopoverController;
    ChartsTableController* chartsListController;
    ChartViewController* chartViewController;
    UINavigationController* chartListNavController;
    FlightRouteController* routeViewController;
    UINavigationController* routeViewNavController;
    SimulationViewController* simulationViewController;
    TerrainProfileView* terrainProfileView;
    TerrainProfileController* terrainProfileController;

    WaypointLayer* waypointLayer;
    AircraftLayer* aircraftLayer;
    AircraftTrackLayer* aircraftTrackLayer;
    WWRenderableLayer* flightRouteLayer;
    FAASectionalsLayer* faaChartsLayer;
    TerrainAltitudeLayer* terrainAltitudeLayer;
    METARLayer* metarLayer;
    PIREPLayer* pirepLayer;
    WeatherCamLayer* weatherCamLayer;
    CompassLayer* compassLayer;
    WWDAFIFLayer* dafifLayer;
    SUALayer* suaLayer;

    UITapGestureRecognizer* tapGestureRecognizer;
    METARDataViewController* metarDataViewController;
    UIPopoverController* metarDataPopoverController;
    PIREPDataViewController* pirepDataViewController;
    UIPopoverController* pirepDataPopoverController;
    WeatherCamViewController* weatherCamViewController;
    UIPopoverController* weatherCamPopoverController;
    SUADataViewController* suaDataViewController;
    UIPopoverController* suaDataPopoverController;
    AddWaypointPopoverController* addWaypointPopoverController;
    EditWaypointPopoverController* editWaypointPopoverController;
}

- (id) initWithFrame:(CGRect)frame
{
    self = [super initWithNibName:nil bundle:nil];

    myFrame = frame;

    metarDataViewController = [[METARDataViewController alloc] init];
    pirepDataViewController = [[PIREPDataViewController alloc] init];
    weatherCamViewController = [[WeatherCamViewController alloc] init];
    suaDataViewController = [[SUADataViewController alloc] init];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(locationTrackingChanged:)
                                                 name:TAIGA_LOCATION_TRACKING_ENABLED object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(gpsQualityNotification:)
                                                 name:TAIGA_GPS_QUALITY object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleChartRefreshNotification:)
                                                 name:TAIGA_REFRESH_CHART
                                               object:nil];

    return self;
}

- (NSUInteger) flightRouteCount
{
    return [routeViewController flightRouteCount];
}

- (FlightRoute*) flightRouteAtIndex:(NSUInteger)index
{
    return [routeViewController flightRouteAtIndex:index];
}

- (NSUInteger) indexOfFlightRoute:(FlightRoute*)flightRoute
{
    return [routeViewController indexOfFlightRoute:flightRoute];
}

- (void) insertFlightRoute:(FlightRoute*)flightRoute atIndex:(NSUInteger)index
{
    [routeViewController insertFlightRoute:flightRoute atIndex:index];
}

- (void) newFlightRoute:(void (^)(FlightRoute* newFlightRoute))completionBlock
{
    [routeViewController newFlightRoute:completionBlock];
}

- (FlightRoute*) presentedFlightRoute
{
    if (isShowRouteView)
    {
        return [routeViewController presentedFlightRoute];
    }

    return nil;
}

- (void) presentFlightRouteAtIndex:(NSUInteger)index editing:(BOOL)editing
{
    // Make the flight route visible on the map.
    FlightRoute* flightRoute = [self flightRouteAtIndex:index];
    [flightRoute setEnabled:YES];
    [flightRouteLayer setEnabled:YES];

    // Make the flight route visible on the route view controller.
    [routeViewController presentFlightRouteAtIndex:index editing:editing];

    if (!isShowRouteView)
    {
        [self transitionRouteView];
    }
}

- (void) loadView
{
    self.view = [[UIView alloc] initWithFrame:myFrame];
    self.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.view.autoresizesSubviews = YES;
    self.view.clipsToBounds = YES;

    [self createWorldWindView];
    [self createTopToolbar];
    [self createDataBar];
    [self createChartsController];
    [self createRouteViewController];
    [self createSimulationController];
    [self createTerrainProfile];
    [self createLocationTrackingController];

    viewSelectionController = [[ViewSelectionController alloc] init];

    float x = 20;//myFrame.size.width - 220;
    float y = myFrame.size.height - 150;
    scaleBarView = [[ScaleBarView alloc] initWithFrame:CGRectMake(x, y, 200, 50) worldWindView:_wwv];
    scaleBarView.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin;
    [self.view addSubview:scaleBarView];

    [topToolBar setTranslatesAutoresizingMaskIntoConstraints:NO];
    [_wwv setTranslatesAutoresizingMaskIntoConstraints:NO];
    [[chartListNavController view] setTranslatesAutoresizingMaskIntoConstraints:NO];
    [[routeViewNavController view] setTranslatesAutoresizingMaskIntoConstraints:NO];
    [[simulationViewController view] setTranslatesAutoresizingMaskIntoConstraints:NO];
    [terrainProfileView setTranslatesAutoresizingMaskIntoConstraints:NO];
    [[locationTrackingViewController view] setTranslatesAutoresizingMaskIntoConstraints:NO];

    UIView* view = [self view];
    UIView* splitView = [chartListNavController view];
    UIView* routeView = [routeViewNavController view];
    UIView* simulationView = [simulationViewController view];
    UIView* locationTrackingView = [locationTrackingViewController view];
    NSDictionary* viewsDictionary = NSDictionaryOfVariableBindings(_wwv, splitView, routeView, topToolBar, scaleBarView,
    simulationView, terrainProfileView, locationTrackingView);

    [view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[topToolBar]|"
                                                                 options:0 metrics:nil views:viewsDictionary]];
    [view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[_wwv]|"
                                                                 options:0 metrics:nil views:viewsDictionary]];
    [view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[simulationView]|"
                                                                 options:0 metrics:nil views:viewsDictionary]];
    [view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[terrainProfileView]|"
                                                                 options:0 metrics:nil views:viewsDictionary]];
    [view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[topToolBar(==80)]"
                                                                 options:0 metrics:nil views:viewsDictionary]];
    [view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[topToolBar][_wwv]|"
                                                                 options:0 metrics:nil views:viewsDictionary]];
    [view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[topToolBar][splitView]|"
                                                                 options:0 metrics:nil views:viewsDictionary]];
    [view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[topToolBar][routeView]|"
                                                                 options:0 metrics:nil views:viewsDictionary]];
    [view addConstraint:[NSLayoutConstraint constraintWithItem:locationTrackingView attribute:NSLayoutAttributeLeft
                                                     relatedBy:NSLayoutRelationEqual
                                                        toItem:_wwv attribute:NSLayoutAttributeLeft multiplier:1 constant:20]];
    [view addConstraint:[NSLayoutConstraint constraintWithItem:locationTrackingView attribute:NSLayoutAttributeTop
                                                     relatedBy:NSLayoutRelationEqual
                                                        toItem:_wwv attribute:NSLayoutAttributeTop multiplier:1 constant:20]];

    showSplitViewConstraints = [NSLayoutConstraint constraintsWithVisualFormat:@"H:[splitView(==350)]|"
                                                                       options:0 metrics:nil views:viewsDictionary];
    hideSplitViewConstraints = [NSLayoutConstraint constraintsWithVisualFormat:@"H:[_wwv][splitView(==350)]"
                                                                       options:0 metrics:nil views:viewsDictionary];
    isShowSplitView = [Settings getBoolForName:@"gov.nasa.worldwind.taiga.splitview.enabled" defaultValue:NO];
    [view addConstraints:isShowSplitView ? showSplitViewConstraints : hideSplitViewConstraints];
    if (isShowSplitView)
        [self loadMostRecentlyUsedChart];

    showRouteViewConstraints = [NSLayoutConstraint constraintsWithVisualFormat:@"H:[routeView(==350)]|"
                                                                       options:0 metrics:nil views:viewsDictionary];
    hideRouteViewConstraints = [NSLayoutConstraint constraintsWithVisualFormat:@"H:[_wwv][routeView(==350)]"
                                                                       options:0 metrics:nil views:viewsDictionary];
    isShowRouteView = [Settings getBoolForName:@"gov.nasa.worldwind.taiga.routeview.enabled" defaultValue:NO];
    [view addConstraints:isShowRouteView ? showRouteViewConstraints : hideRouteViewConstraints];

    showSimulationViewConstraints = [NSLayoutConstraint constraintsWithVisualFormat:@"V:[simulationView(80)]|"
                                                                            options:0 metrics:nil views:viewsDictionary];
    hideSimulationViewConstraints = [NSLayoutConstraint constraintsWithVisualFormat:@"V:[_wwv][simulationView(80)]"
                                                                            options:0 metrics:nil views:viewsDictionary];
    [view addConstraints:hideSimulationViewConstraints];

    showTerrainProfileConstraints = [NSLayoutConstraint
            constraintsWithVisualFormat:@"V:[terrainProfileView(200)][simulationView(80)]"
                                options:0 metrics:nil views:viewsDictionary];
    hideTerrainProfileConstraints = [NSLayoutConstraint
            constraintsWithVisualFormat:@"V:[_wwv][terrainProfileView(200)]"
                                options:0 metrics:nil views:viewsDictionary];
    [view addConstraints:hideTerrainProfileConstraints];
}

- (void) loadMostRecentlyUsedChart
{
    NSString* chartFileName = [[NSUserDefaults standardUserDefaults]
            objectForKey:@"gov.nasa.worldwind.taiga.splitview.chartpath"];

    if (chartFileName == nil || chartFileName.length == 0)
        return;

    NSString* chartName = [[NSUserDefaults standardUserDefaults]
            objectForKey:@"gov.nasa.worldwind.taiga.splitview.chartname"];
    if (chartName == nil || chartName.length == 0)
        return;

    [chartsListController selectChart:chartFileName chartName:chartName];
}

- (void) viewDidLoad
{
    [super viewDidLoad];

    WWLog(@"View Did Load. World Wind iOS Version %@", WW_VERSION);

    WWLayerList* layers = [[_wwv sceneController] layers];

    flightRouteLayer = [[WWRenderableLayer alloc] init];
    [flightRouteLayer addRenderable:routeViewController]; // the flight route controller draws its flight routes on the map
    [flightRouteLayer setDisplayName:@"Routes"];
    [flightRouteLayer setEnabled:[Settings                                 getBoolForName:
            [[NSString alloc] initWithFormat:@"gov.nasa.worldwind.taiga.layer.enabled.%@",
                                             [flightRouteLayer displayName]] defaultValue:YES]];
    [layers addLayer:flightRouteLayer];

    waypointLayer = [[WaypointLayer alloc] init];
    [waypointLayer setEnabled:[Settings                                                                               getBoolForName:
            [[NSString alloc] initWithFormat:@"gov.nasa.worldwind.taiga.layer.enabled.%@", [waypointLayer displayName]] defaultValue:NO]];
    [layers addLayer:waypointLayer];

    aircraftTrackLayer = [[AircraftTrackLayer alloc] init];
    [aircraftTrackLayer setEnabled:[Settings                                 getBoolForName:
            [[NSString alloc] initWithFormat:@"gov.nasa.worldwind.taiga.layer.enabled.%@",
                                             [aircraftTrackLayer displayName]] defaultValue:YES]];
    [layers addLayer:aircraftTrackLayer];

    aircraftLayer = [[AircraftLayer alloc] init];
    [[aircraftLayer userTags] setObject:@"" forKey:TAIGA_HIDDEN_LAYER];
    [layers addLayer:aircraftLayer];

    WWLayer* layer = [[WWBMNGLandsatCombinedLayer alloc] init];
    [[layer userTags] setObject:@"" forKey:TAIGA_HIDDEN_LAYER];
    [layers addLayer:layer];

    layer = [[WWBingLayer alloc] init];
    [layer setEnabled:[Settings                                 getBoolForName:
            [[NSString alloc] initWithFormat:@"gov.nasa.worldwind.taiga.layer.enabled.%@",
                                             [layer displayName]] defaultValue:YES]];
    [layers addLayer:layer];

    faaChartsLayer = [[FAASectionalsLayer alloc] init];
    [faaChartsLayer setEnabled:[Settings                                 getBoolForName:
            [[NSString alloc] initWithFormat:@"gov.nasa.worldwind.taiga.layer.enabled.%@",
                                             [faaChartsLayer displayName]] defaultValue:NO]];
    [[[_wwv sceneController] layers] addLayer:faaChartsLayer];

    dafifLayer = [[DAFIFLayer alloc] init];
    [dafifLayer setEnabled:[Settings                                                                               getBoolForName:
            [[NSString alloc] initWithFormat:@"gov.nasa.worldwind.taiga.layer.enabled.%@", [dafifLayer displayName]] defaultValue:YES]];
    [[[_wwv sceneController] layers] addLayer:dafifLayer];

    suaLayer = [[SUALayer alloc] init];
    [suaLayer setEnabled:[Settings                                                                               getBoolForName:
            [[NSString alloc] initWithFormat:@"gov.nasa.worldwind.taiga.layer.enabled.%@", [suaLayer displayName]] defaultValue:YES]];
    [[[_wwv sceneController] layers] addLayer:suaLayer];

    [self createTerrainAltitudeLayer];
    [terrainAltitudeLayer setEnabled:[Settings                                                                               getBoolForName:
            [[NSString alloc] initWithFormat:@"gov.nasa.worldwind.taiga.layer.enabled.%@", [terrainAltitudeLayer displayName]] defaultValue:NO]];
    [layers addLayer:terrainAltitudeLayer];

    metarLayer = [[METARLayer alloc] init];
    [metarLayer setEnabled:[Settings                                                                               getBoolForName:
            [[NSString alloc] initWithFormat:@"gov.nasa.worldwind.taiga.layer.enabled.%@", [metarLayer displayName]] defaultValue:NO]];
    [[[_wwv sceneController] layers] addLayer:metarLayer];

    pirepLayer = [[PIREPLayer alloc] init];
    [pirepLayer setEnabled:[Settings                                                                               getBoolForName:
            [[NSString alloc] initWithFormat:@"gov.nasa.worldwind.taiga.layer.enabled.%@", [pirepLayer displayName]] defaultValue:NO]];
    [[[_wwv sceneController] layers] addLayer:pirepLayer];

    weatherCamLayer = [[WeatherCamLayer alloc] init];
    [weatherCamLayer setEnabled:[Settings                                                                               getBoolForName:
            [[NSString alloc] initWithFormat:@"gov.nasa.worldwind.taiga.layer.enabled.%@", [weatherCamLayer displayName]] defaultValue:NO]];
    [[[_wwv sceneController] layers] addLayer:weatherCamLayer];

    compassLayer = [[CompassLayer alloc] init];
    [[compassLayer userTags] setObject:@"" forKey:TAIGA_HIDDEN_LAYER];
    [compassLayer setEnabled:[Settings                                                                               getBoolForName:
            [[NSString alloc] initWithFormat:@"gov.nasa.worldwind.taiga.layer.enabled.%@", [compassLayer displayName]] defaultValue:YES]];
    [[[_wwv sceneController] layers] addLayer:compassLayer];

    layerListController = [[LayerListController alloc] initWithWorldWindView:_wwv];

    tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
    [tapGestureRecognizer setNumberOfTapsRequired:1];
    [tapGestureRecognizer setNumberOfTouchesRequired:1];
    [_wwv addGestureRecognizer:tapGestureRecognizer];

    // Set any persisted layer opacity.
    for (WWLayer* wwLayer in [[[_wwv sceneController] layers] allLayers])
    {
        NSString* settingName = [[NSString alloc] initWithFormat:@"gov.nasa.worldwind.taiga.layer.%@.opacity",
                                                                 [wwLayer displayName]];
        float opacity = [Settings getFloatForName:settingName defaultValue:[wwLayer opacity]];
        [wwLayer setOpacity:opacity];
    }
}

- (void) viewWillAppear:(BOOL)animated
{
//    [((UINavigationController*) [self parentViewController]) setNavigationBarHidden:YES animated:YES];
}

- (void) createWorldWindView
{
    CGFloat wwvWidth = self.view.bounds.size.width;
    CGFloat wwvHeight = self.view.bounds.size.height - TAIGA_TOOLBAR_HEIGHT;
//    CGFloat wwvOriginY = self.view.bounds.origin.y + TAIGA_TOOLBAR_HEIGHT;
    CGFloat wwvOriginY = TAIGA_TOOLBAR_HEIGHT;

    _wwv = [[WorldWindView alloc] initWithFrame:CGRectMake(0, wwvOriginY, wwvWidth, wwvHeight)];
    if (_wwv == nil)
    {
        NSLog(@"Unable to create a WorldWindView");
        return;
    }

    WWLocation* center = [[WWLocation alloc] initWithDegreesLatitude:65 longitude:-150];
    [[_wwv navigator] setCenterLocation:center radius:800e3];

    //[_wwv setContentScaleFactor:[[UIScreen mainScreen] scale]]; // enable retina resolution
    [self.view addSubview:_wwv];
}

- (void) navigationController:(UINavigationController*)navigationController
       willShowViewController:(UIViewController*)viewController
                     animated:(BOOL)animated
{
    UIViewController* rootViewController = [[navigationController viewControllers] firstObject];
    if (viewController != rootViewController)
    {
        [[viewController view] setAlpha:[[rootViewController view] alpha]];
    }
}

- (void) createChartsController
{
    chartsListController = [[ChartsTableController alloc] initWithParent:self];
    [[chartsListController view] setAlpha:0.95]; // Make the chart list view semi-transparent.

    chartListNavController = [[UINavigationController alloc] initWithRootViewController:chartsListController];
    [chartListNavController setDelegate:self]; // Propagate the root view alpha to views pushed on the navigation stack.
    [self.view addSubview:[chartListNavController view]];
}

- (void) handleChartRefreshNotification:(NSNotification*)notification
{
    if ([[notification name] isEqualToString:TAIGA_REFRESH_CHART]
            && [chartListNavController visibleViewController] == chartViewController)
    {
        NSDictionary* chartInfo = [notification userInfo];
        NSString* chartName = [chartViewController title];
        if ([chartName isEqualToString:[chartInfo objectForKey:TAIGA_NAME]])
        {
            [self loadChart:[chartInfo objectForKey:TAIGA_PATH] chartName:chartName];
        }
    }
}

- (void) loadChart:(NSString*)chartPath chartName:(NSString*)chartName
{
    if ([[NSFileManager defaultManager] fileExistsAtPath:chartPath])
    {
        if (chartName == nil)
            chartName = @"";

        if (chartViewController == nil)
            chartViewController = [[ChartViewController alloc] initWithFrame:[[chartsListController view] frame]];

        [[chartViewController imageView] setImage:[WWUtil convertPDFToUIImage:[[NSURL alloc]
                initFileURLWithPath:chartPath]]];
        [chartViewController setTitle:chartName];

        [[NSUserDefaults standardUserDefaults] setObject:[chartPath lastPathComponent]
                                                  forKey:@"gov.nasa.worldwind.taiga.splitview.chartpath"];
        [[NSUserDefaults standardUserDefaults] setObject:chartName
                                                  forKey:@"gov.nasa.worldwind.taiga.splitview.chartname"];
        [[NSUserDefaults standardUserDefaults] synchronize];

        if ([chartListNavController visibleViewController] != chartViewController)
            [self performSelectorOnMainThread:@selector(pushChart) withObject:nil waitUntilDone:NO];
    }
}

- (void) pushChart
{
    [((UINavigationController*) [chartsListController parentViewController]) pushViewController:chartViewController animated:YES];
}

- (void) createRouteViewController
{
    routeViewController = [[FlightRouteController alloc] initWithWorldWindView:_wwv];
    [[routeViewController view] setAlpha:0.95]; // Make the flight route view semi-transparent.

    routeViewNavController = [[UINavigationController alloc] initWithRootViewController:routeViewController];
    [routeViewNavController setDelegate:self]; // Propagate the root view alpha to views pushed on the navigation stack.
    [self.view addSubview:[routeViewNavController view]];
}

- (void) createTerrainProfile
{
    terrainProfileView = [[TerrainProfileView alloc] initWithFrame:CGRectZero worldWindView:_wwv];
    [self.view addSubview:terrainProfileView];

    terrainProfileController = [[TerrainProfileController alloc] initWithTerrainProfileView:terrainProfileView];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleShowTerrainProfile:)
                                                 name:TAIGA_SHOW_TERRAIN_PROFILE object:nil];
}

- (void) handleShowTerrainProfile:(NSNotification*)notification
{
    NSNumber* yn = [notification object];

    if ([yn boolValue] == YES)
    {
        [self performSelectorOnMainThread:@selector(presentTerrainProfile) withObject:nil waitUntilDone:NO];
    }
    else
    {
        [self performSelectorOnMainThread:@selector(dismissTerrainProfile) withObject:nil waitUntilDone:NO];
    }
}

- (void) presentTerrainProfile
{
    [self.view bringSubviewToFront:terrainProfileView];
    [self.view bringSubviewToFront:[simulationViewController view]];

    [self.view layoutIfNeeded]; // Ensure all pending layout operations have completed.
    [UIView animateWithDuration:0.3 animations:^
    {
        [self.view removeConstraints:hideTerrainProfileConstraints];
        [self.view addConstraints:showTerrainProfileConstraints];
        [self.view layoutIfNeeded]; // Force layout to capture constraint frame changes in the animation block.
    }];
    [terrainProfileView setNeedsDisplay]; // TODO: Determine why this is needed to make the profile window visible
    [terrainProfileView setEnabled:YES];
}

- (void) dismissTerrainProfile
{
    [terrainProfileView setEnabled:NO];
    [self.view bringSubviewToFront:[simulationViewController view]];

    [self.view layoutIfNeeded]; // Ensure all pending layout operations have completed.
    [UIView animateWithDuration:0.3 animations:^
    {
        [self.view removeConstraints:showTerrainProfileConstraints];
        [self.view addConstraints:hideTerrainProfileConstraints];
        [self.view layoutIfNeeded]; // Force layout to capture constraint frame changes in the animation block.
        [terrainProfileView setNeedsDisplay];
    }];
    [terrainProfileView setNeedsDisplay]; // TODO: Determine why this is needed to make the profile window visible
}

- (void) createSimulationController
{
    simulationViewController = [[SimulationViewController alloc] init];
    [self.view addSubview:[simulationViewController view]];

    // Dismiss the simulation view controller when the user taps its done button.
    [[simulationViewController doneControl] addTarget:self action:@selector(dismissSimulationController)
                                     forControlEvents:UIControlEventTouchUpInside | UIControlEventTouchUpOutside];

    // Dismiss the simulation view controller when the user removes the simulated flight route.
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleFlightRouteRemoved:)
                                                 name:TAIGA_FLIGHT_ROUTE_REMOVED object:nil];
}

- (void) presentSimulationControllerWithFlightRoute:(FlightRoute*)flightRoute
{
    if ([simulationViewController flightRoute] == nil) // begin simulation with the flight route
    {
        [[NSNotificationCenter defaultCenter] postNotificationName:TAIGA_SIMULATION_WILL_BEGIN object:flightRoute];
        [simulationViewController setFlightRoute:flightRoute];

        [self.view bringSubviewToFront:[simulationViewController view]];
        [self.view layoutIfNeeded]; // Ensure all pending layout operations have completed.
        [UIView animateWithDuration:0.3 animations:^
        {
            [self.view removeConstraints:hideSimulationViewConstraints];
            [self.view addConstraints:showSimulationViewConstraints];
            [self.view layoutIfNeeded]; // Force layout to capture constraint frame changes in the animation block.
        }];
    }
    else if ([simulationViewController flightRoute] != flightRoute) // end simulation then begin with another route
    {
        [self dismissSimulationController:^
        {
            [self presentSimulationControllerWithFlightRoute:flightRoute];
        }];
    }
}

- (void) dismissSimulationController:(void (^)(void))completionBlock
{
    if ([simulationViewController flightRoute] != nil)
    {
        [[NSNotificationCenter defaultCenter] postNotificationName:TAIGA_SIMULATION_WILL_END object:nil];

        [self.view layoutIfNeeded]; // Ensure all pending layout operations have completed.
        [UIView animateWithDuration:0.3 animations:^
        {
            [self.view removeConstraints:showSimulationViewConstraints];
            [self.view addConstraints:hideSimulationViewConstraints];
            [self.view layoutIfNeeded]; // Force layout to capture constraint frame changes in the animation block.
        }                completion:^(BOOL finished)
        {
            [simulationViewController setFlightRoute:nil];

            if (completionBlock != NULL)
            {
                completionBlock();
            }
        }];
    }
}

- (void) dismissSimulationController
{
    [self dismissSimulationController:NULL];
}

- (void) handleFlightRouteRemoved:(NSNotification*)notification
{
    FlightRoute* flightRoute = [notification object];
    if (flightRoute == [simulationViewController flightRoute])
    {
        [self dismissSimulationController];
    }
}

- (void) createLocationTrackingController
{
    locationTrackingViewController = [[LocationTrackingViewController alloc] initWithView:_wwv];
    [self.view addSubview:[locationTrackingViewController view]];
}

- (void) createDataBar
{
    CGRect frm = CGRectMake(0, self.view.frame.size.height - TAIGA_TOOLBAR_HEIGHT,
            self.view.frame.size.width, TAIGA_TOOLBAR_HEIGHT);
    dataBar = [[DataBarViewController alloc] initWithFrame:frm];

    [self.view addSubview:[dataBar view]];
    [self addChildViewController:dataBar];
}

- (void) createTopToolbar
{
    topToolBar = [[UIToolbar alloc] init];
    topToolBar.frame = CGRectMake(0, 0, self.view.frame.size.width, TAIGA_TOOLBAR_HEIGHT);
    [topToolBar setAutoresizingMask:UIViewAutoresizingFlexibleWidth];
    [topToolBar setBarStyle:UIBarStyleBlack];
    [topToolBar setTranslucent:NO];

    [topToolBar setBackgroundColor:[UIColor clearColor]];

    CGSize size = CGSizeMake(140, TAIGA_TOOLBAR_HEIGHT);

    connectivityButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"275-broadcast"]
                                                          style:UIBarButtonItemStylePlain
                                                         target:nil
                                                         action:nil];
    [connectivityButton setTintColor:[UIColor whiteColor]];

    //flightPathsButton = [[UIBarButtonItem alloc] initWithCustomView:[[ButtonWithImageAndText alloc]
    //        initWithImageName:@"38-airplane" text:@"Flight Paths" size:size target:self action:@selector
    //        (handleFlightPathsButton)]];
    //UIColor* color = [[UIColor alloc] initWithRed:1.0 green:242. / 255. blue:183. / 255. alpha:1.0];
    //[((ButtonWithImageAndText*) [flightPathsButton customView]) setTextColor:color];
    //[((ButtonWithImageAndText*) [flightPathsButton customView]) setFontSize:15];

    overlaysButton = [[UIBarButtonItem alloc] initWithCustomView:[[ButtonWithImageAndText alloc]
            initWithImageName:@"328-layers2" text:@"Overlays" size:size target:self action:@selector
            (handleOverlaysButton)]];
    UIColor* color = [[UIColor alloc] initWithRed:1.0 green:242. / 255. blue:183. / 255. alpha:1.0];
    [((ButtonWithImageAndText*) [overlaysButton customView]) setTextColor:color];
    [((ButtonWithImageAndText*) [overlaysButton customView]) setFontSize:15];

    quickViewsButton = [[UIBarButtonItem alloc] initWithCustomView:[[ButtonWithImageAndText alloc]
            initWithImageName:@"309-thumbtack" text:@"Views" size:size target:self action:@selector
            (handleViewsButton)]];
    color = [[UIColor alloc] initWithRed:1.0 green:242. / 255. blue:183. / 255. alpha:1.0];
    [((ButtonWithImageAndText*) [quickViewsButton customView]) setTextColor:color];
    [((ButtonWithImageAndText*) [quickViewsButton customView]) setFontSize:15];

    splitViewButton = [[UIBarButtonItem alloc] initWithCustomView:[[ButtonWithImageAndText alloc]
            initWithImageName:@"362-2up" text:@"Split View" size:size target:self action:@selector
            (handleSplitViewButton)]];
    color = [[UIColor alloc] initWithRed:1.0 green:242. / 255. blue:183. / 255. alpha:1.0];
    [((ButtonWithImageAndText*) [splitViewButton customView]) setTextColor:color];
    [((ButtonWithImageAndText*) [splitViewButton customView]) setFontSize:15];

    routeViewButton = [[UIBarButtonItem alloc] initWithCustomView:[[ButtonWithImageAndText alloc]
            initWithImageName:@"122-stats" text:@"Flight Planning" size:size target:self action:@selector
            (handleRouteViewButton)]];
    color = [[UIColor alloc] initWithRed:1.0 green:242. / 255. blue:183. / 255. alpha:1.0];
    [((ButtonWithImageAndText*) [routeViewButton customView]) setTextColor:color];
    [((ButtonWithImageAndText*) [routeViewButton customView]) setFontSize:15];

    UIBarButtonItem* flexibleSpace = [[UIBarButtonItem alloc]
            initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];

    [topToolBar setItems:[NSArray arrayWithObjects:
            //flexibleSpace,
            //flightPathsButton,
            flexibleSpace,
            overlaysButton,
            flexibleSpace,
            quickViewsButton,
            flexibleSpace,
            splitViewButton,
            flexibleSpace,
            routeViewButton,
            flexibleSpace,
            connectivityButton,
            nil]];

    [self.view addSubview:topToolBar];
}

- (void) createTerrainAltitudeLayer
{
    terrainAltitudeLayer = [[TerrainAltitudeLayer alloc] init];
    [terrainAltitudeLayer setDisplayName:@"Terrain Altitude"];

    float threshold = [Settings getFloatForName:TAIGA_SHADED_ELEVATION_THRESHOLD_RED defaultValue:3000.0];
    [terrainAltitudeLayer setRedThreshold:threshold];
    [Settings setFloat:threshold forName:TAIGA_SHADED_ELEVATION_THRESHOLD_RED];

    float offset = [Settings getFloatForName:TAIGA_SHADED_ELEVATION_OFFSET defaultValue:304.8]; // 1000 feet
    [terrainAltitudeLayer setYellowThreshold:[terrainAltitudeLayer redThreshold] - offset];
    [Settings setFloat:offset forName:TAIGA_SHADED_ELEVATION_OFFSET];

    float opacity = [Settings getFloatForName:TAIGA_SHADED_ELEVATION_OPACITY defaultValue:0.3];
    [terrainAltitudeLayer setOpacity:opacity];
    [Settings setFloat:opacity forName:TAIGA_SHADED_ELEVATION_OPACITY];
}

//- (void) handleFlightPathsButton
//{
//    [flightPathsLayer setEnabled:![flightPathsLayer enabled]];
//    [[NSNotificationCenter defaultCenter] postNotificationName:WW_LAYER_LIST_CHANGED object:self];
//    [[NSNotificationCenter defaultCenter] postNotificationName:WW_REQUEST_REDRAW object:self];
//}

- (void) handleOverlaysButton
{
    if (layerListPopoverController == nil)
    {
        UINavigationController* navController = [[UINavigationController alloc]
                initWithRootViewController:layerListController];
        layerListPopoverController = [[UIPopoverController alloc] initWithContentViewController:navController];
    }

    if ([layerListPopoverController isPopoverVisible])
    {
        [layerListPopoverController dismissPopoverAnimated:YES];
    }
    else
    {
        [layerListPopoverController presentPopoverFromBarButtonItem:overlaysButton
                                           permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
        [layerListController flashScrollIndicator];
    }
}

- (void) handleViewsButton
{
    if (viewSelectionPopoverController == nil)
    {
        UINavigationController* navController = [[UINavigationController alloc]
                initWithRootViewController:viewSelectionController];
        viewSelectionPopoverController = [[UIPopoverController alloc] initWithContentViewController:navController];
    }

    if ([viewSelectionPopoverController isPopoverVisible])
    {
        [viewSelectionPopoverController dismissPopoverAnimated:YES];
    }
    else
    {
        [viewSelectionPopoverController presentPopoverFromBarButtonItem:quickViewsButton
                                               permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
    }
}

- (void) handleSplitViewButton
{
    if (isShowRouteView) // Hide the route view if it's currently shown.
    {
        [self transitionRouteView];
    }

    [self transitionSplitView];
}

- (void) transitionSplitView
{
    isShowSplitView = !isShowSplitView;

    UIView* view = [self view];
    UIView* splitView = [chartListNavController view];
    [view bringSubviewToFront:splitView];
    [view layoutIfNeeded]; // Ensure all pending layout operations have completed.

    [UIView animateWithDuration:0.3
                          delay:0.0
                        options:UIViewAnimationOptionBeginFromCurrentState // Animate scroll views from their current state.
                     animations:^
                     {
                         [view removeConstraints:isShowSplitView ? hideSplitViewConstraints : showSplitViewConstraints];
                         [view addConstraints:isShowSplitView ? showSplitViewConstraints : hideSplitViewConstraints];
                         [view layoutIfNeeded]; // Force layout to capture constraint frame changes in the animation block.
                     }
                     completion:NULL];

    if (!isShowSplitView)
    {
        [[NSUserDefaults standardUserDefaults] setObject:@"" forKey:@"gov.nasa.worldwind.taiga.splitview.chartpath"];
        [[NSUserDefaults standardUserDefaults] setObject:@"" forKey:@"gov.nasa.worldwind.taiga.splitview.chartname"];
    }
    [Settings setBool:isShowSplitView forName:@"gov.nasa.worldwind.taiga.splitview.enabled"];
}

- (void) handleRouteViewButton
{
    if (isShowSplitView) // Hide the split view if it's currently shown.
    {
        [self transitionSplitView];
    }

    [self transitionRouteView];
}

- (void) transitionRouteView
{
    isShowRouteView = !isShowRouteView;

    UIView* view = [self view];
    UIView* routeView = [routeViewNavController view];
    [view bringSubviewToFront:routeView];
    [view layoutIfNeeded]; // Ensure all pending layout operations have completed.

    [UIView animateWithDuration:0.3
                          delay:0.0
                        options:UIViewAnimationOptionBeginFromCurrentState // Animate scroll views from their current state.
                     animations:^
                     {
                         [view removeConstraints:isShowRouteView ? hideRouteViewConstraints : showRouteViewConstraints];
                         [view addConstraints:isShowRouteView ? showRouteViewConstraints : hideRouteViewConstraints];
                         [view layoutIfNeeded]; // Force layout to capture constraint frame changes in the animation block.
                     }
                     completion:NULL];

    [Settings setBool:isShowRouteView forName:@"gov.nasa.worldwind.taiga.routeview.enabled"];
}

- (void) handleTap:(UITapGestureRecognizer*)recognizer
{
    if ([recognizer state] == UIGestureRecognizerStateEnded)
    {
        CGPoint tapPoint = [recognizer locationInView:_wwv];
        WWPickedObjectList* pickedObjects = [_wwv pick:tapPoint];
        WWPickedObject* topObject = [pickedObjects topPickedObject];

        if (topObject.isTerrain)
        {
            [self showAddWaypointAtPickPosition:topObject];
        }
        else if ([[topObject userObject] isKindOfClass:[WWPointPlacemark class]])
        {
            WWPointPlacemark* pm = (WWPointPlacemark*) [topObject userObject];
            if ([pm userObject] != nil)
            {
                if ([[[topObject parentLayer] displayName] isEqualToString:@"METAR Weather"])
                    [self showMETARData:pm];
                else if ([[[topObject parentLayer] displayName] isEqualToString:@"PIREPs"])
                    [self showPIREPData:pm];
                else if ([[[topObject parentLayer] displayName] isEqualToString:@"Weather Cams"])
                    [self showWeatherCam:pm];
            }
        }
        else if ([[[topObject parentLayer] displayName] isEqualToString:@"Airspaces"])
        {
            [self showSpecialUseAirspace:topObject];
        }
        else if ([[topObject userObject] isKindOfClass:[Waypoint class]])
        {
            [self showAddWaypoint:topObject];
        }
        else if ([[[topObject parentLayer] displayName] isEqualToString:@"Routes"])
        {
            if ([[topObject userObject] objectForKey:@"waypointIndex"] != nil)
            {
                [self showEditWaypoint:topObject];
            }
            else
            {
                [self selectFlightRoute:topObject];
            }
        }
    }
}

- (void) showAddWaypoint:(WWPickedObject*)po
{
    Waypoint* waypoint = [po userObject];
    addWaypointPopoverController = [[AddWaypointPopoverController alloc] initWithWaypoint:waypoint mapViewController:self];
    [addWaypointPopoverController presentPopoverFromPosition:[po position] inView:_wwv
                                    permittedArrowDirections:UIPopoverArrowDirectionDown animated:YES];
}

- (void) showAddWaypointAtPickPosition:(WWPickedObject*)po
{
    WWPosition* pos = [po position];
    addWaypointPopoverController = [[AddWaypointPopoverController alloc] initWithPosition:pos mapViewController:self];
    [addWaypointPopoverController presentPopoverFromPosition:[po position] inView:_wwv
                                    permittedArrowDirections:UIPopoverArrowDirectionDown animated:YES];
}

- (void) showEditWaypoint:(WWPickedObject*)po
{
    FlightRoute* flightRoute = [[po userObject] objectForKey:@"flightRoute"];
    NSUInteger waypointIndex = [[[po userObject] objectForKey:@"waypointIndex"] unsignedIntegerValue];
    editWaypointPopoverController = [[EditWaypointPopoverController alloc] initWithFlightRoute:flightRoute waypointIndex:waypointIndex mapViewController:self];
    [editWaypointPopoverController presentPopoverFromPosition:[po position] inView:_wwv
                                     permittedArrowDirections:UIPopoverArrowDirectionDown animated:YES];
}

- (void) showMETARData:(WWPointPlacemark*)pm
{
    // Give the controller the placemark's dictionary.
    [metarDataViewController setEntries:[pm userObject]];

    // Ensure that the first line of the data is at the top of the data table.
    [[metarDataViewController tableView] scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]
                                               atScrollPosition:UITableViewScrollPositionTop animated:YES];

    if (metarDataPopoverController == nil)
        metarDataPopoverController = [[UIPopoverController alloc] initWithContentViewController:metarDataViewController];
    [metarDataPopoverController presentPopoverFromPosition:[pm position] inView:_wwv
                                  permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
    [metarDataViewController flashScrollIndicator];
}

- (void) showPIREPData:(WWPointPlacemark*)pm
{
    // Give the controller the placemark's dictionary.
    [pirepDataViewController setEntries:[pm userObject]];

    // Ensure that the first line of the data is at the top of the data table.
    [[pirepDataViewController tableView] scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]
                                               atScrollPosition:UITableViewScrollPositionTop animated:YES];

    if (pirepDataPopoverController == nil)
        pirepDataPopoverController = [[UIPopoverController alloc] initWithContentViewController:pirepDataViewController];
    [pirepDataPopoverController presentPopoverFromPosition:[pm position] inView:_wwv
                                  permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
    [pirepDataViewController flashScrollIndicator];
}

- (void) showWeatherCam:(WWPointPlacemark*)pm
{
    // Give the controller the placemark's dictionary.
    [weatherCamViewController setSiteInfo:[pm userObject]];

    if (weatherCamPopoverController == nil)
        weatherCamPopoverController = [[UIPopoverController alloc] initWithContentViewController:weatherCamViewController];
    [weatherCamPopoverController presentPopoverFromPosition:[pm position] inView:_wwv
                                   permittedArrowDirections:0 animated:YES];
}

- (void) showSpecialUseAirspace:(WWPickedObject*)po
{
    // Give the controller the airspace's dictionary.
    [suaDataViewController setEntries:[[po userObject] userObject]];

    // Ensure that the first line of the data is at the top of the data table.
    [[suaDataViewController tableView] scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]
                                               atScrollPosition:UITableViewScrollPositionTop animated:YES];

    if (suaDataPopoverController == nil)
        suaDataPopoverController = [[UIPopoverController alloc] initWithContentViewController:suaDataViewController];
    [suaDataPopoverController presentPopoverFromPoint:[po pickPoint] inView:_wwv
                             permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
    [suaDataViewController flashScrollIndicator];
}

- (void) selectFlightRoute:(WWPickedObject*)po
{
    FlightRoute* flightRoute = [[po userObject] objectForKey:@"flightRoute"];
    [self presentSimulationControllerWithFlightRoute:flightRoute];
}

- (void) locationTrackingChanged:(NSNotification*)notification
{
    trackingLocation = ((NSNumber*) [notification object]).boolValue;

    if (!trackingLocation)
        [self showNoGPSSign:NO];
}

- (void) gpsQualityNotification:(NSNotification*)notification
{
    NSNumber* quality = (NSNumber*) [notification object];
    [self showNoGPSSign:[notification object] == nil || [quality doubleValue] <= 0];
}

- (void) showNoGPSSign:(bool)yn
{
    if (yn)
    {
        if (noGPSLabel == nil)
        {
            noGPSLabel = [[UILabel alloc] init];
            [noGPSLabel setText:@"NO GPS"];
            [noGPSLabel setBackgroundColor:[UIColor redColor]];
            [noGPSLabel setTextColor:[UIColor whiteColor]];
            [noGPSLabel setFont:[UIFont boldSystemFontOfSize:30]];
            [noGPSLabel sizeToFit];
            [noGPSLabel setAutoresizingMask:UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleLeftMargin];
        }

        CGRect viewFrame = [_wwv frame];
        CGRect labelBounds = [noGPSLabel bounds];
        float labelX = viewFrame.size.width / 2 - labelBounds.size.width / 2;
        [noGPSLabel setFrame:CGRectMake(labelX, viewFrame.origin.y, labelBounds.size.width, labelBounds.size.height)];

        [[self view] addSubview:noGPSLabel];
    }
    else
    {
        if (noGPSLabel != nil)
            [noGPSLabel removeFromSuperview];
    }
}

@end