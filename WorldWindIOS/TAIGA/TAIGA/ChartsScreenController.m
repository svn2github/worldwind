/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import "ChartsScreenController.h"
#import "AppConstants.h"
#import "ChartsListController.h"
#import "WWUtil.h"
#import "ChartViewController.h"
#import "ButtonWithImageAndText.h"

#define SEARCH_BAR_HEIGHT (80)
#define MOST_RECENTLY_USED_CHART_FILE_NAME (@"gov.nasa.worldwind.taiga.mostrecentlyusedchartfilename")
#define MOST_RECENTLY_USED_CHART_NAME (@"gov.nasa.worldwind.taiga.mostrecentlyusedchartname")

@implementation ChartsScreenController
{
    CGRect myFrame;

    UIToolbar* topToolBar;
    UIBarButtonItem* connectivityButton;
    UIBarButtonItem* refreshButton;
    UIBarButtonItem* bookmarksButton;

    UISearchBar* searchBar;
    ChartsListController* chartsListController;
    UIButton* recentViewsButton;
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
    [self createSearchBar];

    chartsListController = [[ChartsListController alloc] initWithParent:self];
    CGRect listFrame = CGRectMake(0, TAIGA_TOOLBAR_HEIGHT + SEARCH_BAR_HEIGHT, 0.35 * myFrame.size.width,
            myFrame.size.height - (TAIGA_TOOLBAR_HEIGHT + SEARCH_BAR_HEIGHT));
    [[chartsListController view] setFrame:listFrame];
    [self addChildViewController:chartsListController];
    [[self view] addSubview:[chartsListController view]];

    CGRect viewFrame = CGRectMake(0.35 * myFrame.size.width, TAIGA_TOOLBAR_HEIGHT + SEARCH_BAR_HEIGHT,
            0.66 * myFrame.size.width, myFrame.size.height - (TAIGA_TOOLBAR_HEIGHT + SEARCH_BAR_HEIGHT));
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

    CGSize size = CGSizeMake(140, TAIGA_TOOLBAR_HEIGHT);

    connectivityButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"275-broadcast"]
                                                          style:UIBarButtonItemStylePlain
                                                         target:nil
                                                         action:nil];
    [connectivityButton setTintColor:[UIColor whiteColor]];

    refreshButton = [[UIBarButtonItem alloc] initWithCustomView:[[ButtonWithImageAndText alloc]
            initWithImageName:@"01-refresh" text:@"Refresh" size:size target:self action:@selector
            (handleButtonTap)]];
    UIColor* color = [[UIColor alloc] initWithRed:1.0 green:242. / 255. blue:183. / 255. alpha:1.0];
    [((ButtonWithImageAndText*) [refreshButton customView]) setTextColor:color];
    [((ButtonWithImageAndText*) [refreshButton customView]) setFontSize:15];

    bookmarksButton = [[UIBarButtonItem alloc] initWithCustomView:[[ButtonWithImageAndText alloc]
            initWithImageName:@"387-bookmarks" text:@"Bookmarks" size:size target:self action:@selector
            (handleButtonTap)]];
    color = [[UIColor alloc] initWithRed:1.0 green:242. / 255. blue:183. / 255. alpha:1.0];
    [((ButtonWithImageAndText*) [bookmarksButton customView]) setTextColor:color];
    [((ButtonWithImageAndText*) [bookmarksButton customView]) setFontSize:15];

    UIBarButtonItem* flexibleSpace = [[UIBarButtonItem alloc]
            initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];

    [topToolBar setItems:[NSArray arrayWithObjects:
            flexibleSpace,
            refreshButton,
            flexibleSpace,
            bookmarksButton,
            flexibleSpace,
            connectivityButton,
            nil]];

    [self.view addSubview:topToolBar];
}

- (void) createSearchBar
{
    UIView* sbView = [[UIView alloc] initWithFrame:CGRectMake(0, TAIGA_TOOLBAR_HEIGHT, myFrame.size.width,
            SEARCH_BAR_HEIGHT)];
    sbView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleBottomMargin;
    sbView.autoresizesSubviews = YES;
    [sbView setBackgroundColor:[UIColor whiteColor]];

    searchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(0, 0, myFrame.size.width, SEARCH_BAR_HEIGHT / 2)];
    searchBar.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    searchBar.autoresizesSubviews = YES;
    [sbView addSubview:searchBar];

    CGRect frame = CGRectMake(0, SEARCH_BAR_HEIGHT / 2, 0.35 * myFrame.size.width, SEARCH_BAR_HEIGHT / 2);
    recentViewsButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [recentViewsButton setFrame:frame];
    recentViewsButton.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    recentViewsButton.autoresizesSubviews = YES;
    [recentViewsButton setTitle:@"Recent Views" forState:UIControlStateNormal];
    [recentViewsButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [sbView addSubview:recentViewsButton];

    frame = CGRectMake([recentViewsButton frame].size.width, SEARCH_BAR_HEIGHT / 2, 0.65 * myFrame.size.width,
            SEARCH_BAR_HEIGHT / 2);
    chartNameLabel = [[UILabel alloc] initWithFrame:frame];
    chartNameLabel.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
    chartNameLabel.autoresizesSubviews = YES;
    [chartNameLabel setText:nil];
    [chartNameLabel setTextAlignment:NSTextAlignmentCenter];
    [chartNameLabel setFont:[UIFont boldSystemFontOfSize:[[chartNameLabel font] pointSize]]];
    [sbView addSubview:chartNameLabel];

    [self.view addSubview:sbView];
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