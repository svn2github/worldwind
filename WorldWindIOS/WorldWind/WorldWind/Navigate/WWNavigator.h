/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.

 @version $Id$
 */

#import <Foundation/Foundation.h>
#import "WorldWind/Util/WWDisposable.h"

@protocol WWNavigatorState;
@class WorldWindView;
@class WWPosition;

static const NSTimeInterval WWNavigatorDurationDefault = DBL_MAX;

@protocol WWNavigator <NSObject, WWDisposable>

/// @name Navigator Attributes

@property (nonatomic) double heading;

@property (nonatomic) double tilt;

@property (nonatomic) double roll;

/// @name Getting a Navigator State Snapshot

- (id<WWNavigatorState>) currentState;

/// @name Setting the Location of Interest

- (void) setToPosition:(WWPosition*)position;

- (void) setToRegionWithCenter:(WWPosition*)center radius:(double)radius;

- (void) animateToPosition:(WWPosition*)position overDuration:(NSTimeInterval)duration;

- (void) animateToRegionWithCenter:(WWPosition*)center radius:(double)radius overDuration:(NSTimeInterval)duration;

@end