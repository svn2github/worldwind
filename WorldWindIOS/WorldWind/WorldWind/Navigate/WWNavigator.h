/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.

 @version $Id$
 */

#import <Foundation/Foundation.h>

@protocol WWNavigatorState;
@class WWLocation;

@protocol WWNavigator

- (void) gotoLocation:(WWLocation*)location overDuration:(NSTimeInterval)duration;

- (void) gotoLocation:(WWLocation*)location fromRange:(double)range overDuration:(NSTimeInterval)duration;

- (void) gotoRegionWithCenter:(WWLocation*)center radius:(double)radius overDuration:(NSTimeInterval)duration;

- (id<WWNavigatorState>) currentState;

@end
