/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import <Foundation/Foundation.h>

@interface TextViewController : UIViewController

@property(nonatomic, readonly) UITextView* textView;

- (TextViewController*)initWithFrame:(CGRect)frame;

@end