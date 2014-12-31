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
    UIButton* headingButton;
    UIButton* speedButton;
    UIButton* gpsAccuracyButton;
    UIButton* destinationDistanceButton;
//    UIButton* gdbMessageButton;
}

- (DataBarViewController*) initWithFrame:(CGRect)frame
{
    self = [super init];

    myFrame = frame;

    formatter = [[UnitsFormatter alloc] init];
    currentLocation = [[CLLocation alloc] init];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(aircraftPositionDidChange:)
                                                 name:TAIGA_CURRENT_AIRCRAFT_POSITION object:nil];
//    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateGDBMessageView:)
//                                                 name:TAIGA_GDB_MESSAGE object:nil];

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

    gpsAccuracyButton = [[UIButton alloc] init];
    [gpsAccuracyButton.titleLabel setNumberOfLines:0];
    [gpsAccuracyButton.titleLabel setLineBreakMode:NSLineBreakByWordWrapping];
    [gpsAccuracyButton.titleLabel setTextAlignment:NSTextAlignmentCenter];
    [gpsAccuracyButton setBounds:CGRectMake(0, 0, 200, self.view.frame.size.height)];
    [gpsAccuracyButton.titleLabel setShadowColor:[UIColor blackColor]];
    [gpsAccuracyButton.titleLabel setShadowOffset:CGSizeMake(1, 1)];
    [self updateGPSView];
    UIBarButtonItem* gpsAccuracyItem = [[UIBarButtonItem alloc] initWithCustomView:gpsAccuracyButton];

//
//    gdbMessageButton = [[UIButton alloc] init];
//    [gdbMessageButton.titleLabel setNumberOfLines:0];
//    [gdbMessageButton.titleLabel setLineBreakMode:NSLineBreakByWordWrapping];
//    [gdbMessageButton.titleLabel setTextAlignment:NSTextAlignmentCenter];
//    [gdbMessageButton setBounds:CGRectMake(0, 0, 200, self.view.frame.size.height)];
//    [gdbMessageButton.titleLabel setShadowColor:[UIColor blackColor]];
//    [gdbMessageButton.titleLabel setShadowOffset:CGSizeMake(1, 1)];
//    [self updateGPSView];
//
//    UIBarButtonItem* gdbMessageItem = [[UIBarButtonItem alloc] initWithCustomView:gdbMessageButton];

    headingButton = [[UIButton alloc] init];
    [headingButton.titleLabel setNumberOfLines:0];
    [headingButton.titleLabel setLineBreakMode:NSLineBreakByWordWrapping];
    [headingButton.titleLabel setTextAlignment:NSTextAlignmentCenter];
    [headingButton setBounds:CGRectMake(0, 0, 200, self.view.frame.size.height)];
    [headingButton.titleLabel setShadowColor:[UIColor blackColor]];
    [headingButton.titleLabel setShadowOffset:CGSizeMake(1, 1)];
    [self updateHeadingView];
    UIBarButtonItem* headingItem = [[UIBarButtonItem alloc] initWithCustomView:headingButton];

    speedButton = [[UIButton alloc] init];
    [speedButton.titleLabel setNumberOfLines:0];
    [speedButton.titleLabel setLineBreakMode:NSLineBreakByWordWrapping];
    [speedButton.titleLabel setTextAlignment:NSTextAlignmentCenter];
    [speedButton setBounds:CGRectMake(0, 0, 200, self.view.frame.size.height)];
    [speedButton.titleLabel setShadowColor:[UIColor blackColor]];
    [speedButton.titleLabel setShadowOffset:CGSizeMake(1, 1)];
    [self updateSpeedView];
    UIBarButtonItem* speedItem = [[UIBarButtonItem alloc] initWithCustomView:speedButton];

    destinationDistanceButton = [[UIButton alloc] init];
    [destinationDistanceButton.titleLabel setNumberOfLines:0];
    [destinationDistanceButton.titleLabel setLineBreakMode:NSLineBreakByWordWrapping];
    [destinationDistanceButton.titleLabel setTextAlignment:NSTextAlignmentCenter];
    [destinationDistanceButton setBounds:CGRectMake(0, 0, 250, self.view.frame.size.height)];
    [destinationDistanceButton.titleLabel setShadowColor:[UIColor blackColor]];
    [destinationDistanceButton.titleLabel setShadowOffset:CGSizeMake(1, 1)];
    [self updateDestinationDistanceView];
    UIBarButtonItem* destinationDistanceItem = [[UIBarButtonItem alloc] initWithCustomView:destinationDistanceButton];

    UIBarButtonItem* flexibleSpace = [[UIBarButtonItem alloc]
            initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    UIBarButtonItem* fixedSpace = [[UIBarButtonItem alloc]
            initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
    fixedSpace.width = 10;

    [toolbar setItems:[NSArray arrayWithObjects:
//            fixedSpace,
//            flexibleSpace,
//            gpsPositionItem,
            flexibleSpace,
            gpsAccuracyItem,
            flexibleSpace,
            headingItem,
            flexibleSpace,
            speedItem,
            flexibleSpace,
            destinationDistanceItem,
            flexibleSpace,
            fixedSpace,
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
    [self updateHeadingView];
    [self updateSpeedView];
    [self updateDestinationDistanceView];
}

- (void) updateGPSView
{
    // Insert non-breaking spaces between the lat/lon/alt values.
    NSString* title = [[NSString alloc] initWithFormat:@"GPS\n%@\u00a0%@\u00a0%@",
                                                       [formatter formatDegreesLatitude:currentLocation.coordinate.latitude],
                                                       [formatter formatDegreesLongitude:currentLocation.coordinate.longitude],
                                                       [formatter formatMetersAltitude:currentLocation.altitude]];
    [gpsPositionButton setTitle:title forState:UIControlStateNormal];

    title = [[NSString alloc] initWithFormat:@"GPS Accuracy\n%@\u00a0",
                                             [formatter formatFeetDistance:currentLocation                                                               .horizontalAccuracy]];
    [gpsAccuracyButton setTitle:title forState:UIControlStateNormal];
}

- (void) updateHeadingView
{
    double heading = currentLocation.course;
    if (heading < 0)
        heading += 360;

    NSString* title = [[NSString alloc] initWithFormat:@"Heading\n%@\u00a0", [formatter formatAngle2:heading]];
    [headingButton setTitle:title forState:UIControlStateNormal];
}

- (void) updateSpeedView
{
    NSString* title = [[NSString alloc] initWithFormat:@"Ground Speed\n%@\u00a0",
                                                       [formatter formatKnotsSpeed:currentLocation.speed]];
    [speedButton setTitle:title forState:UIControlStateNormal];
}

- (void) updateDestinationDistanceView
{
    NSString* title = [[NSString alloc] initWithFormat:@"Distance to Dest.\n%@\u00a0",
                                                       [formatter formatMilesDistance:0]];
    [destinationDistanceButton setTitle:title forState:UIControlStateNormal];
}
//
//- (void) updateGDBMessageView:(NSNotification*)notification
//{
//    NSString* message = [notification object];
//    NSString* title = [[NSString alloc] initWithFormat:@"GDB Message\n%@", message != nil ? message : @"NONE"];
//    [gdbMessageButton setTitle:title forState:UIControlStateNormal];
//}

@end