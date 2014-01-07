/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.

 @version $Id$
 */

#import <Foundation/Foundation.h>

@interface LocationTrackingView : UIView
{
@protected
    BOOL enable;
    UIImage* enabledImage;
    UIImage* disabledImage;
    UIImageView* backgroundView;
    UIButton* button;
}

- (LocationTrackingView*) initWithFrame:(CGRect)frame;

@end