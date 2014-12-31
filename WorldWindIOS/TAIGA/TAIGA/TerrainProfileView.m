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
#import "TAIGA.h"
#import "UnitsFormatter.h"
#import "AppConstants.h"

#define NUM_INTERNAL_SEGMENTS (20)
#define BOTTOM_MARGIN (20)
#define TRI_HEIGHT (30)
#define TRI_HALF_WIDTH (12)
#define AXIS_LABEL_Y (175)

@implementation TerrainProfileView
{
    int numPoints;
    float* xs;
    float* ys;
//    UILabel* minLabel;
    UILabel* maxLabel;
    UILabel* leftLabelView;
    UILabel* centerLabelView;
    UILabel* rightLabelView;
    UILabel* noCourseLabel;
    UILabel* aircraftAltitudeLabelView;
    CGFloat* gradientColors;
}

- (TerrainProfileView*) initWithFrame:(CGRect)frame worldWindView:(WorldWindView*)worldWindView
{
    self = [super initWithFrame:frame];

    _wwv = worldWindView;
    [_wwv addDelegate:self];

    xs = nil;
    ys = nil;

    _opacity = 0.5;
    gradientColors = malloc((size_t) 24 * sizeof(CGFloat));
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

    [self setAutoresizesSubviews:YES];
    [self setAutoresizingMask:UIViewAutoresizingFlexibleWidth];
//
//    minLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, frame.size.height - 22, frame.size.width, 30)];
//    [minLabel setTextColor:[UIColor whiteColor]];
//    [minLabel setTextAlignment:NSTextAlignmentCenter];
//    [minLabel setShadowColor:[UIColor blackColor]];
//    [minLabel setShadowOffset:CGSizeMake(1, 1)];
//    [self addSubview:minLabel];

    maxLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 400, 30)];
    [maxLabel setTextColor:[UIColor whiteColor]];
    [maxLabel setTextAlignment:NSTextAlignmentLeft];
    [maxLabel setShadowColor:[UIColor blackColor]];
    [maxLabel setShadowOffset:CGSizeMake(1, 1)];
    [self addSubview:maxLabel];

    leftLabelView = [[UILabel alloc] initWithFrame:CGRectMake(5, AXIS_LABEL_Y, 100, 30)];
    [leftLabelView setTextColor:[UIColor whiteColor]];
    [leftLabelView setTextAlignment:NSTextAlignmentLeft];
    [leftLabelView setShadowColor:[UIColor blackColor]];
    [leftLabelView setShadowOffset:CGSizeMake(1, 1)];
    [self addSubview:leftLabelView];

    centerLabelView = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 200, 30)];
    [centerLabelView setTextColor:[UIColor whiteColor]];
    [centerLabelView setTextAlignment:NSTextAlignmentLeft];
    [centerLabelView setShadowColor:[UIColor blackColor]];
    [centerLabelView setShadowOffset:CGSizeMake(1, 1)];
    [self addSubview:centerLabelView];

    rightLabelView = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 200, 30)];
    [rightLabelView setTextColor:[UIColor whiteColor]];
    [rightLabelView setTextAlignment:NSTextAlignmentLeft];
    [rightLabelView setShadowColor:[UIColor blackColor]];
    [rightLabelView setShadowOffset:CGSizeMake(1, 1)];
    [self addSubview:rightLabelView];

    aircraftAltitudeLabelView = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 100, 30)];
    [aircraftAltitudeLabelView setTextColor:[UIColor whiteColor]];
    [aircraftAltitudeLabelView setTextAlignment:NSTextAlignmentLeft];
    [aircraftAltitudeLabelView setShadowColor:[UIColor blackColor]];
    [aircraftAltitudeLabelView setShadowOffset:CGSizeMake(1, 1)];
    [self addSubview:aircraftAltitudeLabelView];
//
//    noCourseLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 500, 200)];
//    [noCourseLabel setText:@"NO COURSE"];
//    [noCourseLabel setBackgroundColor:[UIColor clearColor]];
//    [noCourseLabel setTextColor:[UIColor redColor]];
//    [noCourseLabel setFont:[UIFont boldSystemFontOfSize:80]];
//    [noCourseLabel sizeToFit];
//    [noCourseLabel setAutoresizingMask:UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleLeftMargin];
//    [self addSubview:noCourseLabel];

    [self setUserInteractionEnabled:YES];

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

    if (_path == nil)
        return;

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
            float elevation = (float) [globe elevationForLatitude:pos.latitude longitude:pos.longitude];
            ys[n++] = elevation >= 0 ? elevation : 0;
        }
    }
}

