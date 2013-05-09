/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import <UIKit/UIKit.h>

@class WorldWindView;

@interface ViewController : UIViewController <UISearchBarDelegate, UIGestureRecognizerDelegate>

@property (nonatomic, readonly) WorldWindView* wwv;
@property (nonatomic, readonly) UIToolbar* toolbar;

@end