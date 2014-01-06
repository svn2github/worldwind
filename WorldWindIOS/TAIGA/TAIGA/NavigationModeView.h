/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.

 @version $Id$
 */

#import <Foundation/Foundation.h>

@interface NavigationModeView : UIView
{
@protected
    BOOL enableNavigationMode;
    UIImage* enabledImage;
    UIImage* disabledImage;
    UIImageView* backgroundView;
    UIButton* button;
}

- (NavigationModeView*) initWithFrame:(CGRect)frame;

@end