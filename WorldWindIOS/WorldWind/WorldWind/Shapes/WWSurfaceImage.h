/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import <Foundation/Foundation.h>
#import "WorldWind/Render/WWSurfaceTile.h"
#import "WorldWind/Render/WWRenderable.h"

@class WWDrawContext;


@interface WWSurfaceImage : NSObject <WWSurfaceTile, WWRenderable>

@property (nonatomic) WWSector* sector;

- (WWSurfaceImage*) init;

@end