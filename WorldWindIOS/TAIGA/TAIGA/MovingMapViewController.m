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
#import "ButtonWithImageAndText.h"
#import "METARLayer.h"
#import "WWPointPlacemark.h"
#import "WWNavigatorState.h"
#import "WWPosition.h"
#import "WWGlobe.h"
#import "WWVec4.h"
#import "METARDataViewController.h"
#import "WWPickedObject.h"
#import "WWPickedObjectList.h"

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
    METARLayer* metarLayer;

    UITapGestureRecognizer* tapGestureRecognizer;

    METARDataViewController* metarDataViewController;
    UIPopoverController* metarDataPopoverController;
}

- (id) initWithFrame:(CGRect)frame
{
    self = [super initWithNibName:nil bundle:nil];

    myFrame = frame;

    metarDataViewController = [[METARDataViewController alloc] init];

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

    metarLayer = [[METARLayer alloc] init];
    [metarLayer setEnabled:NO];
    [[[_wwv sceneController] layers] addLayer:metarLayer];

    layerListController = [[LayerListController alloc] initWithWorldWindView:_wwv];

    tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
    [tapGestureRecognizer setNumberOfTapsRequired:1];
    [tapGestureRecognizer setNumberOfTouchesRequired:1];
    [_wwv addGestureRecognizer:tapGestureRecognizer];
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

    CGSize size = CGSizeMake(140, TAIGA_TOOLBAR_HEIGHT);

    connectivityButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"275-broadcast"]
                                                          style:UIBarButtonItemStylePlain
                                                         target:nil
                                                         action:nil];

    flightPathsButton = [[UIBarButtonItem alloc] initWithCustomView:[[ButtonWithImageAndText alloc]
            initWithImageName:@"38-airplane" text:@"Flight Paths" size:size target:self action:@selector
            (handleFlightPathsButton)]];
    UIColor* color = [[UIColor alloc] initWithRed:1.0 green:242./255. blue:183./255. alpha:1.0];
    [((ButtonWithImageAndText*) [flightPathsButton customView]) setTextColor:color];
    [((ButtonWithImageAndText*) [flightPathsButton customView]) setFontSize:15];

    overlaysButton = [[UIBarButtonItem alloc] initWithCustomView:[[ButtonWithImageAndText alloc]
            initWithImageName:@"328-layers2" text:@"Overlays" size:size target:self action:@selector
            (handleOverlaysButton)]];
    color = [[UIColor alloc] initWithRed:1.0 green:242./255. blue:183./255. alpha:1.0];
    [((ButtonWithImageAndText*) [overlaysButton customView]) setTextColor:color];
    [((ButtonWithImageAndText*) [overlaysButton customView]) setFontSize:15];

    splitViewButton = [[UIBarButtonItem alloc] initWithCustomView:[[ButtonWithImageAndText alloc]
            initWithImageName:@"362-2up" text:@"Split View" size:size target:self action:@selector
            (handleButtonTap)]];
    color = [[UIColor alloc] initWithRed:1.0 green:242./255. blue:183./255. alpha:1.0];
    [((ButtonWithImageAndText*) [splitViewButton customView]) setTextColor:color];
    [((ButtonWithImageAndText*) [splitViewButton customView]) setFontSize:15];

    quickViewsButton = [[UIBarButtonItem alloc] initWithCustomView:[[ButtonWithImageAndText alloc]
            initWithImageName:@"309-thumbtack" text:@"Quick Views" size:size target:self action:@selector
            (handleButtonTap)]];
    color = [[UIColor alloc] initWithRed:1.0 green:242./255. blue:183./255. alpha:1.0];
    [((ButtonWithImageAndText*) [quickViewsButton customView]) setTextColor:color];
    [((ButtonWithImageAndText*) [quickViewsButton customView]) setFontSize:15];

    routePlanningButton = [[UIBarButtonItem alloc] initWithCustomView:[[ButtonWithImageAndText alloc]
            initWithImageName:@"122-stats" text:@"Route Planning" size:size target:self action:@selector
            (handleButtonTap)]];
    color = [[UIColor alloc] initWithRed:1.0 green:242./255. blue:183./255. alpha:1.0];
    [((ButtonWithImageAndText*) [routePlanningButton customView]) setTextColor:color];
    [((ButtonWithImageAndText*) [routePlanningButton customView]) setFontSize:15];

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

- (void) handleTap:(UITapGestureRecognizer*)recognizer
{
    if ([recognizer state] == UIGestureRecognizerStateEnded)
    {
        CGPoint tapPoint = [recognizer locationInView:_wwv];
        WWPickedObjectList* pickedObjects = [_wwv pick:tapPoint];

        WWPickedObject* topObject = [pickedObjects topPickedObject];

        if ([[topObject userObject] isKindOfClass:[WWPointPlacemark class]])
        {
            WWPointPlacemark* pm = (WWPointPlacemark*) [topObject userObject];
            if ([pm userObject] != nil)
            {
                if ([[[topObject parentLayer] displayName] isEqualToString:@"METAR Weather"])
                    [self showMETARData:pm];
            }
        }
    }
}

- (void) showMETARData:(WWPointPlacemark*)pm
{
    // Compute a screen position that corresponds with the placemarks' position, then show data popover at
    // that screen position.

    WWPosition* pmPos = [pm position];
    WWVec4* pmPoint = [[WWVec4 alloc] init];
    WWVec4* screenPoint = [[WWVec4 alloc] init];

    [[[_wwv sceneController] globe] computePointFromPosition:[pmPos latitude] longitude:[pmPos longitude]
                                                    altitude:[pmPos altitude] outputPoint:pmPoint];
    [[[_wwv sceneController] navigatorState] project:pmPoint result:screenPoint];

    CGPoint uiPoint = [[[_wwv sceneController] navigatorState] convertPointToView:screenPoint];
    CGRect rect = CGRectMake(uiPoint.x, uiPoint.y, 1, 1);

    // Give the controller the placemark's dictionary.
    [metarDataViewController setEntries:[pm userObject]];

    // Ensure that the first line of the data is at the top of the data table.
    [[metarDataViewController tableView] scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]
                                               atScrollPosition:UITableViewScrollPositionTop animated:YES];

    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
    {
        if (metarDataPopoverController == nil)
            metarDataPopoverController = [[UIPopoverController alloc] initWithContentViewController:metarDataViewController];
        [metarDataPopoverController presentPopoverFromRect:rect inView:_wwv
                                  permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
    }
    else
    {
        [((UINavigationController*) [self parentViewController]) pushViewController:metarDataViewController animated:YES];
        [((UINavigationController*) [self parentViewController]) setNavigationBarHidden:NO animated:YES];
    }
}

@end
