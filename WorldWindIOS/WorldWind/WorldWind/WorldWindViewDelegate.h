/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import <Foundation/Foundation.h>

@class WorldWindView;

/**
* Provides entry points for application involvement in World Wind View operations. All methods are optional.
*/
@protocol WorldWindViewDelegate <NSObject>

@optional // all methods are optional

/**
* Called just prior to the view's drawing itself. The OpenGL context is not yet current but frame statistics
* gathering has begun.
*
* @param worldWindView The World Wind View calling the method.
*/
- (void) viewWillDraw:(WorldWindView*)worldWindView;

/**
* Called just after the view draws itself. The OpenGL context is not current but frame statistics gathering is still
* active.
*
* @param worldWindView The World Wind View calling the method.
*/
- (void) viewDidDraw:(WorldWindView*)worldWindView;

@end