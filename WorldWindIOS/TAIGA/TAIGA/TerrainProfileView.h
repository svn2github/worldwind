/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import <Foundation/Foundation.h>
#import "WorldWindViewDelegate.h"

@class WorldWindView;

@interface TerrainProfileView : UIView <WorldWindViewDelegate>

@property (nonatomic) WorldWindView* wwv;
@property (nonatomic, readonly) float warningAltitude;
@property (nonatomic, readonly) float dangerAltitude;
//@property (nonatomic) CGPoint aircraftLocation;
@property (nonatomic) NSArray* path;
@property (nonatomic) float opacity;

- (TerrainProfileView*) initWithFrame:(CGRect)frame worldWindView:(WorldWindView*)worldWindView;

- (void) setWarningAltitude:(float)warningAltitude dangerAltitude:(float)dangerAltitude;

@end