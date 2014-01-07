/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.

 @version $Id$
 */

#import "LocationTrackingView.h"
#import "AppConstants.h"

@implementation LocationTrackingView

- (LocationTrackingView*) initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];

    // Provide a resizable rounded rectangle background image. This image will be stretched to fill the view's bounds
    // while keeping the 5 pixel rounded corners intact.
    UIImage* backgroundImage = [[[UIImage imageNamed:@"rounded-rect.png"]
            resizableImageWithCapInsets:UIEdgeInsetsMake(5, 5, 5, 5) resizingMode:UIImageResizingModeStretch]
            imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    backgroundView = [[UIImageView alloc] initWithImage:backgroundImage];
    [backgroundView setTintColor:[UIColor colorWithWhite:0.8 alpha:1]];
    [self addSubview:backgroundView];

    enabledImage = [[UIImage imageNamed:@"193-location-arrow"]
            imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    disabledImage = [[UIImage imageNamed:@"193-location-arrow-outline"]
            imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    button = [[UIButton alloc] init];
    [button setContentEdgeInsets:UIEdgeInsetsMake(10, 10, 10, 10)];
    [button setImage:disabledImage forState:UIControlStateNormal];
    [button addTarget:self action:@selector(buttonTapped) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:button];

    [self setAlpha:0.95];
    [self layout];

    return self;
}

- (void) layout
{
    NSDictionary* viewsDictionary = NSDictionaryOfVariableBindings(backgroundView, button);
    [backgroundView setTranslatesAutoresizingMaskIntoConstraints:NO];
    [button setTranslatesAutoresizingMaskIntoConstraints:NO];

    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[backgroundView(==button)]|" options:0 metrics:nil views:viewsDictionary]];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[backgroundView(==button)]|" options:0 metrics:nil views:viewsDictionary]];
    [self addConstraint:[NSLayoutConstraint constraintWithItem:button attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual
                                                        toItem:self attribute:NSLayoutAttributeCenterX multiplier:1 constant:0]];
    [self addConstraint:[NSLayoutConstraint constraintWithItem:button attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual
                                                        toItem:self attribute:NSLayoutAttributeCenterY multiplier:1 constant:0]];
}

- (void) buttonTapped
{
    enable = !enable;
    [button setImage:enable ? enabledImage : disabledImage forState:UIControlStateNormal];

    NSNumber* yn = [NSNumber numberWithBool:enable];
    [[NSNotificationCenter defaultCenter] postNotificationName:TAIGA_ENABLE_LOCATION_TRACKING object:yn];
}

@end