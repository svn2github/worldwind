/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import <Foundation/Foundation.h>

@class WWWMSDimensionedLayer;

/**
* Provides a controller to scroll through the dimensions of a WMS dimensioned layer.
*/
@interface DimensionedLayerController : UISlider
{
    UILabel* dimensionLabel;
}

@property (nonatomic) WWWMSDimensionedLayer* wmsLayer;

- (DimensionedLayerController*) initWithLayer:(WWWMSDimensionedLayer*)layer frame:(CGRect)frame;

@end