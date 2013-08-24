/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id: AppDelegate.m 1170 2013-02-11 19:05:20Z tgaskins $
 */

#import "MainScreenViewController.h"
#import "WorldWind.h"
#import "WorldWindView.h"
#import "WWLayerList.h"
#import "WWSceneController.h"
#import "WWBMNGLandsatCombinedLayer.h"
#import "ButtonWithImageAndText.h"

#define TOOLBAR_HEIGHT (80)
#define TOP_BUTTON_WIDTH (100)

@implementation MainScreenViewController
{
    UIToolbar* topToolBar;
    UIBarButtonItem* connectivityButton;
    UIBarButtonItem* flightPathsButton;
    UIBarButtonItem* weatherButton;
    UIBarButtonItem* terrainButton;
    UIBarButtonItem* splitViewButton;
    UIBarButtonItem* quickViewsButton;
//    UIBarButtonItem* moreButton;
}

- (id) init
{
    self = [super initWithNibName:nil bundle:nil];

    return self;
}

- (void) loadView
{
    self.view = [[UIView alloc] initWithFrame:[[UIScreen mainScreen] applicationFrame]];
    self.view.autoresizesSubviews = YES;

    [self createWorldWindView];
    [self createScreen1TopToolbar];
}


- (void) viewDidLoad
{
    [super viewDidLoad];

    WWLog(@"View Did Load. World Wind iOS Version %@", WW_VERSION);

    WWLayerList* layers = [[_wwv sceneController] layers];

    WWLayer* layer = [[WWBMNGLandsatCombinedLayer alloc] init];
    [layers addLayer:layer];
}

- (void) viewWillAppear:(BOOL)animated
{
//    [((UINavigationController*) [self parentViewController]) setNavigationBarHidden:YES animated:YES];
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

- (void) createScreen1TopToolbar
{
    topToolBar = [[UIToolbar alloc] init];
    topToolBar.frame = CGRectMake(0, 0, self.view.frame.size.width, TOOLBAR_HEIGHT);
    [topToolBar setAutoresizingMask:UIViewAutoresizingFlexibleWidth];
    [topToolBar setBarStyle:UIBarStyleBlack];
    [topToolBar setTranslucent:NO];

    CGSize size = CGSizeMake(TOP_BUTTON_WIDTH, TOOLBAR_HEIGHT);

    connectivityButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"275-broadcast"]
                                                          style:UIBarButtonItemStylePlain
                                                         target:nil
                                                         action:nil];

    flightPathsButton = [[UIBarButtonItem alloc] initWithCustomView:[[ButtonWithImageAndText alloc]
            initWithImageName:@"122-stats" text:@"Flight Paths" size:size target:self action:@selector
            (handleScreen1ButtonTap)]];
    weatherButton = [[UIBarButtonItem alloc] initWithCustomView:[[ButtonWithImageAndText alloc]
            initWithImageName:@"25-weather" text:@"Weather" size:size target:self action:@selector
            (handleScreen1ButtonTap)]];
    terrainButton = [[UIBarButtonItem alloc] initWithCustomView:[[ButtonWithImageAndText alloc]
            initWithImageName:@"385-mountain" text:@"Terrain" size:size target:self action:@selector
            (handleScreen1ButtonTap)]];
    splitViewButton = [[UIBarButtonItem alloc] initWithCustomView:[[ButtonWithImageAndText alloc]
            initWithImageName:@"362-2up" text:@"Split View" size:size target:self action:@selector
            (handleScreen1ButtonTap)]];
    quickViewsButton = [[UIBarButtonItem alloc] initWithCustomView:[[ButtonWithImageAndText alloc]
            initWithImageName:@"42-photos" text:@"Quick Views" size:size target:self action:@selector
            (handleScreen1ButtonTap)]];
//    moreButton = [[UIBarButtonItem alloc] initWithCustomView:[[ButtonWithImageAndText alloc]
//            initWithImageName:@"09-chat-2" text:@"More" size:size target:self action:@selector
//            (handleScreen1ButtonTap)]];


    UIBarButtonItem* flexibleSpace = [[UIBarButtonItem alloc]
            initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];

    [topToolBar setItems:[NSArray arrayWithObjects:
            connectivityButton,
            flexibleSpace,
            flightPathsButton,
            flexibleSpace,
            weatherButton,
            flexibleSpace,
            terrainButton,
            flexibleSpace,
            splitViewButton,
            flexibleSpace,
            quickViewsButton,
//            flexibleSpace,
//            moreButton,
            nil]];

    [self.view addSubview:topToolBar];
}

- (void) handleScreen1ButtonTap
{
    NSLog(@"BUTTON TAPPED");
}

@end
