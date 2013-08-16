/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import "DimensionedLayerController.h"
#import "WWWMSDimensionedLayer.h"
#import "WorldWindConstants.h"

@implementation DimensionedLayerController

- (DimensionedLayerController*) initWithLayer:(WWWMSDimensionedLayer*)layer frame:(CGRect)frame
{
    self = [super initWithFrame:frame];

    _wmsLayer = layer;

    [self setMinimumValue:0];
    [self setMaximumValue:[layer layerCount] - 1];

    [self addTarget:self action:@selector(sliderValueChanged:) forControlEvents:UIControlEventValueChanged];

    return self;
}

- (void) sliderValueChanged:(UISlider*)slider
{
    NSUInteger value = (NSUInteger)[slider value];
    [_wmsLayer setEnabledLayerNumber:value];

    NSNotification* redrawNotification = [NSNotification notificationWithName:WW_REQUEST_REDRAW object:self];
    [[NSNotificationCenter defaultCenter] postNotification:redrawNotification];
}

@end