/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
@version $Id$
 */

#import "ViewController.h"
#import "WorldWind/WorldWindConstants.h"
#import "WorldWind/WWLog.h"
#import "WorldWind/Geometry/WWLocation.h"
#import "WorldWind/Navigate/WWNavigator.h"
#import "WorldWind/Render/WWSceneController.h"
#import "WorldWind/Layer/WWLayerList.h"
#import "WorldWind/Layer/WWShowTessellationLayer.h"
#import "WorldWind/Layer/WWBMNGLayer.h"
#import "WorldWind/Layer/WWDAFIFLayer.h"
#import "WorldWind/Layer/WWI3LandsatLayer.h"
#import "WorldWind/Layer/WWBingLayer.h"
#import "LayerListController.h"
#import "LocationController.h"
#import "AnyGestureRecognizer.h"
#import "WorldWind/Layer/WWRenderableLayer.h"
#import "WorldWind/Shapes/WWPath.h"
#import "WorldWind/Geometry/WWPosition.h"

#define TOOLBAR_HEIGHT 44
#define SEARCHBAR_PLACEHOLDER @"Search or Address"

@implementation ViewController
{
    UIBarButtonItem* layerButton;
    LayerListController* layerListController;
    UIPopoverController* layerListPopoverController;
    LocationController* locationController;
    UISearchBar* searchBar;
    CLGeocoder* geocoder;
    AnyGestureRecognizer* anyGestureRecognizer;
}

- (id) init
{
    self = [super initWithNibName:nil bundle:nil];

    if (self != nil)
    {
        self->locationController = [[LocationController alloc] init];
        [self->locationController setState:LocationControllerStateShowInitial];
        self->geocoder = [[CLGeocoder alloc] init];
        self->anyGestureRecognizer = [[AnyGestureRecognizer alloc] initWithTarget:self action:@selector(handleAnyGestureFrom:)];

        // Set up to observe notifications when the navigator recognizes a gesture.
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(handleNotification:)
                                                     name:WW_NAVIGATOR_GESTURE_RECOGNIZED
                                                   object:nil];
    }

    return self;
}

- (void) loadView
{
    self.view = [[UIView alloc] initWithFrame:[[UIScreen mainScreen] applicationFrame]];
    self.view.autoresizesSubviews = YES;

    [self createWorldWindView];
    [self createToolbar];
}

- (void) viewDidLoad
{
    [super viewDidLoad];

    WWLog(@"View Did Load");

    WWLayerList* layers = [[_wwv sceneController] layers];
    //[layers addLayer:[[WWBMNGOneImageLayer alloc] init]];
    [layers addLayer:[[WWBMNGLayer alloc] init]];
    [layers addLayer:[[WWI3LandsatLayer alloc] init]];
    [layers addLayer:[[WWBingLayer alloc] init]];
    [layers addLayer:[[WWDAFIFLayer alloc] initWithSpecialActivityAirspaceLayers]];
    [layers addLayer:[[WWDAFIFLayer alloc] initWithNavigationLayers]];
    [layers addLayer:[[WWDAFIFLayer alloc] initWithAirportLayers]];
    [[layers layerAtIndex:3] setEnabled:NO];
    [[layers layerAtIndex:4] setEnabled:NO];
    [[layers layerAtIndex:5] setEnabled:NO];

    [self createPathsLayer];

    [self->locationController setView:_wwv];
}

- (void) createPathsLayer
{
    WWLayerList* layers = [[_wwv sceneController] layers];

    WWRenderableLayer* renderableLayer = [[WWRenderableLayer alloc] init];
    [renderableLayer setDisplayName:@"Paths"];
    [layers addLayer:renderableLayer];

    NSMutableArray* positions = [[NSMutableArray alloc] init];
    [positions addObject:[[WWPosition alloc] initWithDegreesLatitude:0 longitude:0 altitude:1000]];
    [positions addObject:[[WWPosition alloc] initWithDegreesLatitude:1 longitude:1 altitude:1000]];

    WWPath* path01 = [[WWPath alloc] initWithPositions:positions];
    [renderableLayer addRenderable:path01];
}

/*!
    Returns a Boolean value indicating whether the view controller supports the specified orientation. Returns YES for
    the iPad idom, and returns YES for the iPhone idom except when the specified toInterfaceOrientation is
    UIInterfaceOrientationPortraitUpsideDown. This behavior matches the default supported interface orientations in iOS
    6.0.

    This method is deprecated in iOS 6.0, but is required in iOS 5.x in order to support device orientation changes
    other than portrait. In iOS 6.0, auto rotation and supported interface orientations are handled by entries in the
    application's Info.plist file, or alternatively by overriding the method supportedInterfaceOrientations.

    @param toInterfaceOrientation
        The orientation of the app’s user interface after the rotation. The possible values are described in UIInterfaceOrientation.

    @result Returns
        YES if the view controller auto-rotates its view to the specified orientation; otherwise, NO.
 */
- (BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
        return YES;
    else // UIUserInterfaceIdiomPhone
        return toInterfaceOrientation != UIInterfaceOrientationPortraitUpsideDown;
}