- (void) drawRect:(CGRect)rect
{
    @try
    {
        [self doDrawRect:rect];
    }
    @catch (NSException* exception)
    {
        DDLogError(@"drawRect for TerrainProfileView exception: %@", [exception reason]);
    }
}

- (void) doDrawRect:(CGRect)rect
{
    if (!_enabled)
        return;

    [self computeProfile];

    CGContextRef context = UIGraphicsGetCurrentContext();
    [[UIColor colorWithWhite:0.8 alpha:0.95] set];
    CGContextFillRect(context, rect);

//    [self showNoCourseSign:_path == nil rect:rect];
    if (_path == nil)
        return;

    if (numPoints < 2)
        return;

    CGRect frame = CGRectMake(0, 0, [self frame].size.width, [self frame].size.height);
    float graphYMax = frame.size.height - BOTTOM_MARGIN;

    float xMin = xs[0];
    float xMax = xs[numPoints - 1];
    float yMin = 0;
    float yMax = -FLT_MAX;
    float xAtYMax = xMin;

    for (int i = 0; i < numPoints; i++)
    {
//        if (ys[i] < yMin)
//            yMin = ys[i];
        if (ys[i] > yMax)
        {
            yMax = ys[i];
            xAtYMax = xs[i];
        }
    }

    double maxAltitude = 1.1 * fmax(yMax, _aircraftAltitude);

    float xRange = xMax - xMin;
    float yRange = (float) (maxAltitude - yMin);

    float firstY = graphYMax * (1 - (ys[0] - yMin) / yRange);

    CGContextBeginPath(context);
    CGContextMoveToPoint(context, 0, firstY);

    for (int i = 0; i < numPoints; i++)
    {
        float x = frame.size.width * (xs[i] - xMin) / xRange;
        float y = graphYMax * (1 - (ys[i] - yMin) / yRange);
        CGContextAddLineToPoint(context, x, y);
    }

    // Add the side and bottom edges of the graph.
    CGContextAddLineToPoint(context, frame.size.width, graphYMax); // right side
    CGContextAddLineToPoint(context, 0, graphYMax); // bottom
    CGContextAddLineToPoint(context, 0, firstY); // left side
    CGContextClosePath(context);

    CGContextSaveGState(context);
    CGContextClip(context);

    if (_dangerAltitude > yMax)
    {
        float y0 = 1.0 - (_warningAltitude - yMin) / yRange;
        float dy = (float) fmin(0.03, (1 - y0) / 2);
        CGFloat locations[3] = {1.0, y0 + dy, y0};
        CGGradientRef gradient = CGGradientCreateWithColorComponents(CGColorSpaceCreateDeviceRGB(), gradientColors, locations, 3);
        CGContextDrawLinearGradient(context, gradient, CGPointMake(0, 0), CGPointMake(0, graphYMax),
                kCGGradientDrawsBeforeStartLocation | kCGGradientDrawsAfterEndLocation);
        CGGradientRelease(gradient);
    }
    else
    {
        float y0 = 1.0 - (_warningAltitude - yMin) / yRange;
        float r0 = 1.0 - (_dangerAltitude - yMin) / yRange;
        float dy = (float) fmin(0.03, (1 - y0) / 2);
        float dr = (float) fmin(0.03, (y0 - r0) / 2);
        CGFloat locations[6] = {1.0, y0 + dy, y0, r0 + dr, r0, 0.0};
        CGGradientRef gradient = CGGradientCreateWithColorComponents(CGColorSpaceCreateDeviceRGB(), gradientColors, locations, 6);
        CGContextDrawLinearGradient(context, gradient, CGPointMake(0, 0), CGPointMake(0, graphYMax),
                kCGGradientDrawsBeforeStartLocation | kCGGradientDrawsAfterEndLocation);
        CGGradientRelease(gradient);
    }

    CGContextRestoreGState(context); // eliminate the clip path set above

    // Draw a line at the bottom of the profile to separate it from the simulator controls.
    [[UIColor blackColor] setStroke];
    CGContextBeginPath(context);
    CGContextMoveToPoint(context, 0, frame.size.height);
    CGContextAddLineToPoint(context, frame.size.width, frame.size.height);
    CGContextStrokePath(context);

    // Draw the horizontal axis.
    [[UIColor blackColor] setStroke];
    CGContextBeginPath(context);
    CGContextMoveToPoint(context, 0, graphYMax);
    CGContextAddLineToPoint(context, frame.size.width, graphYMax);
    CGContextStrokePath(context);

    // Show the aircraft altitude.
    float aircraftY = graphYMax * (1 - (_aircraftAltitude - yMin) / yRange);

    NSMutableDictionary* attrDict = [[NSMutableDictionary alloc] init];
    [attrDict setObject:[aircraftAltitudeLabelView font] forKey:NSFontAttributeName];
    NSString* displayString = [[TAIGA unitsFormatter] formatMetersAltitude:_aircraftAltitude];
    CGSize stringSize = [displayString sizeWithAttributes:attrDict];

    [aircraftAltitudeLabelView setFrame:CGRectMake(35, aircraftY - 0.8 * stringSize.height, 100, 30)];
    [aircraftAltitudeLabelView setText:displayString];

    // Show the aircraft altitude as a dashed line across the entire graph.
    [[UIColor blackColor] setStroke];
    CGContextBeginPath(context);
    CGContextMoveToPoint(context, TRI_HEIGHT + 5 + 1.2 * stringSize.width, aircraftY);
    CGContextAddLineToPoint(context, frame.size.width, aircraftY);
    CGFloat lengths[] = {4, 4};
    CGContextSetLineDash(context, 0, lengths, 2);
    CGContextStrokePath(context);
    CGContextSetLineDash(context, 0, nil, 0);

    // Show the aircraft as a filled triangle with outline.
    [[UIColor colorWithRed:.027 green:.596 blue:.976 alpha:1] setFill];
    CGContextBeginPath(context);
    CGContextMoveToPoint(context, TRI_HEIGHT, aircraftY);
    CGContextAddLineToPoint(context, 0, aircraftY - TRI_HALF_WIDTH);
    CGContextAddLineToPoint(context, 0, aircraftY + TRI_HALF_WIDTH);
    CGContextClosePath(context);
    CGContextFillPath(context);

    [[UIColor whiteColor] setStroke];
    CGContextBeginPath(context);
    CGContextMoveToPoint(context, TRI_HEIGHT, aircraftY);
    CGContextAddLineToPoint(context, 0, aircraftY - TRI_HALF_WIDTH);
    CGContextAddLineToPoint(context, 0, aircraftY + TRI_HALF_WIDTH);
    CGContextClosePath(context);
    CGContextStrokePath(context);

    // Update the text and positions of the labels.
    NSNumberFormatter* formatter = [[NSNumberFormatter alloc] init];
    [formatter setNumberStyle:NSNumberFormatterDecimalStyle];

//    numberString = [formatter stringFromNumber:[[NSNumber alloc] initWithFloat:ceilf(yMax * (float) TAIGA_METERS_TO_FEET)]];
    displayString = [[TAIGA unitsFormatter] formatMetersAltitude:yMax];
    stringSize = [displayString sizeWithAttributes:attrDict];
    float maxLabelX = frame.size.width * (xAtYMax - xMin) / xRange - 0.5 * stringSize.width;
    if (yMax <= 0)
        maxLabelX = stringSize.width;
    else if (maxLabelX < 0.5 * stringSize.width)
        maxLabelX = 0.5 * stringSize.width;
    else if (maxLabelX + stringSize.width > frame.size.width)
        maxLabelX = frame.size.width - stringSize.width;
    float maxLabelY = graphYMax * (1 - (yMax - yMin) / yRange);
    if (maxLabelY < 0)
        maxLabelY = 0;
    else if (maxLabelY + stringSize.height > graphYMax)
        maxLabelY = graphYMax - stringSize.height;
    [maxLabel setFrame:CGRectMake(maxLabelX, maxLabelY, stringSize.width, stringSize.height)];
    [maxLabel setText:displayString];

    [leftLabelView setText:_leftLabel];

    stringSize = [_centerLabel sizeWithAttributes:attrDict];
    [centerLabelView setFrame:CGRectMake(frame.size.width / 2 - stringSize.width / 2, AXIS_LABEL_Y, 200, 30)];
    [centerLabelView setText:_centerLabel];

    stringSize = [_rightLabel sizeWithAttributes:attrDict];
    [rightLabelView setFrame:CGRectMake(frame.size.width - stringSize.width, AXIS_LABEL_Y, 200, 30)];
    [rightLabelView setText:_rightLabel];
}

- (void) showNoCourseSign:(bool)yn rect:(CGRect)rect
{
    CGRect labelBounds = [noCourseLabel bounds];
    float labelX = rect.size.width / 2 - labelBounds.size.width / 2;
    [noCourseLabel setFrame:CGRectMake(labelX, 0, labelBounds.size.width, labelBounds.size.height)];
    [noCourseLabel setText:yn ? @"  No Course" : @""];

    [maxLabel setText:@""];
}
@end