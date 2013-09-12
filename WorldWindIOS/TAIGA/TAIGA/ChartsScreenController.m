/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import "ChartsScreenController.h"
#import "AppConstants.h"
#import "ChartsListController.h"
#import "WWUtil.h"

#define SEARCH_BAR_HEIGHT (80)

@implementation ChartsScreenController
{
    CGRect myFrame;

    UIToolbar* topToolBar;
    UIBarButtonItem* connectivityButton;
    UIBarButtonItem* button1;
    UIBarButtonItem* button2;
    UIBarButtonItem* button3;
    UIBarButtonItem* button4;
    UIBarButtonItem* button5;

    UISearchBar* searchBar;
    ChartsListController* chartsListController;
    UIButton* recentViewsButton;
    UILabel* chartNameLabel;
    UIImageView* chartView;
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

    chartsListController = [[ChartsListController alloc] init];
    [[chartsListController view] setFrame:
            CGRectMake(0, TAIGA_TOOLBAR_HEIGHT + SEARCH_BAR_HEIGHT, 0.35 * myFrame.size.width,
                    myFrame.size.height - (TAIGA_TOOLBAR_HEIGHT + SEARCH_BAR_HEIGHT))];
    [self addChildViewController:chartsListController];
    [[self view] addSubview:[chartsListController view]];

    NSString* imagePath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"PAJN.pdf"];
    NSURL* imageURL = [[NSURL alloc] initFileURLWithPath:imagePath];

    chartView = [[UIImageView alloc] initWithImage:[WWUtil convertPDFToUIImage:imageURL]];
    [chartView setFrame:
            CGRectMake(0.35 * myFrame.size.width, TAIGA_TOOLBAR_HEIGHT + SEARCH_BAR_HEIGHT, 0.65 * myFrame.size.width,
                    myFrame.size.height - (TAIGA_TOOLBAR_HEIGHT + SEARCH_BAR_HEIGHT))];
    chartView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleHeight;
    chartView.autoresizesSubviews = YES;
    [chartView setBackgroundColor:[UIColor whiteColor]];
    [[self view] addSubview:chartView];
}

- (void) viewDidLoad
{
    [super viewDidLoad];
}

- (void) createTopToolbar
{
    topToolBar = [[UIToolbar alloc] init];
    topToolBar.frame = CGRectMake(0, 0, self.view.frame.size.width, TAIGA_TOOLBAR_HEIGHT);
    [topToolBar setAutoresizingMask:UIViewAutoresizingFlexibleWidth];
    [topToolBar setBarStyle:UIBarStyleBlack];
    [topToolBar setTranslucent:NO];

    NSDictionary* textAttrs = [[NSDictionary alloc] initWithObjectsAndKeys:
            [UIFont boldSystemFontOfSize:18], UITextAttributeFont, nil];

    connectivityButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"275-broadcast"]
                                                          style:UIBarButtonItemStylePlain
                                                         target:nil
                                                         action:nil];

    button1 = [[UIBarButtonItem alloc] initWithTitle:@"Download" style:UIBarButtonItemStylePlain
                                              target:self
                                              action:@selector(handleButtonTap)];
    [button1 setTitleTextAttributes:textAttrs forState:UIControlStateNormal];

    button2 = [[UIBarButtonItem alloc] initWithTitle:@"Refresh" style:UIBarButtonItemStylePlain
                                              target:self
                                              action:@selector(handleButtonTap)];
    [button2 setTitleTextAttributes:textAttrs forState:UIControlStateNormal];

    button3 = [[UIBarButtonItem alloc] initWithTitle:@"Bookmarks" style:UIBarButtonItemStylePlain
                                              target:self
                                              action:@selector(handleButtonTap)];
    [button3 setTitleTextAttributes:textAttrs forState:UIControlStateNormal];

    button4 = [[UIBarButtonItem alloc] initWithTitle:@"Pen" style:UIBarButtonItemStylePlain
                                              target:self
                                              action:@selector(handleButtonTap)];
    [button4 setTitleTextAttributes:textAttrs forState:UIControlStateNormal];

    button5 = [[UIBarButtonItem alloc] initWithTitle:@"Clear Drawing" style:UIBarButtonItemStylePlain
                                              target:self
                                              action:@selector(handleButtonTap)];
    [button5 setTitleTextAttributes:textAttrs forState:UIControlStateNormal];

    UIBarButtonItem* flexibleSpace = [[UIBarButtonItem alloc]
            initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];

    [topToolBar setItems:[NSArray arrayWithObjects:
            flexibleSpace,
            button1,
            flexibleSpace,
            button2,
            flexibleSpace,
            button3,
            flexibleSpace,
            button4,
            flexibleSpace,
            button5,
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
    [chartNameLabel setText:@"Chart Name"];
    [chartNameLabel setTextAlignment:NSTextAlignmentCenter];
    [chartNameLabel setFont:[UIFont boldSystemFontOfSize:[[chartNameLabel font] pointSize]]];
    [sbView addSubview:chartNameLabel];

    [self.view addSubview:sbView];
}

- (void) handleButtonTap
{
    NSLog(@"BUTTON TAPPED");
}
@end