/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import "TerrainProfileView.h"
#import "WWPosition.h"
#import "WWGlobe.h"
#import "WorldWindView.h"
#import "WWSceneController.h"

#define NUM_INTERNAL_SEGMENTS (20)

@implementation TerrainProfileView
{
    int numPoints;
    float* xs;
    float* ys;
    UILabel* minLabel;
    UILabel* maxLabel;
    UILabel* crosshairLabel;
    float* gradientColors;
}

- (TerrainProfileView*) initWithFrame:(CGRect)frame worldWindView:(WorldWindView*)worldWindView
{
    self = [super initWithFrame:frame];

    _wwv = worldWindView;
    [_wwv addDelegate:self];

    xs = nil;
    ys = nil;

    _opacity = 0.5;
    gradientColors = malloc((size_t) 24 * sizeof(float));
    gradientColors[0] = 0.0;
    gradientColors[1] = 1.0;
    gradientColors[2] = 0.0;
    gradientColors[3] = _opacity;
    gradientColors[4] = 0.0;
    gradientColors[5] = 1.0;
    gradientColors[6] = 0.0;
    gradientColors[7] = _opacity;
    gradientColors[8] = 1.0;
    gradientColors[9] = 1.0;
    gradientColors[10] = 0.0;
    gradientColors[11] = _opacity;
    gradientColors[12] = 1.0;
    gradientColors[13] = 1.0;
    gradientColors[14] = 0.0;
    gradientColors[15] = _opacity;
    gradientColors[16] = 1.0;
    gradientColors[17] = 0.0;
    gradientColors[18] = 0.0;
    gradientColors[19] = _opacity;
    gradientColors[20] = 1.0;
    gradientColors[21] = 0.0;
    gradientColors[22] = 0.0;
    gradientColors[23] = _opacity;

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

- (void) viewDidDraw:(WorldWindView*)worldWindView
{
    [self setNeedsDisplay];
}

- (void) setPath:(NSArray*)path
{
    _path = path;

    [self setNeedsDisplay];
}

- (void) setWarningAltitude:(float)warningAltitude dangerAltitude:(float)dangerAltitude
{
    _warningAltitude = warningAltitude;
    _dangerAltitude = dangerAltitude;

    [self setNeedsDisplay];
}

- (void) setOpacity:(float)opacity
{
    _opacity = opacity;

    gradientColors[3] = _opacity;
    gradientColors[7] = _opacity;
    gradientColors[11] = _opacity;
    gradientColors[15] = _opacity;
    gradientColors[19] = _opacity;
    gradientColors[23] = _opacity;

    [self setNeedsDisplay];
}
//
//- (void) setAircraftLocation:(CGPoint)aircraftLocation
//{
//    _aircraftLocation = aircraftLocation;
//
//    [self setNeedsDisplay];
//}

- (void) computeProfile
{
    if (xs != nil)
    {
        free(xs);
        xs = nil;
    }
    if (ys != nil)
    {
        free(ys);
        ys = nil;
    }

    WWGlobe* globe = [[_wwv sceneController] globe];

    numPoints = ([_path count] - 1) * (NUM_INTERNAL_SEGMENTS + 1);
    xs = malloc((size_t) numPoints * sizeof(float_t));
    ys = malloc((size_t) numPoints * sizeof(float_t));
    WWPosition* pos = [[WWPosition alloc] init];

    int n = 0;
    for (NSUInteger i = 0; i < [_path count] - 1; i++)
    {
        WWLocation* posA = [_path objectAtIndex:i];
        WWLocation* posB = [_path objectAtIndex:i + 1];

        double segmentLength = [WWLocation greatCircleDistance:posA endLocation:posB];
        double azimuth = [WWLocation greatCircleAzimuth:posA endLocation:posB];
        double ds = segmentLength / NUM_INTERNAL_SEGMENTS;

        for (NSUInteger j = 0; j <= NUM_INTERNAL_SEGMENTS; j++)
        {
            if (n == 0)
                xs[n] = 0;
            else if (j == 0)
                xs[n] = xs[n - 1];
            else
                xs[n] = xs[n - 1] + (float) ds;

            [WWLocation greatCircleLocation:posA azimuth:azimuth distance:j * ds outputLocation:pos];
            ys[n++] = 3.280839895f * (float) [globe elevationForLatitude:pos.latitude longitude:pos.longitude];
        }
    }
}

- (void) drawRect:(CGRect)rect
{
    [self computeProfile];

    CGContextRef context = UIGraphicsGetCurrentContext();
    [[UIColor clearColor] set];
    CGContextFillRect(context, rect);

    if (numPoints < 2)
        return;

    CGRect frame = CGRectMake(0, 0, [self frame].size.width, [self frame].size.height);

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

    if (_warningAltitude > yMax)
    {
        [[[UIColor alloc] initWithRed:0 green:1 blue:0 alpha:_opacity] set];
        CGContextFillRect(context, rect);
    }
    else if (_dangerAltitude > yMax)
    {
        float y0 = 1.0 - (_warningAltitude - yMin) / dy;
        CGFloat locations[3] = {1.0, y0 + 0.03, y0};
        CGGradientRef gradient = CGGradientCreateWithColorComponents(CGColorSpaceCreateDeviceRGB(), gradientColors, locations, 3);
        CGContextDrawLinearGradient(context, gradient, CGPointMake(0, 0), CGPointMake(0, frame.size.height),
                kCGGradientDrawsBeforeStartLocation | kCGGradientDrawsAfterEndLocation);
        CGGradientRelease(gradient);
    }
    else
    {
        float y0 = 1.0 - (_warningAltitude - yMin) / dy;
        float r0 = 1.0 - (_dangerAltitude - yMin) / dy;
        CGFloat locations[6] = {1.0, y0 + 0.03, y0, r0 + 0.03, r0, 0.0};
        CGGradientRef gradient = CGGradientCreateWithColorComponents(CGColorSpaceCreateDeviceRGB(), gradientColors, locations, 6);
        CGContextDrawLinearGradient(context, gradient, CGPointMake(0, 0), CGPointMake(0, frame.size.height),
                kCGGradientDrawsBeforeStartLocation | kCGGradientDrawsAfterEndLocation);
        CGGradientRelease(gradient);
    }

    NSNumberFormatter* formatter = [[NSNumberFormatter alloc] init];
    [formatter setNumberStyle:NSNumberFormatterDecimalStyle];

    NSString* numberString = [formatter stringFromNumber:[[NSNumber alloc] initWithFloat:ceilf(yMin)]];
    NSString* displayString = [[NSString alloc] initWithFormat:@"%@ ft", numberString];
    [minLabel setText:displayString];

    numberString = [formatter stringFromNumber:[[NSNumber alloc] initWithFloat:ceilf(yMax)]];
    displayString = [[NSString alloc] initWithFormat:@"%@ ft", numberString];
    NSMutableDictionary* attrDict = [[NSMutableDictionary alloc] init];
    [attrDict setObject:[maxLabel font] forKey:NSFontAttributeName];
    CGSize stringSize = [displayString sizeWithAttributes:attrDict];
    float maxLabelX = frame.size.width * (xAtYMax - xMin) / dx - 0.5 * stringSize.width;
    [maxLabel setFrame:CGRectMake(maxLabelX, 0, stringSize.width, stringSize.height)];
    [maxLabel setText:displayString];
//
//    float crosshairSize = 10;
//    float x = frame.size.width * (_aircraftLocation.x - xMin) / dx;
//    float y = frame.size.height * (1 - (_aircraftLocation.y - yMin) / dy);
//
//    [[UIColor blackColor] set];
//    CGContextBeginPath(context);
//    CGContextMoveToPoint(context, x - crosshairSize + 1, y + 1);
//    CGContextAddLineToPoint(context, x + crosshairSize + 1, y + 1);
//    CGContextMoveToPoint(context, x + 1, y - crosshairSize + 1);
//    CGContextAddLineToPoint(context, x + 1, y + crosshairSize + 1);
//    CGContextStrokePath(context);
//
//    [[UIColor whiteColor] set];
//    CGContextBeginPath(context);
//    CGContextMoveToPoint(context, x - crosshairSize, y);
//    CGContextAddLineToPoint(context, x + crosshairSize, y);
//    CGContextMoveToPoint(context, x, y - crosshairSize);
//    CGContextAddLineToPoint(context, x, y + crosshairSize);
//    CGContextStrokePath(context);
//
//    numberString = [formatter stringFromNumber:[[NSNumber alloc] initWithFloat:_aircraftLocation.y]];
//    displayString = [[NSString alloc] initWithFormat:@"%@ ft", numberString];
//    stringSize = [displayString sizeWithAttributes:attrDict];
//    [crosshairLabel setFrame:CGRectMake(x + 12, y - 0.75 * stringSize.height, 200, 30)];
//    [crosshairLabel setText:displayString];
}
@end