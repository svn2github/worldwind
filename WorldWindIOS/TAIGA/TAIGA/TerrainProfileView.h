/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import <Foundation/Foundation.h>
#import "WorldWindViewDelegate.h"

@class WorldWindView;

@interface TerrainProfileView : UIView

@property (nonatomic) float warningAltitude;
@property (nonatomic) float dangerAltitude;

- (TerrainProfileView*) initWithFrame:(CGRect)frame;

- (void) setValues:(int)count xValues:(float*)xValues yValues:(float*)yValues;

@end