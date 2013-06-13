/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
@version $Id$
 */

#import "ViewController.h"
#import "LayerListController.h"
#import "NavigatorSettingsController.h"
#import "TrackingController.h"
#import "AnyGestureRecognizer.h"
#import "PathFollower.h"
#import "CrashDataLayer.h"
#import "WorldWind/WorldWindConstants.h"
#import "WorldWind/WWLog.h"
#import "WorldWind/Geometry/WWLocation.h"
#import "WorldWind/Geometry/WWSector.h"
#import "WorldWind/Navigate/WWNavigator.h"
#import "WorldWind/Navigate/WWNavigatorState.h"
#import "WorldWind/Render/WWSceneController.h"
#import "WorldWind/Layer/WWLayerList.h"
#import "WorldWind/Layer/WWBMNGLayer.h"
#import "WorldWind/Layer/WWDAFIFLayer.h"
#import "WorldWind/Layer/WWI3LandsatLayer.h"
#import "WorldWind/Layer/WWBingLayer.h"
#import "WorldWind/Layer/WWOpenStreetMapLayer.h"
#import "WorldWind/Shapes/WWPath.h"
#import "WorldWind/Geometry/WWPosition.h"
#import "WorldWind/Shapes/WWShapeAttributes.h"
#import "WorldWind/Util/WWColor.h"
#import "WorldWind/Layer/WWOpenWeatherMapLayer.h"
#import "FAAChartsAlaskaLayer.h"
#import "WorldWind/Pick/WWPickedObjectList.h"
#import "WorldWind/Geometry/WWVec4.h"
#import "WorldWind/Pick/WWPickedObject.h"
#import "WorldWind/Shapes/WWPointPlacemark.h"
#import "CrashDataViewController.h"
#import "WorldWind/Terrain/WWGlobe.h"
#import "WMSServerListController.h"
#import "WorldWind/Util/WWRetriever.h"
#import "WorldWind/Layer/WWEarthAtNightLayer.h"
#import "METARLayer.h"
#import "METARDataViewController.h"
#import "BulkRetrieverController.h"
#import "FrameStatisticsController.h"

#define TOOLBAR_HEIGHT 44
#define SEARCHBAR_PLACEHOLDER @"Search or Address"

@implementation ViewController
{
    UIBarButtonItem* layerButton;
    UIBarButtonItem* wmsServersButton;
    UIBarButtonItem* bulkRetrieverButton;
    UIBarButtonItem* navigatorButton;
    UIBarButtonItem* trackButton;
    UIBarButtonItem* flightButton;
    LayerListController* layerListController;
    WMSServerListController* wmsServersListController;
    UIPopoverController* layerListPopoverController;
    UIPopoverController* wmsServersListPopoverController;
    BulkRetrieverController* bulkRetrieverController;
    UIPopoverController* bulkRetrieverPopoverController;
    UIPopoverController* crashDataPopoverController;
    CrashDataViewController* crashDataViewController;
    UIPopoverController* metarDataPopoverController;
    FrameStatisticsController* statisticsController;
    METARDataViewController* metarDataViewController;
    NavigatorSettingsController* navigatorSettingsController;
    UIPopoverController* navigatorSettingsPopoverController;
    TrackingController* trackingController;
    PathFollower* pathFollower;
    UISearchBar* searchBar;
    CLGeocoder* geocoder;
    AnyGestureRecognizer* anyGestureRecognizer;
    UITapGestureRecognizer* tapGestureRecognizer;
    UITapGestureRecognizer* tripleTapGestureRecognizer;
    id selectedPath;
}

