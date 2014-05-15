/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import "ChartsTableController.h"
#import "ChartsListController.h"


@implementation ChartsTableController
{
    UISearchBar* chartSearchBar;
    ChartsListController* chartsListController;
}

- (ChartsTableController*) initWithParent:(id)parent
{
    self = [super init];

    [[self navigationItem] setTitle:@"Charts"];

    chartSearchBar = [[UISearchBar alloc] init];
    [chartSearchBar setDelegate:self];
    [chartSearchBar setPlaceholder:@"Chart name"];

    chartsListController = [[ChartsListController alloc] initWithParent:parent];

    return self;
}

- (void) loadView
{
    self.view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 1, 1)];
    self.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.view.autoresizesSubviews = YES;

    [[self view] addSubview:chartSearchBar];
    [[self view] addSubview:[chartsListController view]];
    [self addChildViewController:chartsListController];

    [chartSearchBar setTranslatesAutoresizingMaskIntoConstraints:NO];
    [[chartsListController view] setTranslatesAutoresizingMaskIntoConstraints:NO];

    UIView* view = [self view];
    UIView* chartView = [chartsListController view];
    NSDictionary* viewsDictionary = NSDictionaryOfVariableBindings(view, chartView, chartSearchBar);

    [view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[chartSearchBar]|"
                                                                 options:0 metrics:nil views:viewsDictionary]];
    [view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[chartView]|"
                                                                 options:0 metrics:nil views:viewsDictionary]];
    [view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[chartSearchBar][chartView]|"
                                                                 options:0 metrics:nil views:viewsDictionary]];

    [self setEdgesForExtendedLayout:UIRectEdgeNone];
}

- (void) selectChart:(NSString*)chartFileName chartName:(NSString*)chartName
{
    [chartsListController selectChart:chartFileName chartName:chartName];
}

- (void) searchBar:(UISearchBar*)bar textDidChange:(NSString*)searchText
{
    [chartsListController setFilter:searchText];
}

- (void) searchBarSearchButtonClicked:(UISearchBar*)bar
{
    [chartsListController setFilter:[bar text]];
}

- (void) refreshAll
{
    [chartsListController refreshAll];
}

@end