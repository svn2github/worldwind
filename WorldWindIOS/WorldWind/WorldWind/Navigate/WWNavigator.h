/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.

 @version $Id$
 */

#import <Foundation/Foundation.h>
#import "WorldWind/Util/WWDisposable.h"

@protocol WWNavigatorState;
@class WWLocation;

static const NSTimeInterval WWNavigatorDurationAutomatic = DBL_MAX;

@protocol WWNavigator <NSObject, WWDisposable>

/// @name Navigator Attributes

@property (nonatomic) double heading;

@property (nonatomic) double tilt;

@property (nonatomic) double roll;

/// @name Getting a Navigator State Snapshot

- (id<WWNavigatorState>) currentState;

/// @name Setting the Location of Interest

- (void) setCenterLocation:(WWLocation*)location;

- (void) setCenterLocation:(WWLocation*)location radius:(double)radius;

/// @name Animating the Navigator

- (void) animateWithDuration:(NSTimeInterval)duration animations:(void (^)(void))animations;

- (void) animateWithDuration:(NSTimeInterval)duration animations:(void (^)(void))animations completion:(void (^)(BOOL finished))completion;

- (void) animateWithBlock:(void (^)(NSDate* timestamp, BOOL* stop))block;

- (void) animateWithBlock:(void (^)(NSDate* timestamp, BOOL* stop))block completion:(void (^)(BOOL finished))completion;

- (void) stopAnimations;

@end