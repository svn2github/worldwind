/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import <Foundation/Foundation.h>


@interface ButtonWithImageAndText : UIButton

@property (nonatomic) int fontSize;
@property (nonatomic) UIColor* textColor;

- (ButtonWithImageAndText*) initWithImageName:(NSString*)imageName text:(NSString*)text size:(CGSize)size target:(id)
        target action:(SEL)action;

- (void) highlight:(BOOL)highlight;

@end