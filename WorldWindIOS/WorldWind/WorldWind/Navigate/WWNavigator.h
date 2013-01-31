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
* @param animate TODO
*
* @exception TODO
*/
- (void) gotoLocation:(WWLocation*)location animate:(BOOL)animate;

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
* @param distance TODO
* @param animate TODO
*
* @exception TODO
*/
- (void) gotoLocation:(WWLocation*)location fromDistance:(double)distance animate:(BOOL)animate;

/**
* TODO
*
* @param location TODO
* @param distance TODO
* @param duration TODO
*
* @exception TODO
*/
- (void) gotoLocation:(WWLocation*)location fromDistance:(double)distance overDuration:(NSTimeInterval)duration;

/**
* TODO
*
* @param center TODO
* @param radius TODO
* @param animate TODO
*
* @exception TODO
*/
- (void) gotoRegionWithCenter:(WWLocation*)center radius:(double)radius animate:(BOOL)animate;

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