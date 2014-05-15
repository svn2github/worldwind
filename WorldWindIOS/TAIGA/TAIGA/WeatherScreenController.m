/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import "WeatherScreenController.h"
#import "AppConstants.h"
#import "WWRetriever.h"
#import "WorldWindConstants.h"

#define MOST_RECENTLY_USED_WEATHER_CHART_NAME (@"gov.nasa.worldwind.taiga.mostrecentlyusedweatherchartname")
#define DEFAULT_CHART_NAME @"Icing"

@implementation WeatherScreenController
{
    CGRect myFrame;
    NSString* cachePath;
    NSArray* charts;

    UIToolbar* topToolBar;
    UILabel* chartNameLabel;
    UIImageView* imageView;
}

- (id) initWithFrame:(CGRect)frame
{
    self = [super initWithNibName:nil bundle:nil];

    myFrame = frame;

    NSString* cacheDir = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    cachePath = [cacheDir stringByAppendingPathComponent:@"charts/weather"];
    NSError* error = nil;
    [[NSFileManager defaultManager] createDirectoryAtPath:cachePath
                              withIntermediateDirectories:YES attributes:nil error:&error];

    charts = [[NSArray alloc] initWithObjects:
            @"MVFR/IFR,http://aawu.arh.noaa.gov/fcstgraphics/ifr.gif",
            @"Icing,http://aawu.arh.noaa.gov/fcstgraphics/icing_summary.png",
            @"Surface,http://aawu.arh.noaa.gov/fcstgraphics/sfc.gif",
            @"Turbulence,http://aawu.arh.noaa.gov/fcstgraphics/turb_summary.png",
            @"Hazards,http://aawu.arh.noaa.gov/fcstgraphics/avhazard.gif",
            nil];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleRefreshNotification:)
                                                 name:TAIGA_REFRESH
                                               object:nil];

    return self;
}

- (void) loadView
{
    self.view = [[UIView alloc] initWithFrame:myFrame];
    self.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.view.autoresizesSubviews = YES;

    [self createTopToolbar];

    CGRect nameFrame = CGRectMake(0, TAIGA_TOOLBAR_HEIGHT, myFrame.size.width, 44);
    chartNameLabel = [[UILabel alloc] initWithFrame:nameFrame];
    chartNameLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    chartNameLabel.autoresizesSubviews = YES;
    [chartNameLabel setTextAlignment:NSTextAlignmentCenter];
    [chartNameLabel setFont:[UIFont boldSystemFontOfSize:[[chartNameLabel font] pointSize]]];
    [chartNameLabel setBackgroundColor:[UIColor whiteColor]];
    [chartNameLabel setTextColor:[UIColor blackColor]];
    [chartNameLabel setText:@"Chart Name"];
    [[self view] addSubview:chartNameLabel];


    imageView = [[UIImageView alloc] init];
    imageView.frame = CGRectMake(0, 0, myFrame.size.width, myFrame.size.height - (TAIGA_TOOLBAR_HEIGHT + 44));
    imageView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    imageView.autoresizesSubviews = YES;
    imageView.backgroundColor = [UIColor whiteColor];
    imageView.userInteractionEnabled = YES;
    imageView.contentMode = UIViewContentModeScaleAspectFit;

    UIScrollView* scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, TAIGA_TOOLBAR_HEIGHT + 44,
            myFrame.size.width,
            myFrame.size.height - (TAIGA_TOOLBAR_HEIGHT + 44))];
    scrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    scrollView.autoresizesSubviews = YES;
    [scrollView setMinimumZoomScale:1];
    [scrollView setMaximumZoomScale:4.0];
    [scrollView setDelegate:self];
    [scrollView setContentSize:[imageView frame].size];
    [scrollView setShowsHorizontalScrollIndicator:NO];
    [scrollView setShowsVerticalScrollIndicator:NO];
    [scrollView addSubview:imageView];

    [[self view] addSubview:scrollView];
}

- (UIView*) viewForZoomingInScrollView:(UIScrollView*)scrollView
{
    return imageView;
}

- (void) viewDidLoad
{
    [super viewDidLoad];

    [self loadMostRecentlyUsedChart];
}

- (void) createTopToolbar
{
    topToolBar = [[UIToolbar alloc] init];
    topToolBar.frame = CGRectMake(0, 0, self.view.frame.size.width, TAIGA_TOOLBAR_HEIGHT);
    [topToolBar setAutoresizingMask:UIViewAutoresizingFlexibleWidth];
    [topToolBar setBarStyle:UIBarStyleBlack];
    [topToolBar setTranslucent:NO];

    NSMutableArray* barItems = [[NSMutableArray alloc] initWithCapacity:5];

    UIBarButtonItem* flexibleSpace = [[UIBarButtonItem alloc]
            initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];

    [barItems addObject:flexibleSpace];

    for (NSString* chartInfo in charts)
    {
        NSString* name = [chartInfo componentsSeparatedByString:@","][0];

        UIBarButtonItem* button = [[UIBarButtonItem alloc] initWithTitle:name style:UIBarButtonItemStylePlain
                                                                  target:self
                                                                  action:@selector(handleChartSelection:)];
        [button setTintColor:[UIColor whiteColor]];

        [barItems addObject:button];
        [barItems addObject:flexibleSpace];
    }

    [topToolBar setItems:barItems];

    [self.view addSubview:topToolBar];
}

