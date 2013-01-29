/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
@version $Id$
 */

#import "ViewController.h"
#import "WorldWind/WorldWindConstants.h"
#import "WorldWind/Render/WWSceneController.h"
#import "WorldWind/Layer/WWLayerList.h"
#import "WorldWind/Layer/WWShowTessellationLayer.h"
#import "WorldWind/WWLog.h"
#import "WorldWind/Layer/WWBMNGLayer.h"
#import "WorldWind/Layer/WWDAFIFLayer.h"
#import "WorldWind/Layer/WWI3LandsatLayer.h"
#import "WorldWind/Layer/WWBingLayer.h"
#import "LayerListController.h"

@implementation ViewController
{
    UIBarButtonItem* layerButton;
    UIPopoverController* layerListPopoverController;
}

- (id) init
{
    self = [super initWithNibName:nil bundle:nil];

    if (self != nil)
    {
        self->initialLocationController = [[LocationController alloc] init];
        self->trackingLocationController = [[LocationController alloc] init];
        [self->initialLocationController setRepeats:NO];
        [self->trackingLocationController setRepeats:YES];
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
    //[layers addLayer:[[WWDAFIFLayer alloc] initWithNavigationLayers]];
    //[layers addLayer:[[WWDAFIFLayer alloc] initWithAirportLayers]];

    // Start a non-repeating location controller in order to navigate to the device's current location after the
    // World Wind view loads.
    [self->trackingLocationController setView:_wwv];
    [self->initialLocationController setView:_wwv];
    [self->initialLocationController startUpdatingLocation];

    // Install a double tap gesture recognizer to initiate location tracking mode.
    self->doubleTapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleDoubleTapFrom:)];
    [self->doubleTapGestureRecognizer setNumberOfTapsRequired:2];
    [_wwv addGestureRecognizer:self->doubleTapGestureRecognizer];

    // Set up to observe navigator gesture changes.
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleNotification:)
                                                 name:WW_NAVIGATOR_GESTURE_RECOGNIZED
                                               object:nil];
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
    CGFloat wwvHeight = self.view.bounds.size.height - _toolbar.bounds.size.height;
    CGFloat wwvOriginY = self.view.bounds.origin.y + _toolbar.bounds.size.height;

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
    _toolbar.frame = CGRectMake(0, 0, self.view.frame.size.width, 44);
    [_toolbar setAutoresizingMask:UIViewAutoresizingFlexibleWidth];
    [_toolbar setBarStyle:UIBarStyleBlack];
    [_toolbar setTranslucent:NO];

    [self.view addSubview:_toolbar];

    self->layerButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"LayerList"]
                                                         style:UIBarButtonItemStylePlain
                                                        target:self action:@selector(handleLayerButtonTap)];
    LayerListController* llc = [[LayerListController alloc] initWithWorldWindView:_wwv];
    self->layerListPopoverController = [[UIPopoverController alloc] initWithContentViewController:llc];

    UIBarButtonItem* trackButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"LocationArrow"]
                                                                    style:UIBarButtonItemStylePlain
                                                                   target:self action:nil];

    UISearchBar* searchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(0, 0, 200, 44)];
    UIBarButtonItem* searchBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:searchBar];

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
    [layerListPopoverController presentPopoverFromBarButtonItem:self->layerButton
                                       permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
}

- (void) handleDoubleTapFrom:(UITapGestureRecognizer*)recognizer
{
    // Stop the initial location controller if it's still running. We're starting a new location controller to
    // continuously track the device's current location, and have no need for the initial location if it's not already
    // resolved.
    if ([self->initialLocationController isUpdatingLocation])
    {
        [self->initialLocationController stopUpdatingLocation];
    }

    // Toggle the state of the repeating location controller in order to track the device's current location.
    if ([self->trackingLocationController isUpdatingLocation])
    {
        [self->trackingLocationController stopUpdatingLocation];
    }
    else
    {
        [self->trackingLocationController startUpdatingLocation];
    }
}

- (void) handleNotification:(NSNotification*)notification
{
    if ([[notification name] isEqualToString:WW_NAVIGATOR_GESTURE_RECOGNIZED])
    {
        if ([self->initialLocationController isUpdatingLocation])
        {
            [self->initialLocationController stopUpdatingLocation];
        }

        if ([self->trackingLocationController isUpdatingLocation])
        {
            [self->trackingLocationController stopUpdatingLocation];
        }
    }
}

@end