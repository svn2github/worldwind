/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.

 @version $Id$
 */

#import <Foundation/Foundation.h>
#import "WorldWind/Layer/WWLayer.h"

@class WWGpuProgram;
@class WWDrawContext;

@interface WWShowTessellationLayer : WWLayer

@property (readonly, nonatomic) WWGpuProgram* gpuProgram;

- (void) beginRendering:(WWDrawContext*)dc;
- (void) endRendering:(WWDrawContext*)dc;
- (void) makeGpuProgram;

@end