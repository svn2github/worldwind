/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import <Foundation/Foundation.h>

@class WWDrawContext;

@protocol WWOutlinedShape

- (BOOL) isDrawOutline:(WWDrawContext*)dc;

- (BOOL) isDrawInterior:(WWDrawContext*)dc;

- (void) drawOutline:(WWDrawContext*)dc;

- (void) drawInterior:(WWDrawContext*)dc;

- (BOOL) isEnableDepthOffset:(WWDrawContext*)dc;

- (float) depthOffsetFactor:(WWDrawContext*)dc;

- (float) depthOffsetUnits:(WWDrawContext*)dc;

@end