/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import <Foundation/Foundation.h>

@class WorldWindView;

@interface WeatherScreenController : UIViewController <UIGestureRecognizerDelegate,  UIScrollViewDelegate>

@property (atomic) NSNumber* refreshInProgress;

- (WeatherScreenController*) initWithFrame:(CGRect)frame;

@end