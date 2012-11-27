/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */


#import <WorldWind/WorldWind.h>
#import <WorldWind/Render/WWSceneController.h>
#import <UIKit/UIKit.h>


@interface WorldWindView : UIView

@property (readonly, nonatomic) GLuint frameBuffer;
@property (readonly, nonatomic) GLuint renderBuffer;
@property (readonly, nonatomic) GLuint depthBuffer;
@property (readonly, nonatomic, strong) EAGLContext* context;
@property (readonly, nonatomic, strong) WWSceneController* sceneController;

- (void) drawView;

@end