/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import <Foundation/Foundation.h>
#import "WorldWindViewDelegate.h"

@class WorldWindView;


@interface ScaleBarView : UIView <WorldWindViewDelegate>

- (ScaleBarView*) initWithFrame:(CGRect)frame worldWindView:(WorldWindView*)worldWindView;

@end