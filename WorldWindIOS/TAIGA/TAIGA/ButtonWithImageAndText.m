/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import "ButtonWithImageAndText.h"

@implementation ButtonWithImageAndText

- (ButtonWithImageAndText*) initWithImageName:(NSString*)imageName text:(NSString*)text size:(CGSize)size target:(id)
        target                         action:(SEL)action;
{
    self = [super initWithFrame:CGRectMake(0, 0, size.width, size.height)];

    [self setShowsTouchWhenHighlighted:YES];

    [self setTitle:text forState:UIControlStateNormal];
    [self.titleLabel setFont:[UIFont fontWithName:@"Helvetica-Bold" size:18]];
    [self.titleLabel setShadowOffset:CGSizeMake(0, -1)];

    [self setImage:[UIImage imageNamed:imageName] forState:UIControlStateNormal];

    [self centerAlignImageAndTextForButton:self];

    [self addTarget:target action:action forControlEvents:UIControlEventTouchUpInside];

    return self;
}

- (void)centerAlignImageAndTextForButton:(UIButton*)button
{
    CGFloat spacing = 5;
    CGSize imageSize = button.imageView.frame.size;
    button.titleEdgeInsets = UIEdgeInsetsMake(0, -imageSize.width, -(imageSize.height + spacing), 0);
    CGSize titleSize = button.titleLabel.frame.size;
    button.imageEdgeInsets = UIEdgeInsetsMake(-(titleSize.height + spacing), 0, 0, -titleSize.width);
}

- (void) setFontSize:(int)fontSize
{
    [self.titleLabel setFont:[UIFont fontWithName:@"Helvetica-Bold" size:fontSize]];
    [self centerAlignImageAndTextForButton:self];
}

- (void) setTextColor:(UIColor*)textColor
{
    [self setTitleColor:textColor forState:UIControlStateNormal];
}

- (void) highlight:(BOOL)highlight
{
    if (highlight)
        [self setBackgroundColor:[[UIColor alloc] initWithRed:1. green:1. blue:1. alpha:0.2]];
    else
        [self setBackgroundColor:[UIColor clearColor]];
}

@end