- (void) loadMostRecentlyUsedChart
{
    NSString* chartName = [[NSUserDefaults standardUserDefaults] objectForKey:MOST_RECENTLY_USED_WEATHER_CHART_NAME];
    if (chartName == nil)
        chartName = DEFAULT_CHART_NAME;

    [self selectChart:chartName];
}

- (void) handleChartSelection:(UIBarButtonItem*)button
{
    [self selectChart:[button title]];
}

- (void) selectChart:(NSString*)chartName
{
    NSString* chartURL;
    for (NSString* chartInfo in charts)
    {
        NSString* name = [chartInfo componentsSeparatedByString:@","][0];
        if ([name isEqualToString:chartName])
        {
            chartURL = [chartInfo componentsSeparatedByString:@","][1];
            break;
        }
    }

    if (chartURL == nil)
        return;

    NSURL* url = [[NSURL alloc] initWithString:chartURL];
    WWRetriever* retriever = [[WWRetriever alloc] initWithUrl:url timeout:5
                                                finishedBlock:^(WWRetriever* myRetriever)
                                                {
                                                    [self loadSelectedChart:myRetriever];
                                                }];
    [retriever setUserData:chartName];
    [retriever performRetrieval];
}

- (void) loadSelectedChart:(WWRetriever*)retriever
{
    if ([[retriever status] isEqualToString:WW_SUCCEEDED] && [[retriever retrievedData] length] > 0)
    {
        [self saveChart:retriever];

        NSString* chartFileName = [[retriever url] lastPathComponent];
        NSString* chartPath = [cachePath stringByAppendingPathComponent:chartFileName];

        [self loadChart:chartPath chartName:[retriever userData]];
    }

}

- (void) saveChart:(WWRetriever*)retriever
{
    NSString* chartFileName = [[retriever url] lastPathComponent];
    NSString* chartPath = [cachePath stringByAppendingPathComponent:chartFileName];

    [[retriever retrievedData] writeToFile:chartPath atomically:YES];
}

- (void) loadChart:(NSString*)chartPath chartName:(NSString*)chartName
{
    if ([[NSFileManager defaultManager] fileExistsAtPath:chartPath])
    {
        if (chartName == nil)
            chartName = @"";

        [imageView setImage:[UIImage imageWithContentsOfFile:chartPath]];
        [chartNameLabel setText:chartName];

        // Update the most recently used chart property.
        [[NSUserDefaults standardUserDefaults] setObject:chartName forKey:MOST_RECENTLY_USED_WEATHER_CHART_NAME];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
}

- (void) handleRefreshNotification:(NSNotification*)notification
{
    if ([[notification name] isEqualToString:TAIGA_REFRESH] && [notification object] == nil)
    {
        [self retrieveAllCharts];
    }
}

- (void) retrieveAllCharts
{
    @synchronized (_refreshInProgress)
    {
        if ([_refreshInProgress boolValue])
            return;

        _refreshInProgress = [[NSNumber alloc] initWithBool:YES];
    }

    for (NSString* chartInfo in charts)
    {
        NSString* chartName = [chartInfo componentsSeparatedByString:@","][0];
        NSString* chartURL = [chartInfo componentsSeparatedByString:@","][1];
        if (chartURL != nil)
        {
            NSURL* url = [[NSURL alloc] initWithString:chartURL];
            WWRetriever* retriever = [[WWRetriever alloc] initWithUrl:url timeout:5
                                                        finishedBlock:^(WWRetriever* myRetriever)
                                                        {
                                                            [self performSelectorOnMainThread:@selector(saveRefreshedChart:)
                                                                                   withObject:myRetriever
                                                                                waitUntilDone:NO];
                                                        }];
            [retriever setUserData:chartName];
            [retriever performRetrieval];
        }
    }

    _refreshInProgress = [[NSNumber alloc] initWithBool:NO];
}

- (void) saveRefreshedChart:(WWRetriever*)retriever
{
    if ([[retriever status] isEqualToString:WW_SUCCEEDED] && [[retriever retrievedData] length] > 0)
    {
        [self saveChart:retriever];

        NSString* chartName = [retriever userData];
        if (chartNameLabel != nil && [[chartNameLabel text] isEqualToString:chartName])
        {
            NSString* chartFileName = [[retriever url] lastPathComponent];
            NSString* chartPath = [cachePath stringByAppendingPathComponent:chartFileName];

            [self loadChart:chartPath chartName:[retriever userData]];
        }
    }

}

@end