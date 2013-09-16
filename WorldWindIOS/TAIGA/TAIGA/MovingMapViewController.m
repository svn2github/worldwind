/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import "MovingMapViewController.h"
#import "WorldWind.h"
#import "WorldWindView.h"
#import "WWLayerList.h"
#import "WWSceneController.h"
#import "WWBMNGLandsatCombinedLayer.h"
#import "FlightPathsLayer.h"
#import "LayerListController.h"
#import "AppConstants.h"
#import "WWElevationShadingLayer.h"
#import "Settings.h"

@implementation MovingMapViewController
{
    CGRect myFrame;

    UIToolbar* topToolBar;
    UIBarButtonItem* connectivityButton;
    UIBarButtonItem* flightPathsButton;
    UIBarButtonItem* overlaysButton;
    UIBarButtonItem* splitViewButton;
    UIBarButtonItem* quickViewsButton;
    UIBarButtonItem* routePlanningButton;

    LayerListController* layerListController;
    UIPopoverController* layerListPopoverController;

    FlightPathsLayer* flightPathsLayer;
    WWElevationShadingLayer* elevationShadingLayer;
}

- (id) initWithFrame:(CGRect)frame
{
    self = [super initWithNibName:nil bundle:nil];

    myFrame = frame;

    return self;
}

- (void) loadView
{
    self.view = [[UIView alloc] initWithFrame:myFrame];
    self.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.view.autoresizesSubviews = YES;

    [self createWorldWindView];
    [self createTopToolbar];
}


- (void) viewDidLoad
{
    [super viewDidLoad];

    WWLog(@"View Did Load. World Wind iOS Version %@", WW_VERSION);

    WWLayerList* layers = [[_wwv sceneController] layers];

    WWLayer* layer = [[WWBMNGLandsatCombinedLayer alloc] init];
    [[layer userTags] setObject:@"" forKey:TAIGA_HIDDEN_LAYER];
    [layers addLayer:layer];

    [self createTerrainAltitudeLayer];
    [layers addLayer:elevationShadingLayer];

    flightPathsLayer = [[FlightPathsLayer alloc]
            initWithPathsLocation:@"http://worldwind.arc.nasa.gov/mobile/PassageWays.json"];
    [flightPathsLayer setEnabled:NO];
    [[[_wwv sceneController] layers] addLayer:flightPathsLayer];

    layerListController = [[LayerListController alloc] initWithWorldWindView:_wwv];
}

- (void) viewWillAppear:(BOOL)animated
{
//    [((UINavigationController*) [self parentViewController]) setNavigationBarHidden:YES animated:YES];
}

- (void) createWorldWindView
{
    CGFloat wwvWidth = self.view.bounds.size.width;
    CGFloat wwvHeight = self.view.bounds.size.height - TAIGA_TOOLBAR_HEIGHT;
    CGFloat wwvOriginY = self.view.bounds.origin.y + TAIGA_TOOLBAR_HEIGHT;

    _wwv = [[WorldWindView alloc] initWithFrame:CGRectMake(0, wwvOriginY, wwvWidth, wwvHeight)];
    if (_wwv == nil)
    {
        NSLog(@"Unable to create a WorldWindView");
        return;
    }

    //[_wwv setContentScaleFactor:[[UIScreen mainScreen] scale]]; // enable retina resolution
    [self.view addSubview:_wwv];
}