- (id) init
{
    self = [super initWithNibName:nil bundle:nil];

    if (self != nil)
    {
        self->geocoder = [[CLGeocoder alloc] init];
        self->anyGestureRecognizer = [[AnyGestureRecognizer alloc] initWithTarget:self action:@selector(handleAnyGestureFrom:)];
    }

    crashDataViewController = [[CrashDataViewController alloc] init];
    metarDataViewController = [[METARDataViewController alloc] init];

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

    WWLayer* layer = [[WWBMNGLayer alloc] init];
    [layers addLayer:layer];

    layer = [[WWI3LandsatLayer alloc] init];
    [layers addLayer:layer];

    layer = [[WWBingLayer alloc] init];
    [layers addLayer:layer];

    layer = [[WWOpenStreetMapLayer alloc] init];
    [layer setOpacity:0.75];
    [layers addLayer:layer];

    layer = [[WWDAFIFLayer alloc] init];
    [layer setEnabled:NO];
    [layers addLayer:layer];

    layer = [[FAAChartsAlaskaLayer alloc] init];
    [layer setEnabled:NO];
    [layers addLayer:layer];

    layer = [[WWOpenWeatherMapLayer alloc] init];
    [layer setOpacity:0.4];
    [layer setEnabled:NO];
    [layers addLayer:layer];

    layer = [[WWEarthAtNightLayer alloc] init];
    [layer setOpacity:0.75];
    [layer setEnabled:NO];
    [layers addLayer:layer];

    [self makeTrackingController];
    [self makeFlightPathsLayer];
//
//    layer = [[WWShowTessellationLayer alloc] init];
//    [layers addLayer:layer];

    layer = [[CrashDataLayer alloc] initWithURL:@"http://worldwindserver.net/crashes.kml"];
    [layer setEnabled:NO];
    [layers addLayer:layer];

    layer = [[METARLayer alloc] init];
    [layer setEnabled:NO];
    [layers addLayer:layer];

    tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
    [tapGestureRecognizer setNumberOfTapsRequired:1];
    [tapGestureRecognizer setNumberOfTouchesRequired:1];
    [_wwv addGestureRecognizer:tapGestureRecognizer];

    tripleTapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTripleTap:)];
    [tripleTapGestureRecognizer setNumberOfTapsRequired:3];
    [tripleTapGestureRecognizer setNumberOfTouchesRequired:2];
    [_wwv addGestureRecognizer:tripleTapGestureRecognizer];
}

- (void) makeTrackingController
{
    trackingController = [[TrackingController alloc] initWithView:_wwv];
    [trackingController addObserver:self forKeyPath:@"enabled"
                            options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionInitial context:NULL];
}

- (void) makeFlightPathsLayer
{
    NSURL* url = [[NSURL alloc] initWithString:@"http://worldwindserver.net/PassageWays.json"];
    WWRetriever* retriever = [[WWRetriever alloc] initWithUrl:url timeout:5
                                                finishedBlock:^(WWRetriever* myRetriever)
                                                {
                                                    [self doMakeFlightPathsLayer:myRetriever];
                                                }];
    [retriever performRetrieval];
}

- (void) doMakeFlightPathsLayer:(WWRetriever*)retriever
{
    if (![[retriever status] isEqualToString:WW_SUCCEEDED] || [[retriever retrievedData] length] == 0)
    {
        WWLog(@"Unable to download flight paths file %@", [[retriever url] absoluteString]);
        return;
    }

    NSData* data = [retriever retrievedData];

    NSError* error;
    NSDictionary* jData = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
    if (error != nil)
    {
        NSDictionary* userInfo = [error userInfo];
        NSString* errMsg = [[userInfo objectForKey:NSUnderlyingErrorKey] localizedDescription];
        WWLog(@"Error %@ reading flight paths file %@", errMsg, [[retriever url] absoluteString]);
        return;
    }

    WWRenderableLayer* pathsLayer = [[WWRenderableLayer alloc] init];
    [pathsLayer setDisplayName:@"Alaska Flight Paths"];
    [[[_wwv sceneController] layers] addLayer:pathsLayer];

    // Path colors derived from http://www.colorcombos.com/color-schemes/95/ColorCombo95.html
    WWShapeAttributes* attrs = [[WWShapeAttributes alloc] init];
    [attrs setOutlineColor:[[WWColor alloc] initWithR:0.8 g:0.2 b:0.2 a:1]];
    [attrs setOutlineWidth:3];

    WWShapeAttributes* highlightAttrs = [[WWShapeAttributes alloc] init];
    [highlightAttrs setOutlineColor:[[WWColor alloc] initWithR:1.0 g:0.6 b:0 a:1]];
    [highlightAttrs setOutlineWidth:5];

    NSArray* features = [jData valueForKey:@"features"];
    for (NSUInteger i = 0; i < [features count]; i++)
    {
        // Make a Path
        NSDictionary* entry = (NSDictionary*) [features objectAtIndex:i];
        NSDictionary* geometry = [entry valueForKey:@"geometry"];

        // Make the path's positions
        NSArray* coords = [geometry valueForKey:@"coordinates"];
        NSMutableArray* pathCoords = [[NSMutableArray alloc] initWithCapacity:[coords count]];
        for (NSUInteger j = 0; j < [coords count]; j++)
        {
            NSArray* values = [coords objectAtIndex:j];
            NSNumber* lon = [values objectAtIndex:0];
            NSNumber* lat = [values objectAtIndex:1];
            NSDecimalNumber* alt = [values objectAtIndex:2];

            WWPosition* pos = [[WWPosition alloc] initWithDegreesLatitude:[lat doubleValue]
                                                                longitude:[lon doubleValue]
                                                                 altitude:([alt doubleValue] > 0 ? [alt doubleValue]
                                                                         : 4572)]; // 15,000 feet
            [pathCoords addObject:pos];
        }

        WWPath* path = [[WWPath alloc] initWithPositions:pathCoords];
        [path setDisplayName:[NSString stringWithFormat:@"Flight Path %d", i + 1]];
        [path setAltitudeMode:WW_ALTITUDE_MODE_ABSOLUTE];
        [path setAttributes:attrs];
        [path setHighlightAttributes:highlightAttrs];
        [pathsLayer addRenderable:path];

        if (i == [features count] - 1)
        {
            pathFollower = [[PathFollower alloc] initWithPath:path speed:135 view:_wwv]; // ~300 MPH
            [pathFollower addObserver:self forKeyPath:@"enabled"
                              options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionInitial context:NULL];
        }
    }

}

