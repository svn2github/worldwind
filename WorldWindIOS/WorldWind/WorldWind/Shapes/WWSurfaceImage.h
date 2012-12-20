/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import <Foundation/Foundation.h>
#import "WorldWind/Render/WWSurfaceTile.h"
#import "WorldWind/Render/WWRenderable.h"

@class WWDrawContext;
@class WWTexture;

@interface WWSurfaceImage : NSObject <WWSurfaceTile, WWRenderable>

@property (readonly, nonatomic) WWSector* sector;
@property (readonly, nonatomic) NSString* imagePath;

- (WWSurfaceImage*) initWithImagePath:(WWSector*)sector imagePath:(NSString*)imagePath;

@end