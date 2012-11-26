/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration.
 All Rights Reserved.
 
 * @version $Id$
 */

#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>
#import <OpenGLES/ES2/gl.h>
#import "WorldWind/WorldWind.h"


@interface WWSceneController : NSObject
{
@protected
    GLuint program;
}

- (void) render:(CGRect) bounds;

- (void) dispose;
@end