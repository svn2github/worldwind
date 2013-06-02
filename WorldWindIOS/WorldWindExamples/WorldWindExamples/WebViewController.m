/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import "WebViewController.h"

@implementation WebViewController

- (WebViewController*) initWithFrame:(CGRect)frame
{
    self = [super init];

    [self setContentSizeForViewInPopover:frame.size];

    _webView = [[UIWebView alloc] initWithFrame:frame];

    [_webView setDelegate:self];

    return self;
}

- (void) viewDidLoad
{
    [super viewDidLoad];

    [[self view] addSubview:_webView];
}

- (BOOL)           webView:(UIWebView*)webView
shouldStartLoadWithRequest:(NSURLRequest*)request
            navigationType:(UIWebViewNavigationType)navigationType
{
    if (navigationType == UIWebViewNavigationTypeLinkClicked)
    {
        [[UIApplication sharedApplication] openURL:[request URL]];
        return NO;
    }

    return YES;
}

@end