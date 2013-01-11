/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import <OpenGLES/ES2/gl.h>

@class WWSceneController;
@protocol WWNavigator;

@interface WorldWindView : UIView

@property (readonly, nonatomic) GLuint frameBuffer;
@property (readonly, nonatomic) GLuint colorBuffer;
@property (readonly, nonatomic) GLuint depthBuffer;
@property (readonly, nonatomic) CGRect viewport;
@property (readonly, nonatomic, strong) EAGLContext* context;
@property (readonly, nonatomic, strong) WWSceneController* sceneController;
@property (readonly, nonatomic, strong) id<WWNavigator> navigator;

- (void) drawView;
- (void) tearDownGL;
- (void) handleNotification:(NSNotification*)notification;

@end