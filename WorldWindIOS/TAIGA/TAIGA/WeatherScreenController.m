/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import "WeatherScreenController.h"
#import "AppConstants.h"

@implementation WeatherScreenController
{
    CGRect myFrame;

    UIToolbar* topToolBar;
    UIBarButtonItem* connectivityButton;
    UIBarButtonItem* button1;
    UIBarButtonItem* button2;
    UIBarButtonItem* button3;
    UIBarButtonItem* button4;
}

- (id) initWithFrame:(CGRect)frame
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
}

- (void) viewDidLoad
{
    [super viewDidLoad];

    [self.view setBackgroundColor:[UIColor greenColor]];
}
@end