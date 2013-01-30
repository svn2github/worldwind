/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.

 @version $Id$
 */

#import <Foundation/Foundation.h>

@protocol WWNavigatorState;
@class WWLocation;

/**
* TODO
*/
@protocol WWNavigator

/// @name Getting a Navigator State Snapshot

/**
* TODO
*
* @return TODO
*/
- (id<WWNavigatorState>) currentState;

/// @name Changing the Location of Interest

/**
* TODO
*
* @param location TODO
* @param duration TODO
*
* @exception TODO
*/
- (void) gotoLocation:(WWLocation*)location overDuration:(NSTimeInterval)duration;

/**
* TODO
*
* @param location TODO
* @param range TODO
* @param duration TODO
*
* @exception TODO
*/
- (void) gotoLocation:(WWLocation*)location fromRange:(double)range overDuration:(NSTimeInterval)duration;

/**
* TODO
*
* @param center TODO
* @param radius TODO
* @param duration TODO
*
* @exception TODO
*/
- (void) gotoRegionWithCenter:(WWLocation*)center radius:(double)radius overDuration:(NSTimeInterval)duration;

@end
