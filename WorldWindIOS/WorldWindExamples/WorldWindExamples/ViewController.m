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
#import "WorldWind/Navigate/WWNavigator.h"
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
#import "WorldWind/Util/WWUtil.h"
#import "FAAChartsAlaskaLayer.h"
#import "WorldWind/Pick/WWPickedObjectList.h"
#import "WorldWind/Geometry/WWVec4.h"
#import "WorldWind/Pick/WWPickedObject.h"
#import "WorldWind/Shapes/WWPointPlacemark.h"
#import "CrashDataViewController.h"

#define TOOLBAR_HEIGHT 44
#define SEARCHBAR_PLACEHOLDER @"Search or Address"

@implementation ViewController
{
    UIBarButtonItem* layerButton;
    UIBarButtonItem* navigatorButton;
    UIBarButtonItem* trackButton;
    UIBarButtonItem* flightButton;
    LayerListController* layerListController;
    UIPopoverController* layerListPopoverController;
    UIPopoverController* crashDataPopoverController;
    CrashDataViewController* crashDataViewController;
    NavigatorSettingsController* navigatorSettingsController;
    UIPopoverController* navigatorSettingsPopoverController;
    TrackingController* trackingController;
    PathFollower* pathFollower;
    UISearchBar* searchBar;
    CLGeocoder* geocoder;
    AnyGestureRecognizer* anyGestureRecognizer;
    UITapGestureRecognizer* tapGestureRecognizer;
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
    crashDataPopoverController = [[UIPopoverController alloc] initWithContentViewController:crashDataViewController];

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

    [self makeTrackingController];
    [self makeFlightPathsLayer];
//
//    layer = [[WWShowTessellationLayer alloc] init];
//    [layers addLayer:layer];

    layer = [[CrashDataLayer alloc] initWithURL:@"http://worldwindserver.net/crashes.kml"];
    [layer setEnabled:NO];
    [layers addLayer:layer];

    tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
    [tapGestureRecognizer setNumberOfTapsRequired:1];
    [_wwv addGestureRecognizer:tapGestureRecognizer];
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
    NSData* data = [WWUtil retrieveUrl:url timeout:5];
    if (data == nil)
    {
        WWLog(@"Unable to download flight paths file %@", [url absoluteString]);
        return;
    }

    NSError* error;
    NSDictionary* jData = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
    if (error != nil)
    {
        NSDictionary* userInfo = [error userInfo];
        NSString* errMsg = [[userInfo objectForKey:NSUnderlyingErrorKey] localizedDescription];
        WWLog(@"Error %@ reading flight paths file %@", errMsg, [url absoluteString]);
        return;
    }

    WWRenderableLayer* pathsLayer = [[WWRenderableLayer alloc] init];
    [pathsLayer setDisplayName:@"Alaska Flight Paths"];
    [[[_wwv sceneController] layers] addLayer:pathsLayer];

    WWShapeAttributes* attributes = [[WWShapeAttributes alloc] init];
    [attributes setOutlineEnabled:true];
    [attributes setInteriorEnabled:false];
    [attributes setOutlineColor:[[WWColor alloc] initWithR:1 g:0 b:0 a:1]];
    [attributes setOutlineWidth:5];

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
        [path setAttributes:attributes];
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
    UINavigationController* navController = [[UINavigationController alloc]
            initWithRootViewController:layerListController];
    layerListPopoverController = [[UIPopoverController alloc] initWithContentViewController:navController];

    navigatorButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"12-eye"]
                                                       style:UIBarButtonItemStylePlain
                                                      target:self action:@selector(handleNavigatorButtonTap)];
    navigatorSettingsController = [[NavigatorSettingsController alloc] initWithWorldWindView:_wwv];
    navController = [[UINavigationController alloc] initWithRootViewController:navigatorSettingsController];
    navigatorSettingsPopoverController = [[UIPopoverController alloc] initWithContentViewController:navController];

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
    [fixedSpace1 setWidth:40];

    [_toolbar setItems:[NSArray arrayWithObjects:
            layerButton,
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
    [layerListPopoverController presentPopoverFromBarButtonItem:layerButton
                                       permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
}

- (void) handleNavigatorButtonTap
{
    [navigatorSettingsPopoverController presentPopoverFromBarButtonItem:navigatorButton
                                               permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
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

        WWVec4* pickPoint = [[WWVec4 alloc] initWithCoordinates:tapPoint.x y:tapPoint.y z:0];
        WWPickedObjectList* pickedObjects = [_wwv pick:pickPoint];

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
            id entries = [pm userObject];
            if (entries != nil)
            {
                [crashDataViewController setEntries:entries];
                CGRect rect = CGRectMake(tapPoint.x, tapPoint.y, 4, 4);
                [[crashDataViewController tableView] scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]
                                                           atScrollPosition:UITableViewScrollPositionTop animated:YES];
                [crashDataPopoverController presentPopoverFromRect:rect inView:_wwv
                                          permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
            }
        }
    }
}

@end