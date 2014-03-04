/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import <UIKit/UIKit.h>

@class WorldWindView;

@interface MovingMapViewController : UIViewController <UIGestureRecognizerDelegate, UINavigationControllerDelegate>

@property (nonatomic, readonly) WorldWindView* wwv;

- (MovingMapViewController*) initWithFrame:(CGRect)frame;

@end
