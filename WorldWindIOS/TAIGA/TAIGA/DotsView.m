/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import "DotsView.h"

@implementation DotsView

- (DotsView*) initWithCenter:(CGPoint)center dotCount:(int)dotCount
{
    self = [super init];

    _dotSize = 15;

    _viewCenter = center;
    _dotCount = dotCount;

    float width = (2 * _dotCount - 1) * _dotSize;
    [self setFrame:CGRectMake(_viewCenter.x - 0.5 * width, _viewCenter.y, width, _dotSize)];

    [self setBackgroundColor:[UIColor clearColor]];

    return self;
}

- (void) drawRect:(CGRect)rect
{
    float width = (2 * _dotCount - 1) * _dotSize;

    for (NSUInteger i = 0; i < _dotCount; i++)
    {
        float x = (0.5 + i * 2) * _dotSize;
        CGPoint arcCenter = CGPointMake(x, 0.5 * _dotSize);
        UIBezierPath* aPath = [UIBezierPath bezierPathWithArcCenter:arcCenter radius:0.5 * _dotSize
                                                         startAngle:0 endAngle:(float) (2 * M_PI) clockwise:YES];
        [aPath closePath];

        if (i == _highlightedDot)
            [[UIColor whiteColor] setFill];
        else
            [[UIColor grayColor] setFill];
        [aPath fill];
    }
}

@end