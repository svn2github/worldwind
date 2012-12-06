/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import <OpenGLES/ES2/gl.h>

@class WWSceneController;

@interface WorldWindView : UIView

@property (readonly, nonatomic) GLuint frameBuffer;
@property (readonly, nonatomic) GLuint renderBuffer;
@property (readonly, nonatomic) GLuint depthBuffer;
@property (readonly, nonatomic, strong) EAGLContext* context;
@property (readonly, nonatomic, strong) WWSceneController* sceneController;

- (void) drawView;
- (void) tearDownGL;

@end