- (void) createTopToolbar
{
    topToolBar = [[UIToolbar alloc] init];
    topToolBar.frame = CGRectMake(0, 0, self.view.frame.size.width, TAIGA_TOOLBAR_HEIGHT);
    [topToolBar setAutoresizingMask:UIViewAutoresizingFlexibleWidth];
    [topToolBar setBarStyle:UIBarStyleBlack];
    [topToolBar setTranslucent:NO];

    NSDictionary* textAttrs = [[NSDictionary alloc] initWithObjectsAndKeys:
            [UIFont boldSystemFontOfSize:18], UITextAttributeFont, nil];

    connectivityButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"275-broadcast"]
                                                          style:UIBarButtonItemStylePlain
                                                         target:nil
                                                         action:nil];

    flightPathsButton = [[UIBarButtonItem alloc] initWithTitle:@"Flight Paths" style:UIBarButtonItemStylePlain
                                                        target:self
                                                        action:@selector(handleFlightPathsButton)];
    [flightPathsButton setTitleTextAttributes:textAttrs forState:UIControlStateNormal];

    overlaysButton = [[UIBarButtonItem alloc] initWithTitle:@"Overlays" style:UIBarButtonItemStylePlain
                                                     target:self
                                                     action:@selector(handleOverlaysButton)];
    [overlaysButton setTitleTextAttributes:textAttrs forState:UIControlStateNormal];

    splitViewButton = [[UIBarButtonItem alloc] initWithTitle:@"Split View" style:UIBarButtonItemStylePlain
                                                      target:self
                                                      action:@selector(handleButtonTap)];
    [splitViewButton setTitleTextAttributes:textAttrs forState:UIControlStateNormal];

    quickViewsButton = [[UIBarButtonItem alloc] initWithTitle:@"Quick Views" style:UIBarButtonItemStylePlain
                                                       target:self
                                                       action:@selector(handleButtonTap)];
    [quickViewsButton setTitleTextAttributes:textAttrs forState:UIControlStateNormal];

    routePlanningButton = [[UIBarButtonItem alloc] initWithTitle:@"RoutePlanning" style:UIBarButtonItemStylePlain
                                                          target:self
                                                          action:@selector(handleButtonTap)];
    [routePlanningButton setTitleTextAttributes:textAttrs forState:UIControlStateNormal];

    UIBarButtonItem* flexibleSpace = [[UIBarButtonItem alloc]
            initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];

    [topToolBar setItems:[NSArray arrayWithObjects:
            flexibleSpace,
            flightPathsButton,
            flexibleSpace,
            overlaysButton,
            flexibleSpace,
            splitViewButton,
            flexibleSpace,
            quickViewsButton,
            flexibleSpace,
            routePlanningButton,
            flexibleSpace,
            connectivityButton,
            nil]];

    [self.view addSubview:topToolBar];
}

- (void) createTerrainAltitudeLayer
{
    elevationShadingLayer = [[WWElevationShadingLayer alloc] init];
    [elevationShadingLayer setDisplayName:@"Terrain Altitude"];

    float threshold = [Settings getFloat:TAIGA_SHADED_ELEVATION_THRESHOLD_RED defaultValue:3000.0];
    [elevationShadingLayer setRedThreshold:threshold];
    [Settings setFloat:TAIGA_SHADED_ELEVATION_THRESHOLD_RED value:threshold];

    float offset = [Settings getFloat:TAIGA_SHADED_ELEVATION_OFFSET defaultValue:304.8]; // 1000 feet
    [elevationShadingLayer setYellowThreshold:[elevationShadingLayer redThreshold] - offset];
    [Settings setFloat:TAIGA_SHADED_ELEVATION_OFFSET value:offset];

    float opacity = [Settings getFloat:TAIGA_SHADED_ELEVATION_OPACITY defaultValue:0.3];
    [elevationShadingLayer setOpacity:opacity];
    [Settings setFloat:TAIGA_SHADED_ELEVATION_OPACITY value:opacity];
}

- (void) handleButtonTap
{
    NSLog(@"BUTTON TAPPED");
}

- (void) handleFlightPathsButton
{
    [flightPathsLayer setEnabled:![flightPathsLayer enabled]];
    [[NSNotificationCenter defaultCenter] postNotificationName:WW_LAYER_LIST_CHANGED object:self];
    [[NSNotificationCenter defaultCenter] postNotificationName:WW_REQUEST_REDRAW object:self];
}

- (void) handleOverlaysButton
{
    if (layerListPopoverController == nil)
    {
        UINavigationController* navController = [[UINavigationController alloc]
                initWithRootViewController:layerListController];
        [navController setDelegate:layerListController];
        layerListPopoverController = [[UIPopoverController alloc] initWithContentViewController:navController];
    }

    [layerListPopoverController presentPopoverFromBarButtonItem:overlaysButton
                                       permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
}

@end
