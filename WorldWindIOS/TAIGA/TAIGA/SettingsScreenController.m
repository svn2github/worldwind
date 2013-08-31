/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import "SettingsScreenController.h"
#import "AppConstants.h"

@implementation SettingsScreenController
{
    CGRect myFrame;

    UIToolbar* topToolBar;
    UIBarButtonItem* connectivityButton;
    UIBarButtonItem* button1;
    UIBarButtonItem* button2;
    UIBarButtonItem* button3;
    UIBarButtonItem* button4;
}

- (SettingsScreenController*) initWithFrame:(CGRect)frame
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
}

- (void) viewDidLoad
{
    [super viewDidLoad];

    [self.view setBackgroundColor:[UIColor lightGrayColor]];
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

    button1 = [[UIBarButtonItem alloc] initWithTitle:@"Button 1" style:UIBarButtonItemStylePlain
                                              target:self
                                              action:@selector(handleButtonTap)];
    [button1 setTitleTextAttributes:textAttrs forState:UIControlStateNormal];

    button2 = [[UIBarButtonItem alloc] initWithTitle:@"Button 2" style:UIBarButtonItemStylePlain
                                              target:self
                                              action:@selector(handleButtonTap)];
    [button2 setTitleTextAttributes:textAttrs forState:UIControlStateNormal];

    button3 = [[UIBarButtonItem alloc] initWithTitle:@"Button 3" style:UIBarButtonItemStylePlain
                                              target:self
                                              action:@selector(handleButtonTap)];
    [button3 setTitleTextAttributes:textAttrs forState:UIControlStateNormal];

    button4 = [[UIBarButtonItem alloc] initWithTitle:@"Button 4" style:UIBarButtonItemStylePlain
                                              target:self
                                              action:@selector(handleButtonTap)];
    [button4 setTitleTextAttributes:textAttrs forState:UIControlStateNormal];

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
            connectivityButton,
            nil]];

    [self.view addSubview:topToolBar];
}

- (void) handleButtonTap
{
    NSLog(@"BUTTON TAPPED");
}
@end