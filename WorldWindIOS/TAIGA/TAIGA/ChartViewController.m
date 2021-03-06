/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import "ChartViewController.h"


@implementation ChartViewController
{
    CGRect myFrame;
}

- (ChartViewController*) initWithFrame:(CGRect)frame
{
    self = [super init];

    myFrame = frame;

    [[self view] setFrame:myFrame];

    _imageView = [[UIImageView alloc] init];
    _imageView.frame = CGRectMake(0, 0, myFrame.size.width, myFrame.size.height);
    _imageView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleHeight;
    _imageView.autoresizesSubviews = YES;
    _imageView.backgroundColor = [UIColor whiteColor];
    _imageView.userInteractionEnabled = YES;
    _imageView.contentMode = UIViewContentModeScaleAspectFit;

    UIScrollView* scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, myFrame.size.width, myFrame.size.height)];
    scrollView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleHeight;
    scrollView.autoresizesSubviews = YES;
    [scrollView setMinimumZoomScale:1];
    [scrollView setMaximumZoomScale:4.0];
    [scrollView setDelegate:self];
    [scrollView setContentSize:[_imageView frame].size];
    [scrollView setShowsHorizontalScrollIndicator:NO];
    [scrollView setShowsVerticalScrollIndicator:NO];
    [scrollView setBackgroundColor:[UIColor darkGrayColor]];
    [scrollView addSubview:_imageView];

    [[self view] addSubview:scrollView];

    return self;
}

- (UIView*) viewForZoomingInScrollView:(UIScrollView*)scrollView
{
    return _imageView;
}

@end