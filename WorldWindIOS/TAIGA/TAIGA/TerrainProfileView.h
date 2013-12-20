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
@property (nonatomic) BOOL enabled;
@property (nonatomic, readonly) float warningAltitude;
@property (nonatomic, readonly) float dangerAltitude;
@property (nonatomic) float maxAltitude;
@property (nonatomic) float aircraftAltitude;
@property (nonatomic) NSArray* path;
@property (nonatomic) NSString* leftLabel;
@property (nonatomic) NSString* centerLabel;
@property (nonatomic) NSString* rightLabel;
@property (nonatomic) float opacity;

- (TerrainProfileView*) initWithFrame:(CGRect)frame worldWindView:(WorldWindView*)worldWindView;

- (void) setWarningAltitude:(float)warningAltitude dangerAltitude:(float)dangerAltitude;

@end