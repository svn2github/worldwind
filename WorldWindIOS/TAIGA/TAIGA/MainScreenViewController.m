/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id: AppDelegate.m 1170 2013-02-11 19:05:20Z tgaskins $
 */

#import "MainScreenViewController.h"
#import "WorldWind/WorldWind.h"
#import "WorldWind/WorldWindView.h"
#import "WWLayerList.h"
#import "WWSceneController.h"
#import "WWBMNGLandsatCombinedLayer.h"
#import "ButtonWithImageAndText.h"

#define TOOLBAR_HEIGHT 80

@interface MainScreenViewController ()

@end

@implementation MainScreenViewController
{
    UIToolbar* screen1TopToolbar;
    UIBarButtonItem* screen1TopButton1;
    UIBarButtonItem* screen1TopButton2;
    UIBarButtonItem* screen1TopButton3;
    UIBarButtonItem* screen1TopButton4;
    UIBarButtonItem* screen1TopButton5;
    UIBarButtonItem* screen1TopButton6;
    UIBarButtonItem* screen1TopButton7;
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
    [((UINavigationController*) [self parentViewController]) setNavigationBarHidden:YES animated:YES];
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
    screen1TopToolbar = [[UIToolbar alloc] init];
    screen1TopToolbar.frame = CGRectMake(0, 0, self.view.frame.size.width, TOOLBAR_HEIGHT);
    [screen1TopToolbar setAutoresizingMask:UIViewAutoresizingFlexibleWidth];
    [screen1TopToolbar setBarStyle:UIBarStyleBlack];
    [screen1TopToolbar setTranslucent:NO];

    CGSize size = CGSizeMake(100, TOOLBAR_HEIGHT);

    screen1TopButton1 = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"275-broadcast"]
                                                         style:UIBarButtonItemStylePlain
                                                        target:nil
                                                        action:nil];

    screen1TopButton2 = [[UIBarButtonItem alloc] initWithCustomView:[[ButtonWithImageAndText alloc]
            initWithImageName:@"122-stats" text:@"Flight Paths" size:size target:self action:@selector
            (handleScreen1ButtonTap)]];
    screen1TopButton3 = [[UIBarButtonItem alloc] initWithCustomView:[[ButtonWithImageAndText alloc]
            initWithImageName:@"25-weather" text:@"Weather" size:size target:self action:@selector
            (handleScreen1ButtonTap)]];
    screen1TopButton4 = [[UIBarButtonItem alloc] initWithCustomView:[[ButtonWithImageAndText alloc]
            initWithImageName:@"385-mountain" text:@"Terrain" size:size target:self action:@selector
            (handleScreen1ButtonTap)]];
    screen1TopButton5 = [[UIBarButtonItem alloc] initWithCustomView:[[ButtonWithImageAndText alloc]
            initWithImageName:@"362-2up" text:@"Split View" size:size target:self action:@selector
            (handleScreen1ButtonTap)]];
    screen1TopButton6 = [[UIBarButtonItem alloc] initWithCustomView:[[ButtonWithImageAndText alloc]
            initWithImageName:@"42-photos" text:@"Quick Views" size:size target:self action:@selector
            (handleScreen1ButtonTap)]];
    screen1TopButton7 = [[UIBarButtonItem alloc] initWithCustomView:[[ButtonWithImageAndText alloc]
            initWithImageName:@"09-chat-2" text:@"More" size:size target:self action:@selector
            (handleScreen1ButtonTap)]];


    UIBarButtonItem* flexibleSpace = [[UIBarButtonItem alloc]
            initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];

    [screen1TopToolbar setItems:[NSArray arrayWithObjects:
            screen1TopButton1,
            flexibleSpace,
            screen1TopButton2,
            flexibleSpace,
            screen1TopButton3,
            flexibleSpace,
            screen1TopButton4,
            flexibleSpace,
            screen1TopButton5,
            flexibleSpace,
            screen1TopButton6,
            flexibleSpace,
            screen1TopButton7,
            nil]];

    [self.view addSubview:screen1TopToolbar];
}

- (void) handleScreen1ButtonTap
{
    NSLog(@"BUTTON TAPPED");
}

@end
