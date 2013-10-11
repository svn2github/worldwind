/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import "ScaleBarView.h"
#import "WorldWindView.h"
#import "WWNavigatorState.h"
#import "WWSceneController.h"
#import "WWVec4.h"
#import "WWGlobe.h"


@implementation ScaleBarView
{
    WorldWindView* wwv;
    UILabel* scaleLabel;
    WWVec4* modelPoint; // temp variable to avoid having to recreate it every frame.
}

- (ScaleBarView*) initWithFrame:(CGRect)frame worldWindView:(WorldWindView*)worldWindView
{
    self = [super initWithFrame:frame];

    wwv = worldWindView;
    [wwv addDelegate:self];

    modelPoint = [[WWVec4 alloc] initWithZeroVector];

    scaleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, frame.size.width, frame.size.height)];
    [scaleLabel setTextColor:[UIColor whiteColor]];
    [scaleLabel setTextAlignment:NSTextAlignmentCenter];
    [self addSubview:scaleLabel];

    [self setBackgroundColor:[UIColor clearColor]];

    return self;
}

- (void) viewDidDraw:(WorldWindView*)worldWindView
{
    [self setNeedsDisplay];
}

- (void) drawRect:(CGRect)rect
{
    CGContextRef context = UIGraphicsGetCurrentContext();
    [[UIColor clearColor] set];
    CGContextFillRect(context, rect);

    CGSize wwvSize = [wwv frame].size;
    id <WWNavigatorState> navState = [[wwv sceneController] navigatorState];
    WWLine* ray = [navState rayFromScreenPoint:CGPointMake(wwvSize.width / 2, wwvSize.height / 2)];
    if (![[[wwv sceneController] globe] intersectWithRay:ray result:modelPoint])
        return;

    double d = [[navState eyePoint] distanceTo3:modelPoint];
    double pixelSize = [navState pixelSizeAtDistance:d];

    CGRect frame = [self frame];
    float width = frame.size.width;
    double scaleDistance = pixelSize * width * 3.280839895; // in feet
    NSString* unitLabel = @"ft";
    if (scaleDistance > 5280)
    {
        scaleDistance /= 5280;
        unitLabel = scaleDistance >= 2 ? @"miles" : @"mile";
    }

    int pot = (int) floor(log10(scaleDistance));
    NSString* s = [[NSString alloc] initWithFormat:@"%f", scaleDistance];
    int digit = [[s substringToIndex:1] integerValue];
    double truncatedScaleDistance = digit * pow(10, pot);
    if (digit >= 5)
        truncatedScaleDistance = 5 * pow(10, pot);
    else if (digit >= 2)
        truncatedScaleDistance = 2 * pow(10, pot);
    width *= truncatedScaleDistance / scaleDistance;

    CGContextSetLineWidth(context, 2);
    [[UIColor whiteColor] set];

    float margin = 1 + (frame.size.width - width) / 2;

    CGContextBeginPath(context);
    CGContextMoveToPoint(context, margin, frame.size.height - 12);
    CGContextAddLineToPoint(context, margin, frame.size.height - 2);
    CGContextAddLineToPoint(context, frame.size.width - margin, frame.size.height - 2);
    CGContextAddLineToPoint(context, frame.size.width - margin, frame.size.height - 12);
    CGContextStrokePath(context);

    NSString* displayString = [[NSString alloc] initWithFormat:@"%.0f %@", truncatedScaleDistance, unitLabel];
    [scaleLabel setText:displayString];
}

@end