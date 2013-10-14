/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import "TerrainProfileView.h"

@implementation TerrainProfileView
{
    int numPoints;
    float* xs;
    float* ys;
    UILabel* minLabel;
    UILabel* maxLabel;
    UILabel* crosshairLabel;
}

static float const alpha = 0.5;
static float const colorComponents[] = {
        0.0, 1.0, 0.0, alpha, // solid green area
        0.0, 1.0, 0.0, alpha, // edge of green-to-yellow gradient
        1.0, 1.0, 0.0, alpha, // beginning of solid yellow area
        1.0, 1.0, 0.0, alpha, // end of solid yellow area
        1.0, 0.0, 0.0, alpha, // edge of yellow-to-red gradient
        1.0, 0.0, 0.0, alpha  // solid red area
};

- (TerrainProfileView*) initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];

    [self setBackgroundColor:[UIColor clearColor]];
    [self setUserInteractionEnabled:NO];

    minLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, frame.size.height - 22, frame.size.width, 30)];
    [minLabel setTextColor:[UIColor whiteColor]];
    [minLabel setTextAlignment:NSTextAlignmentCenter];
    [minLabel setShadowColor:[UIColor blackColor]];
    [minLabel setShadowOffset:CGSizeMake(1, 1)];
    [self addSubview:minLabel];

    maxLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 200, 30)];
    [maxLabel setTextColor:[UIColor whiteColor]];
    [maxLabel setTextAlignment:NSTextAlignmentLeft];
    [maxLabel setShadowColor:[UIColor blackColor]];
    [maxLabel setShadowOffset:CGSizeMake(1, 1)];
    [self addSubview:maxLabel];

    crosshairLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 200, 30)];
    [crosshairLabel setTextColor:[UIColor whiteColor]];
    [crosshairLabel setTextAlignment:NSTextAlignmentLeft];
    [crosshairLabel setShadowColor:[UIColor blackColor]];
    [crosshairLabel setShadowOffset:CGSizeMake(1, 1)];
    [self addSubview:crosshairLabel];

    return self;
}

- (void) setValues:(int)count xValues:(float*)xValues yValues:(float*)yValues
{
    numPoints = count;
    xs = xValues;
    ys = yValues;

    [self setNeedsDisplay];
}

- (void) setDangerAltitude:(float)dangerAltitude
{
    _dangerAltitude = dangerAltitude;

    [self setNeedsDisplay];
}

- (void) setWarningAltitude:(float)warningAltitude
{
    _warningAltitude = warningAltitude;

    [self setNeedsDisplay];
}

- (void) setAircraftLocation:(CGPoint)aircraftLocation
{
    _aircraftLocation = aircraftLocation;

    [self setNeedsDisplay];
}

- (void) drawRect:(CGRect)rect
{
    CGContextRef context = UIGraphicsGetCurrentContext();
    [[UIColor clearColor] set];
    CGContextFillRect(context, rect);

    if (numPoints < 2)
        return;

    CGRect frame = [self frame];

    float xMin = xs[0];
    float xMax = xs[numPoints - 1];
    float yMin = 0;
    float yMax = -FLT_MAX;
    float xAtYMax = xMin;

    for (int i = 0; i < numPoints; i++)
    {
        if (ys[i] < yMin)
            yMin = ys[i];
        if (ys[i] > yMax)
        {
            yMax = ys[i];
            xAtYMax = xs[i];
        }
    }

    float dx = xMax - xMin;
    float dy = yMax - yMin;

    float firstY = frame.size.height * (1 - (ys[0] - yMin) / dy);

    CGContextBeginPath(context);
    CGContextMoveToPoint(context, 0, firstY);

    for (int i = 0; i < numPoints; i++)
    {
        float x = frame.size.width * (xs[i] - xMin) / dx;
        float y = frame.size.height * (1 - (ys[i] - yMin) / dy);
        CGContextAddLineToPoint(context, x, y);
    }

    // Add the bottom of the graph.
    CGContextAddLineToPoint(context, frame.size.width, frame.size.height);
    CGContextAddLineToPoint(context, 0, frame.size.height);
    CGContextAddLineToPoint(context, 0, firstY);

    CGContextClip(context);

    float y0 = 1.0 - (_warningAltitude - yMin) / dy;
    float r0 = 1.0 - (_dangerAltitude - yMin) / dy;
    CGFloat locations[6] = {1.0, y0 + 0.03, y0, r0 + 0.03, r0, 0.0};
    CGGradientRef myGradient = CGGradientCreateWithColorComponents(CGColorSpaceCreateDeviceRGB(), colorComponents, locations, 6);
    CGContextDrawLinearGradient(context, myGradient, CGPointMake(0, 0), CGPointMake(0, frame.size.height), 0);

    NSNumberFormatter* formatter = [[NSNumberFormatter alloc] init];
    [formatter setNumberStyle:NSNumberFormatterDecimalStyle];

    NSString* numberString = [formatter stringFromNumber:[[NSNumber alloc] initWithFloat:yMin]];
    NSString* displayString = [[NSString alloc] initWithFormat:@"%@ ft", numberString];
    [minLabel setText:displayString];

    numberString = [formatter stringFromNumber:[[NSNumber alloc] initWithFloat:yMax]];
    displayString = [[NSString alloc] initWithFormat:@"%@ ft", numberString];
    NSMutableDictionary* attrDict = [[NSMutableDictionary alloc] init];
    [attrDict setObject:[maxLabel font] forKey:NSFontAttributeName];
    CGSize stringSize = [displayString sizeWithAttributes:attrDict];
    float maxLabelX = frame.size.width * (xAtYMax - xMin) / dx - 0.5 * stringSize.width;
    [maxLabel setFrame:CGRectMake(maxLabelX, 0, stringSize.width, stringSize.height)];
    [maxLabel setText:displayString];

    float crosshairSize = 10;
    float x = frame.size.width * (_aircraftLocation.x - xMin) / dx;
    float y = frame.size.height * (1 - (_aircraftLocation.y - yMin) / dy);

    [[UIColor blackColor] set];
    CGContextBeginPath(context);
    CGContextMoveToPoint(context, x - crosshairSize + 1, y + 1);
    CGContextAddLineToPoint(context, x + crosshairSize + 1, y + 1);
    CGContextMoveToPoint(context, x + 1, y - crosshairSize + 1);
    CGContextAddLineToPoint(context, x + 1, y + crosshairSize + 1);
    CGContextStrokePath(context);

    [[UIColor whiteColor] set];
    CGContextBeginPath(context);
    CGContextMoveToPoint(context, x - crosshairSize, y);
    CGContextAddLineToPoint(context, x + crosshairSize, y);
    CGContextMoveToPoint(context, x, y - crosshairSize);
    CGContextAddLineToPoint(context, x, y + crosshairSize);
    CGContextStrokePath(context);

    numberString = [formatter stringFromNumber:[[NSNumber alloc] initWithFloat:_aircraftLocation.y]];
    displayString = [[NSString alloc] initWithFormat:@"%@ ft", numberString];
    stringSize = [displayString sizeWithAttributes:attrDict];
    [crosshairLabel setFrame:CGRectMake(x + 12, y - 0.75 * stringSize.height, 200, 30)];
    [crosshairLabel setText:displayString];
}
@end