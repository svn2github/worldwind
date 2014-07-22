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
    UIButton* gdbMessageButton;
}

- (DataBarViewController*) initWithFrame:(CGRect)frame
{
    self = [super init];

    myFrame = frame;

    formatter = [[UnitsFormatter alloc] init];
    currentLocation = [[CLLocation alloc] init];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(aircraftPositionDidChange:)
                                                 name:TAIGA_CURRENT_AIRCRAFT_POSITION object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateGDBMessageView:)
                                                 name:TAIGA_GDB_MESSAGE object:nil];

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
    CGContextSetFillColorWithColor(context, [[UIColor colorWithRed:0.5 green:0.5 blue:0.5 alpha:0.5] CGColor]);
    CGContextFillRect(context, rect);
    UIImage* transparentImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    [toolbar setBackgroundImage:transparentImage forToolbarPosition:UIToolbarPositionAny barMetrics:UIBarMetricsDefault];

    gpsPositionButton = [[UIButton alloc] init];
    [gpsPositionButton.titleLabel setNumberOfLines:0];
    [gpsPositionButton.titleLabel setLineBreakMode:NSLineBreakByWordWrapping];
    [gpsPositionButton.titleLabel setTextAlignment:NSTextAlignmentCenter];
    [gpsPositionButton setBounds:CGRectMake(0, 0, 300, self.view.frame.size.height)];
    [gpsPositionButton.titleLabel setShadowColor:[UIColor blackColor]];
    [gpsPositionButton.titleLabel setShadowOffset:CGSizeMake(1, 1)];
    [self updateGPSView];

    UIBarButtonItem* gpsPositionItem = [[UIBarButtonItem alloc] initWithCustomView:gpsPositionButton];


    gdbMessageButton = [[UIButton alloc] init];
    [gdbMessageButton.titleLabel setNumberOfLines:0];
    [gdbMessageButton.titleLabel setLineBreakMode:NSLineBreakByWordWrapping];
    [gdbMessageButton.titleLabel setTextAlignment:NSTextAlignmentCenter];
    [gdbMessageButton setBounds:CGRectMake(0, 0, 200, self.view.frame.size.height)];
    [gdbMessageButton.titleLabel setShadowColor:[UIColor blackColor]];
    [gdbMessageButton.titleLabel setShadowOffset:CGSizeMake(1, 1)];
    [self updateGPSView];

    UIBarButtonItem* gdbMessageItem = [[UIBarButtonItem alloc] initWithCustomView:gdbMessageButton];

    UIBarButtonItem* flexibleSpace = [[UIBarButtonItem alloc]
            initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    UIBarButtonItem* fixedSpace = [[UIBarButtonItem alloc]
            initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
    fixedSpace.width = 200;

    [toolbar setItems:[NSArray arrayWithObjects:
            fixedSpace,
            flexibleSpace,
            gpsPositionItem,
            flexibleSpace,
            gdbMessageItem,
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

- (void) aircraftPositionDidChange:(NSNotification*)notification
{
    currentLocation = [notification object];
    [self updateGPSView];
}

- (void) updateGPSView
{
    // Insert non-breaking spaces between the lat/lon/alt values.
    NSString* title = [[NSString alloc] initWithFormat:@"GPS\n%@\u00a0%@\u00a0%@",
                                                       [formatter formatDegreesLatitude:currentLocation.coordinate.latitude],
                                                       [formatter formatDegreesLongitude:currentLocation.coordinate.longitude],
                                                       [formatter formatMetersAltitude:currentLocation.altitude]];
    [gpsPositionButton setTitle:title forState:UIControlStateNormal];
}

- (void) updateGDBMessageView:(NSNotification*)notification
{
    NSString* message = [notification object];
    NSString* title = [[NSString alloc] initWithFormat:@"GDB Message\n%@", message != nil ? message : @"NONE"];
    [gdbMessageButton setTitle:title forState:UIControlStateNormal];
}

@end