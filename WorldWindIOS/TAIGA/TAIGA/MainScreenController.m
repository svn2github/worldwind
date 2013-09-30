/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import "MainScreenController.h"
#import "MovingMapViewController.h"
#import "AppConstants.h"
#import "WeatherScreenController.h"
#import "ChartsScreenController.h"
#import "SettingsScreenController.h"
#import "ButtonWithImageAndText.h"
#import "TAIGA.h"
#import "AppUpdateController.h"

#define VIEW_TAG (100)

@implementation MainScreenController
{
    UIToolbar* modeBar;
    UIBarButtonItem* movingMapButton;
    UIBarButtonItem* weatherButton;
    UIBarButtonItem* chartsButton;
    UIBarButtonItem* settingsButton;

    MovingMapViewController* movingMapScreenController;
    WeatherScreenController* weatherScreenController;
    ChartsScreenController* chartsScreenController;
    SettingsScreenController* settingsScreenController;
}

- (id) init
{
    self = [super initWithNibName:nil bundle:nil];

    return self;
}

- (void) loadView
{
    self.view = [[UIView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.view.autoresizesSubviews = YES;

    [self createModeBar];

    CGRect frame = [self.view frame];
    frame.origin.x = 0;
    frame.origin.y = 20;
    frame.size.height -= TAIGA_TOOLBAR_HEIGHT + 20;

    movingMapScreenController = [[MovingMapViewController alloc] initWithFrame:frame];
    [[movingMapScreenController view] setTag:VIEW_TAG];

    weatherScreenController = [[WeatherScreenController alloc] initWithFrame:frame];
    [[weatherScreenController view] setTag:VIEW_TAG];

    chartsScreenController = [[ChartsScreenController alloc] initWithFrame:frame];
    [[chartsScreenController view] setTag:VIEW_TAG];

    settingsScreenController = [[SettingsScreenController alloc] initWithFrame:frame];
    [[settingsScreenController view] setTag:VIEW_TAG];

    [self.view addSubview:[movingMapScreenController view]];
    [((ButtonWithImageAndText*) [movingMapButton customView]) highlight:YES];
}


- (void) viewDidLoad
{
    [super viewDidLoad];

    [self setNeedsStatusBarAppearanceUpdate];

    [[TAIGA appUpdateController] checkForUpdate:YES];
}

- (UIStatusBarStyle) preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}

- (void) createModeBar
{
    modeBar = [[UIToolbar alloc] init];
    modeBar.frame = CGRectMake(0, self.view.frame.size.height - TAIGA_TOOLBAR_HEIGHT, self.view.frame.size.width, TAIGA_TOOLBAR_HEIGHT);
    [modeBar setAutoresizingMask:UIViewAutoresizingFlexibleWidth];
    [modeBar setBarStyle:UIBarStyleBlack];
    [modeBar setTranslucent:NO];

    CGSize size = CGSizeMake(130, TAIGA_TOOLBAR_HEIGHT);

    movingMapButton = [[UIBarButtonItem alloc] initWithCustomView:[[ButtonWithImageAndText alloc]
            initWithImageName:@"401-globe" text:@"Moving Map" size:size target:self action:@selector
            (handleMovingMap)]];
    UIColor* color = [[UIColor alloc] initWithRed:1.0 green:242./255. blue:183./255. alpha:1.0];
    [((ButtonWithImageAndText*) [movingMapButton customView]) setTextColor:color];

    weatherButton = [[UIBarButtonItem alloc] initWithCustomView:[[ButtonWithImageAndText alloc]
            initWithImageName:@"25-weather" text:@"Weather" size:size target:self action:@selector
            (handleWeather)]];
     color = [[UIColor alloc] initWithRed:1.0 green:208./255. blue:237./255. alpha:1.0];
    [((ButtonWithImageAndText*) [weatherButton customView]) setTextColor:color];

    chartsButton = [[UIBarButtonItem alloc] initWithCustomView:[[ButtonWithImageAndText alloc]
            initWithImageName:@"361-1up" text:@"Charts" size:size target:self action:@selector
            (handleCharts)]];
    color = [[UIColor alloc] initWithRed:182./255. green:255./255. blue:190./255. alpha:1.0];
    [((ButtonWithImageAndText*) [chartsButton customView]) setTextColor:color];

    settingsButton = [[UIBarButtonItem alloc] initWithCustomView:[[ButtonWithImageAndText alloc]
            initWithImageName:@"19-gear" text:@"Settings" size:size target:self action:@selector
            (handleSettings)]];

    UIBarButtonItem* flexibleSpace = [[UIBarButtonItem alloc]
            initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];

    [modeBar setItems:[NSArray arrayWithObjects:
            flexibleSpace,
            movingMapButton,
            flexibleSpace,
            weatherButton,
            flexibleSpace,
            chartsButton,
            flexibleSpace,
            settingsButton,
            flexibleSpace,
            nil]];

    [modeBar setAutoresizingMask:UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin];
    [self.view addSubview:modeBar];
}

- (void) handleMovingMap
{
    [self swapScreenController:movingMapScreenController button:movingMapButton];
}

- (void) handleWeather
{
    [self swapScreenController:weatherScreenController button:weatherButton];
}

- (void) handleCharts
{
    [self swapScreenController:chartsScreenController button:chartsButton];
}

- (void) handleSettings
{
    [self swapScreenController:settingsScreenController button:settingsButton];
}

- (void) swapScreenController:(UIViewController*)screenController button:(UIBarButtonItem*)button
{
    CGRect frame = [[screenController view] frame];

    for (UIView* subview in self.view.subviews)
    {
        if (subview.tag == VIEW_TAG)
        {
            frame = subview.frame;
            [subview removeFromSuperview];
            break;
        }
    }

    [[screenController view] setFrame:frame];
    [self.view addSubview:[screenController view]];

    [((ButtonWithImageAndText*) [movingMapButton customView]) highlight:NO];
    [((ButtonWithImageAndText*) [weatherButton customView]) highlight:NO];
    [((ButtonWithImageAndText*) [chartsButton customView]) highlight:NO];
    [((ButtonWithImageAndText*) [settingsButton customView]) highlight:NO];

    [((ButtonWithImageAndText*) [button customView]) highlight:YES];
}
@end