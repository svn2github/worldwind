/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id: AppDelegate.m 1170 2013-02-11 19:05:20Z tgaskins $
 */

#import <UIKit/UIKit.h>

@class WorldWindView;

@interface MainScreenViewController : UIViewController <UIGestureRecognizerDelegate>

@property (nonatomic, readonly) WorldWindView* wwv;

@end