- (void) createWorldWindView
{
    CGFloat wwvWidth = self.view.bounds.size.width;
    CGFloat wwvHeight = self.view.bounds.size.height - TOOLBAR_HEIGHT;
    CGFloat wwvOriginY = self.view.bounds.origin.y + TOOLBAR_HEIGHT;

    _wwv = [[WorldWindView alloc] initWithFrame:CGRectMake(0, wwvOriginY, wwvWidth, wwvHeight)];
    if (_wwv == nil)
    {
        NSLog(@"Unable to create a WorldWindView");
        return;
    }

    [self.view addSubview:_wwv];
}

- (void) createToolbar
{
    _toolbar = [[UIToolbar alloc] init];
    _toolbar.frame = CGRectMake(0, 0, self.view.frame.size.width, TOOLBAR_HEIGHT);
    [_toolbar setAutoresizingMask:UIViewAutoresizingFlexibleWidth];
    [_toolbar setBarStyle:UIBarStyleBlack];
    [_toolbar setTranslucent:NO];

    [self.view addSubview:_toolbar];

    self->layerButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"LayerList"]
                                                         style:UIBarButtonItemStylePlain
                                                        target:self action:@selector(handleLayerButtonTap)];
    layerListController = [[LayerListController alloc] initWithWorldWindView:_wwv];
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
    {
        self->layerListPopoverController =
                [[UIPopoverController alloc] initWithContentViewController:layerListController];
    }

    UIBarButtonItem* trackButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"LocationArrow"]
                                                                    style:UIBarButtonItemStylePlain
                                                                   target:self action:@selector(handleLocationButtonTap)];

    self->searchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(0, 0, 200, TOOLBAR_HEIGHT)];
    [self->searchBar setPlaceholder:SEARCHBAR_PLACEHOLDER];
    UIBarButtonItem* searchBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:self->searchBar];
    [self->searchBar setDelegate:self];

    UIBarButtonItem* flexibleSpace1 = [[UIBarButtonItem alloc]
            initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    UIBarButtonItem* flexibleSpace2 = [[UIBarButtonItem alloc]
            initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];

    [_toolbar setItems:[NSArray arrayWithObjects:
            layerButton,
            flexibleSpace1,
            trackButton,
            flexibleSpace2,
            searchBarButtonItem,
            nil]];
}

- (void) handleLayerButtonTap
{
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
    {
        [((UINavigationController*) [self parentViewController]) pushViewController:layerListController animated:YES];
    }
    else
    {
        [layerListPopoverController presentPopoverFromBarButtonItem:self->layerButton
                                           permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
    }
}

- (void) handleLocationButtonTap
{
    LocationControllerState state = [self->locationController state];

    if (state == LocationControllerStateDisabled || state == LocationControllerStateShowInitial)
    {
        [self->locationController setState:LocationControllerStateForecast];
    }
    else if (state == LocationControllerStateForecast)
    {
        [self->locationController setState:LocationControllerStateDisabled];
    }
    else
    {
        WWLog(@"Unknown location controller state: %d", state);
    }
}

- (void) handleNotification:(NSNotification*)notification
{
    if ([[notification name] isEqualToString:WW_NAVIGATOR_GESTURE_RECOGNIZED])
    {
        [self->locationController setState:LocationControllerStateDisabled];
    }
}

- (void) dismissSearchBar
{
    [self->searchBar resignFirstResponder];
    [_wwv removeGestureRecognizer:self->anyGestureRecognizer];
}

- (void) searchBarTextDidBeginEditing:(UISearchBar*)aSearchBar
{
    [_wwv addGestureRecognizer:self->anyGestureRecognizer];
}

- (void) searchBarSearchButtonClicked:(UISearchBar*)aSearchBar
{
    NSString* searchText = [aSearchBar text];
    if (searchText != nil && [searchText length] > 0)
    {
        [self->geocoder geocodeAddressString:searchText
                           completionHandler:^(NSArray* placemarks, NSError* error)
                           {
                               [self handleGeocodeResults:placemarks error:error];
                           }
        ];
    };

    [self dismissSearchBar];
}

- (void) handleGeocodeResults:(NSArray*)placemarks error:(NSError*)error
{
    if (placemarks != nil && [placemarks count] > 0)
    {
        [self->locationController setState:LocationControllerStateDisabled];

        CLPlacemark* lastPlacemark = [placemarks objectAtIndex:0];
        CLRegion* region = [lastPlacemark region];
        WWLocation* center = [[WWLocation alloc] initWithCLCoordinate:[region center]];
        double radius = [region radius];

        [[_wwv navigator] gotoRegionWithCenter:center radius:radius animate:YES];
    }
    else
    {
        [[[UIAlertView alloc] initWithTitle:@"No Results Found"
                                    message:nil delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil] show];
    }
}

- (void) handleAnyGestureFrom:(AnyGestureRecognizer*)recognizer
{
    UIGestureRecognizerState state = [recognizer state];
    if (state == UIGestureRecognizerStateEnded || state == UIGestureRecognizerStateCancelled)
    {
        [self dismissSearchBar];
    }
}

- (void) viewWillAppear:(BOOL)animated
{
    [((UINavigationController*) [self parentViewController]) setNavigationBarHidden:YES animated:YES];
}

@end