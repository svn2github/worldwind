/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import <Foundation/Foundation.h>

/**
* A view controller for a Web view.
*/
@interface WebViewController : UIViewController <UIWebViewDelegate>

/// The controller's web view.
@property(nonatomic, readonly) UIWebView* webView;

/**
* Initializes the web view controller.
*
* @param frame The size to make the web view.
*/
- (WebViewController*)initWithFrame:(CGRect)frame;

@end