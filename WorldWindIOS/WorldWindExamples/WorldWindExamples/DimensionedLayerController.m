/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import "DimensionedLayerController.h"
#import "WorldWind/Layer/WWWMSDimensionedLayer.h"
#import "WorldWind/WorldWindConstants.h"
#import "WorldWind/Layer/WWWMSTiledImageLayer.h"

@implementation DimensionedLayerController

- (DimensionedLayerController*) initWithLayer:(WWWMSDimensionedLayer*)layer frame:(CGRect)frame
{
    self = [super initWithFrame:frame];

    [self addTarget:self action:@selector(sliderValueChanged:) forControlEvents:UIControlEventValueChanged];

    [self setWmsLayer:layer];

    return self;
}

- (void) setWmsLayer:(WWWMSDimensionedLayer*)wmsLayer
{
    _wmsLayer = wmsLayer;

    [self setMinimumValue:0];
    [self setMaximumValue:[_wmsLayer dimensionCount] - 1];

    int enabledLayerNumber = [_wmsLayer enabledDimensionNumber];
    if (enabledLayerNumber >= 0)
        [self setValue:enabledLayerNumber];
    else
        [self setValue:0];

    [self adjustLabel];
}

- (void) sliderValueChanged:(UISlider*)slider
{
    NSUInteger value = (NSUInteger) [slider value];
    [_wmsLayer setEnabledDimensionNumber:value];
    [self adjustLabel];

    NSNotification* redrawNotification = [NSNotification notificationWithName:WW_REQUEST_REDRAW object:self];
    [[NSNotificationCenter defaultCenter] postNotification:redrawNotification];
}

- (void) adjustLabel
{
    NSUInteger value = (NSUInteger) [self value];

    CGRect sliderFrame = [self frame];
    CGRect labelFrame;
    labelFrame.size.width = 400;
    labelFrame.size.height = 40;
    labelFrame.origin.x = sliderFrame.size.width * value / [_wmsLayer dimensionCount];
    labelFrame.origin.x -= 0.5 * labelFrame.size.width;
    labelFrame.origin.y = -20;

    if (dimensionLabel == nil)
    {
        dimensionLabel = [[UILabel alloc] initWithFrame:labelFrame];
        [dimensionLabel setBackgroundColor:[UIColor clearColor]];
        [dimensionLabel setTextColor:[UIColor whiteColor]];
        [dimensionLabel setTextAlignment:NSTextAlignmentCenter];
        [self addSubview:dimensionLabel];
    }

    [dimensionLabel setFrame:labelFrame];
    int enabledLayerNumber = [_wmsLayer enabledDimensionNumber];
    if (enabledLayerNumber >= 0)
        [dimensionLabel setText:[[_wmsLayer enabledLayer] displayName]];
    else
        [dimensionLabel setText:@""];
}

@end