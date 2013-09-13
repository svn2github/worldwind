/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import <Foundation/Foundation.h>


@interface ChartViewController : UIViewController <UIScrollViewDelegate>

@property (nonatomic, readonly) UIImageView* imageView;

- (ChartViewController*) initWithFrame:(CGRect)frame;

@end