/*!
    Returns a Boolean value indicating whether the view controller supports the specified orientation. Returns YES for
    the iPad idiom, and returns YES for the iPhone idom except when the specified toInterfaceOrientation is
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

    //[_wwv setContentScaleFactor:[[UIScreen mainScreen] scale]]; // enable retina resolution
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

    layerButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"LayerList"]
                                                   style:UIBarButtonItemStylePlain
                                                  target:self action:@selector(handleLayerButtonTap)];
    layerListController = [[LayerListController alloc] initWithWorldWindView:_wwv];

    wmsServersButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"401-globe"]
                                                        style:UIBarButtonItemStylePlain
                                                       target:self action:@selector(handleWMSServersListButtonTap)];
    wmsServersListController = [[WMSServerListController alloc] initWithWorldWindView:_wwv];

    bulkRetrieverButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"265-download"]
                                                           style:UIBarButtonItemStylePlain
                                                          target:self action:@selector(handleBulkRetrieverButtonTap)];
    [bulkRetrieverButton setEnabled:NO];
    bulkRetrieverController = [[BulkRetrieverController alloc] initWithWorldWindView:_wwv];

    navigatorButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"12-eye"]
                                                       style:UIBarButtonItemStylePlain
                                                      target:self action:@selector(handleNavigatorButtonTap)];
    navigatorSettingsController = [[NavigatorSettingsController alloc] initWithWorldWindView:_wwv];

    trackButton = [[UIBarButtonItem alloc] initWithImage:nil style:UIBarButtonItemStylePlain
                                                  target:self action:@selector(handleTrackButtonTap)];

    flightButton = [[UIBarButtonItem alloc] initWithImage:nil style:UIBarButtonItemStylePlain
                                                   target:self action:@selector(handleFlightButtonTap)];

    self->searchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(0, 0, 200, TOOLBAR_HEIGHT)];
    [self->searchBar setPlaceholder:SEARCHBAR_PLACEHOLDER];
    UIBarButtonItem* searchBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:self->searchBar];
    [self->searchBar setDelegate:self];

    UIBarButtonItem* flexibleSpace1 = [[UIBarButtonItem alloc]
            initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    UIBarButtonItem* flexibleSpace2 = [[UIBarButtonItem alloc]
            initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    UIBarButtonItem* fixedSpace1 = [[UIBarButtonItem alloc]
            initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
    [fixedSpace1 setWidth:UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad ? 40 : 10];

    [_toolbar setItems:[NSArray arrayWithObjects:
            layerButton,
            fixedSpace1,
            wmsServersButton,
            fixedSpace1,
            bulkRetrieverButton,
            flexibleSpace1,
            navigatorButton,
            fixedSpace1,
            trackButton,
            fixedSpace1,
            flightButton,
            flexibleSpace2,
            searchBarButtonItem,
            nil]];
}

- (void) handleLayerButtonTap
{
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
    {
        if (layerListPopoverController == nil)
        {
            UINavigationController* navController = [[UINavigationController alloc]
                    initWithRootViewController:layerListController];
            layerListPopoverController = [[UIPopoverController alloc] initWithContentViewController:navController];
        }
        [layerListPopoverController presentPopoverFromBarButtonItem:layerButton
                                           permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
    }
    else
    {
        [((UINavigationController*) [self parentViewController]) pushViewController:layerListController animated:YES];
        [((UINavigationController*) [self parentViewController]) setNavigationBarHidden:NO animated:YES];
    }
}

- (void) handleWMSServersListButtonTap
{
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
    {
        if (wmsServersListPopoverController == nil)
        {
            UINavigationController* navController = [[UINavigationController alloc]
                    initWithRootViewController:wmsServersListController];
            wmsServersListPopoverController = [[UIPopoverController alloc] initWithContentViewController:navController];
        }
        [wmsServersListPopoverController presentPopoverFromBarButtonItem:wmsServersButton
                                                permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
    }
    else
    {
        [((UINavigationController*) [self parentViewController]) pushViewController:wmsServersListController animated:YES];
        [((UINavigationController*) [self parentViewController]) setNavigationBarHidden:NO animated:YES];
    }
}

- (void) handleBulkRetrieverButtonTap
{
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
    {
        if (bulkRetrieverPopoverController == nil)
        {
            UINavigationController* navController = [[UINavigationController alloc]
                    initWithRootViewController:bulkRetrieverController];
            bulkRetrieverPopoverController = [[UIPopoverController alloc] initWithContentViewController:navController];
        }
        [bulkRetrieverPopoverController presentPopoverFromBarButtonItem:bulkRetrieverButton
                                               permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
    }
    else
    {
        [((UINavigationController*) [self parentViewController]) pushViewController:bulkRetrieverController animated:YES];
        [((UINavigationController*) [self parentViewController]) setNavigationBarHidden:NO animated:YES];
    }
}

- (void) handleNavigatorButtonTap
{
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
    {
        if (navigatorSettingsPopoverController == nil)
        {
            UINavigationController* navController = [[UINavigationController alloc]
                    initWithRootViewController:navigatorSettingsController];
            navigatorSettingsPopoverController = [[UIPopoverController alloc] initWithContentViewController:navController];
        }
        [navigatorSettingsPopoverController presentPopoverFromBarButtonItem:navigatorButton
                                                   permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
    }
    else
    {
        [((UINavigationController*) [self parentViewController]) pushViewController:navigatorSettingsController animated:YES];
        [((UINavigationController*) [self parentViewController]) setNavigationBarHidden:NO animated:YES];
    }
}

- (void) handleTrackButtonTap
{
    [trackingController setEnabled:![trackingController isEnabled]];

    if ([trackingController isEnabled])
    {
        [pathFollower setEnabled:NO];
    }
}

- (void) handleFlightButtonTap
{
    [pathFollower setEnabled:![pathFollower isEnabled]];

    if ([pathFollower isEnabled])
    {
        [trackingController setEnabled:NO];
    }
}

- (void) observeValueForKeyPath:(NSString*)keyPath
                       ofObject:(id)object
                         change:(NSDictionary*)change
                        context:(void*)context
{
    if (object == trackingController && [keyPath isEqualToString:@"enabled"])
    {
        NSNumber* value = [change objectForKey:NSKeyValueChangeNewKey];
        [trackButton setImage:[UIImage imageNamed:[value boolValue] ? @"LocationArrowWithLine" : @"LocationArrow"]];
    }
    else if (object == pathFollower && [keyPath isEqualToString:@"enabled"])
    {
        NSNumber* value = [change objectForKey:NSKeyValueChangeNewKey];
        [flightButton setImage:[UIImage imageNamed:[value boolValue] ? @"38-airplane-location" : @"38-airplane"]];
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
        CLPlacemark* firstPlacemark = [placemarks objectAtIndex:0];
        CLRegion* region = [firstPlacemark region];
        WWPosition* center = [[WWPosition alloc] initWithCLCoordinate:[region center] altitude:0];
        double radius = [region radius];

        [[_wwv navigator] animateToRegionWithCenter:center radius:radius overDuration:WWNavigatorDurationDefault];
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

- (void) handleTap:(UITapGestureRecognizer*)recognizer
{
    if ([recognizer state] == UIGestureRecognizerStateEnded)
    {
        CGPoint tapPoint = [recognizer locationInView:_wwv];
        WWPickedObjectList* pickedObjects = [_wwv pick:tapPoint];

//        if ([pickedObjects terrainObject] != nil)
//        {
//            WWPosition* position = [[pickedObjects terrainObject] position];
//            NSLog(@"%f, %f, %f", [position latitude], [position longitude], [position altitude]);
//        }
//
//        NSLog(@"%d picked objects", [[pickedObjects objects] count]);

        WWPickedObject* topObject = [pickedObjects topPickedObject];
//        if (![topObject isTerrain])
//        {
//            NSString* displayName = @"NO NAME";
//            if ([[topObject userObject] respondsToSelector:@selector(displayName)])
//            {
//                displayName = [[topObject userObject] displayName];
//            }
//            NSLog(@"Non-terrain object on top: %@", displayName);
//        }

        if ([[topObject userObject] isKindOfClass:[WWPointPlacemark class]])
        {
            WWPointPlacemark* pm = (WWPointPlacemark*) [topObject userObject];
            if ([pm userObject] != nil)
            {
                if ([[[topObject parentLayer] displayName] isEqualToString:@"Accidents"])
                    [self showCrashData:pm];
                else if ([[[topObject parentLayer] displayName] isEqualToString:@"METAR Weather"])
                    [self showMETARData:pm];
            }
        }

        if ([[topObject userObject] isKindOfClass:[WWPath class]])
        {
            WWPath* path = (WWPath*) [topObject userObject];
            [self setSelectedPath:path];
        }
        else
        {
            [self setSelectedPath:nil];
        }
    }
}

- (void) handleTripleTap:(UITapGestureRecognizer*)recognizer
{
    if ([recognizer state] == UIGestureRecognizerStateEnded)
    {
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
        {
            if (statisticsController == nil)
            {
                statisticsController = [[FrameStatisticsController alloc] initWithView:_wwv];
                CGRect rect = CGRectMake([_wwv bounds].size.width - 210, 50, 200, 320);
                [[statisticsController view] setFrame:rect];
                [self addChildViewController:statisticsController];
                [[self view] addSubview:[statisticsController view]];
                [statisticsController didMoveToParentViewController:self];
            }
            else
            {
                [statisticsController willMoveToParentViewController:nil];
                [[statisticsController view] removeFromSuperview];
                [statisticsController removeFromParentViewController];
                statisticsController = nil;
            }
        }
        else
        {
            if (statisticsController == nil)
                statisticsController = [[FrameStatisticsController alloc] initWithView:_wwv];
            [((UINavigationController*) [self parentViewController]) pushViewController:statisticsController animated:YES];
            [((UINavigationController*) [self parentViewController]) setNavigationBarHidden:NO animated:YES];
        }
    }
}

- (void) showCrashData:(WWPointPlacemark*)pm
{
    // Compute a screen position that corresponds with the placemarks' position, then show the  crash data popover at
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
    [crashDataViewController setEntries:[pm userObject]];

    // Ensure that the first line of the data is at the top of the data table.
    [[crashDataViewController tableView] scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]
                                               atScrollPosition:UITableViewScrollPositionTop animated:YES];

    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
    {
        if (crashDataPopoverController == nil)
            crashDataPopoverController = [[UIPopoverController alloc] initWithContentViewController:crashDataViewController];
        [crashDataPopoverController presentPopoverFromRect:rect inView:_wwv
                                  permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
    }
    else
    {
        [((UINavigationController*) [self parentViewController]) pushViewController:crashDataViewController animated:YES];
        [((UINavigationController*) [self parentViewController]) setNavigationBarHidden:NO animated:YES];
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

- (void) setSelectedPath:(WWPath*)path
{
    if ([[bulkRetrieverController operationQueue] operationCount] > 0)
    {
        return; // Prevent selection changes while the bulk retriever is running.
    }

    [selectedPath setHighlighted:NO];
    [path setHighlighted:YES];
    selectedPath = path;
    [[NSNotificationCenter defaultCenter] postNotificationName:WW_REQUEST_REDRAW object:self];

    if (path != nil)
    {
        [bulkRetrieverController setSector:[[WWSector alloc] initWithLocations:[path positions]]];
        [bulkRetrieverButton setEnabled:YES];
    }
    else
    {
        [bulkRetrieverController setSector:nil];
        [bulkRetrieverButton setEnabled:NO];
    }
}

@end