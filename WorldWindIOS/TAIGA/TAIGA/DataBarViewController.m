/*
 Copyright (C) 2014 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import <CoreLocation/CoreLocation.h>
#import "DataBarViewController.h"
#import "AppConstants.h"
#import "UnitsFormatter.h"

@implementation DataBarViewController
{
    CGRect myFrame;
    UIToolbar* toolbar;
    UnitsFormatter* formatter;
    CLLocation* currentLocation;
    UIButton* gpsPositionButton;
}

- (DataBarViewController*) initWithFrame:(CGRect)frame
{
    self = [super init];

    myFrame = frame;

    formatter = [[UnitsFormatter alloc] init];
    currentLocation = [[CLLocation alloc] init];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(aircraftPositionDidChange:)
                                                 name:TAIGA_CURRENT_AIRCRAFT_POSITION object:nil];

    return self;
}

- (void) loadView
{
    self.view = [[UIView alloc] initWithFrame:myFrame];
    self.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
    self.view.autoresizesSubviews = YES;
    self.view.clipsToBounds = YES;

    toolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 0, myFrame.size.width, myFrame.size.height)];
    toolbar.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    toolbar.autoresizesSubviews = YES;
    toolbar.clipsToBounds = YES;

    // Create a transparent background image for the toolbar.
    CGRect rect = CGRectMake(0, 0, 1, 1);
    UIGraphicsBeginImageContext(rect.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetFillColorWithColor(context, [[UIColor clearColor] CGColor]);
    CGContextFillRect(context, rect);
    UIImage* transparentImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    [toolbar setBackgroundImage:transparentImage forToolbarPosition:UIToolbarPositionAny barMetrics:UIBarMetricsDefault];

    gpsPositionButton = [[UIButton alloc] init];
    [gpsPositionButton.titleLabel setNumberOfLines:0];
    [gpsPositionButton.titleLabel setLineBreakMode:NSLineBreakByWordWrapping];
    [gpsPositionButton.titleLabel setTextAlignment:NSTextAlignmentCenter];
    [gpsPositionButton setBounds:CGRectMake(0, 0, 160, self.view.frame.size.height)];
    [gpsPositionButton.titleLabel setShadowColor:[UIColor blackColor]];
    [gpsPositionButton.titleLabel setShadowOffset:CGSizeMake(1, 1)];
    [self updateGPSView];

    UIBarButtonItem* gpsPositionItem = [[UIBarButtonItem alloc] initWithCustomView:gpsPositionButton];

    UIBarButtonItem* flexibleSpace = [[UIBarButtonItem alloc]
            initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];

    [toolbar setItems:[NSArray arrayWithObjects:
            flexibleSpace,
            gpsPositionItem,
            flexibleSpace,
            nil]];

    // Disable user interaction for the data bar so that gestures pass through to the World Wind view.
    self.view.userInteractionEnabled = NO;
    [toolbar setUserInteractionEnabled:NO];
    for (UIView* v in [toolbar subviews])
    {
        v.userInteractionEnabled = NO;
    }

    [self.view addSubview:toolbar];
}

- (void) viewDidLoad
{
    [super viewDidLoad];
}

- (void) aircraftPositionDidChange:(NSNotification*)notification
{
    currentLocation = [notification object];
    [self updateGPSView];
}

- (void) updateGPSView
{
    NSString* title = [[NSString alloc] initWithFormat:@"GPS\n%@\u00a0%@",
                                                       [formatter formatDegreesLatitude:currentLocation.coordinate.latitude],
                                                       [formatter formatDegreesLongitude:currentLocation.coordinate.longitude]];
    [gpsPositionButton setTitle:title forState:UIControlStateNormal];
}

@end