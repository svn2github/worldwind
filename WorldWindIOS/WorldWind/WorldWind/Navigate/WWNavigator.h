/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.

 @version $Id$
 */

#import <Foundation/Foundation.h>

@protocol WWNavigatorState;
@class WWLocation;

static const NSTimeInterval WWNavigatorDurationDefault = DBL_MAX;

@protocol WWNavigator

/// @name Getting a Navigator State Snapshot

- (id<WWNavigatorState>) currentState;

/// @name Animating to a Location of Interest

- (void) gotoLocation:(WWLocation*)location overDuration:(NSTimeInterval)duration;

- (void) gotoLookAt:(WWLocation*)lookAt range:(double)range overDuration:(NSTimeInterval)duration;

- (void) gotoRegionWithCenter:(WWLocation*)center radius:(double)radius overDuration:(NSTimeInterval)duration;

@end