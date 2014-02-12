/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import "ChartsScreenController.h"
#import "AppConstants.h"
#import "WWUtil.h"
#import "ChartViewController.h"
#import "ButtonWithImageAndText.h"
#import "ChartsTableController.h"

#define MOST_RECENTLY_USED_CHART_FILE_NAME (@"gov.nasa.worldwind.taiga.mostrecentlyusedchartfilename")
#define MOST_RECENTLY_USED_CHART_NAME (@"gov.nasa.worldwind.taiga.mostrecentlyusedchartname")

@implementation ChartsScreenController
{
    CGRect myFrame;

    UIToolbar* topToolBar;
    UIBarButtonItem* connectivityButton;

    ChartsTableController* chartsListController;
    UILabel* chartNameLabel;
    ChartViewController* chartViewController;
}

- (ChartsScreenController*) initWithFrame:(CGRect)frame
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

    [self createTopToolbar];

    chartsListController = [[ChartsTableController alloc] initWithParent:self];
    CGRect listFrame = CGRectMake(0, TAIGA_TOOLBAR_HEIGHT, 0.35 * myFrame.size.width,
            myFrame.size.height - (TAIGA_TOOLBAR_HEIGHT));
    [[chartsListController view] setFrame:listFrame];
    [self addChildViewController:chartsListController];
    [[self view] addSubview:[chartsListController view]];

    CGRect nameFrame = CGRectMake(0.35 * myFrame.size.width, TAIGA_TOOLBAR_HEIGHT,
            0.66 * myFrame.size.width, 44);
    chartNameLabel = [[UILabel alloc] initWithFrame:nameFrame];
    chartNameLabel.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
    chartNameLabel.autoresizesSubviews = YES;
    [chartNameLabel setTextAlignment:NSTextAlignmentCenter];
    [chartNameLabel setFont:[UIFont boldSystemFontOfSize:[[chartNameLabel font] pointSize]]];
    [chartNameLabel setBackgroundColor:[UIColor whiteColor]];
    [chartNameLabel setTextColor:[UIColor blackColor]];
    [[self view] addSubview:chartNameLabel];

    CGRect viewFrame = CGRectMake(0.35 * myFrame.size.width, TAIGA_TOOLBAR_HEIGHT + 44,
            0.66 * myFrame.size.width, myFrame.size.height - (TAIGA_TOOLBAR_HEIGHT + 44));
    chartViewController = [[ChartViewController alloc] initWithFrame:viewFrame];
    [self addChildViewController:chartViewController];
    [[self view] addSubview:[chartViewController view]];
}

- (void) viewDidLoad
{
    [self loadMostRecentlyUsedChart];
}

- (void) createTopToolbar
{
    topToolBar = [[UIToolbar alloc] init];
    topToolBar.frame = CGRectMake(0, 0, self.view.frame.size.width, TAIGA_TOOLBAR_HEIGHT);
    [topToolBar setAutoresizingMask:UIViewAutoresizingFlexibleWidth];
    [topToolBar setBarStyle:UIBarStyleBlack];
    [topToolBar setTranslucent:NO];

    connectivityButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"275-broadcast"]
                                                          style:UIBarButtonItemStylePlain
                                                         target:nil
                                                         action:nil];
    [connectivityButton setTintColor:[UIColor whiteColor]];

    UIBarButtonItem* flexibleSpace = [[UIBarButtonItem alloc]
            initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];

    [topToolBar setItems:[NSArray arrayWithObjects:
            flexibleSpace,
            connectivityButton,
            nil]];

    [self.view addSubview:topToolBar];
}

- (void) handleButtonTap
{
    NSLog(@"BUTTON TAPPED");
}

- (void) loadChart:(NSString*)chartPath chartName:(NSString*)chartName
{
    if ([[NSFileManager defaultManager] fileExistsAtPath:chartPath])
    {
        if (chartName == nil)
            chartName = @"";

        [[chartViewController imageView] setImage:[WWUtil convertPDFToUIImage:[[NSURL alloc] initFileURLWithPath:chartPath]]];
        [chartNameLabel setText:chartName];

        // Update the most recently used chart property.
        [[NSUserDefaults standardUserDefaults] setObject:[chartPath lastPathComponent] forKey:MOST_RECENTLY_USED_CHART_FILE_NAME];
        [[NSUserDefaults standardUserDefaults] setObject:chartName forKey:MOST_RECENTLY_USED_CHART_NAME];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
}


- (void) loadMostRecentlyUsedChart
{
    NSString* chartFileName = [[NSUserDefaults standardUserDefaults] objectForKey:MOST_RECENTLY_USED_CHART_FILE_NAME];
    if (chartFileName == nil)
        return;

    NSString* chartName = [[NSUserDefaults standardUserDefaults] objectForKey:MOST_RECENTLY_USED_CHART_NAME];

    [chartsListController selectChart:chartFileName chartName:chartName];
}

@end