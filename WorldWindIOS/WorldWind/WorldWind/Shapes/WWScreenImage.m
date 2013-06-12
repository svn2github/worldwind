/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.

 @version $Id$
 */

#import <CoreGraphics/CoreGraphics.h>
#import "WorldWind/Shapes/WWScreenImage.h"
#import "WorldWind/Geometry/WWMatrix.h"
#import "WorldWind/Layer/WWLayer.h"
#import "WorldWind/Navigate/WWNavigatorState.h"
#import "WorldWind/Pick/WWPickedObject.h"
#import "WorldWind/Pick/WWPickSupport.h"
#import "WorldWind/Render/WWDrawContext.h"
#import "WorldWind/Render/WWGpuProgram.h"
#import "WorldWind/Render/WWTexture.h"
#import "WorldWind/Util/WWColor.h"
#import "WorldWind/Util/WWOffset.h"
#import "WorldWind/Util/WWResourceLoader.h"
#import "WorldWind/Util/WWSize.h"
#import "WorldWind/WorldWind.h"

@implementation WWScreenImage

//--------------------------------------------------------------------------------------------------------------------//
//-- Initializing Screen Images --//
//--------------------------------------------------------------------------------------------------------------------//

- (WWScreenImage*) initWithScreenOffset:(WWOffset*)screenOffset imagePath:(NSString*)imagePath
{
    self = [super init];

    _displayName = @"Screen Image";
    _enabled = YES;
    _screenOffset = screenOffset;
    _imagePath = imagePath;
    _imageColor = [[WWColor alloc] initWithR:1 g:1 b:1 a:1];
    _imageOffset = [[WWOffset alloc] initWithPixelsX:0 y:0];
    _imageSize = [[WWSize alloc] initWithOriginalSize];
    _eyeDistance = 0;

    // Rendering attributes.
    mvpMatrix = [[WWMatrix alloc] initWithIdentity];
    texCoordMatrix = [[WWMatrix alloc] initWithIdentity];
    color = [[WWColor alloc] init];

    // Picking attributes.
    pickSupport = [[WWPickSupport alloc] init];

    return self;
}

//--------------------------------------------------------------------------------------------------------------------//
//-- Drawing Renderables --//
//--------------------------------------------------------------------------------------------------------------------//

- (void) render:(WWDrawContext*)dc
{
    if (dc == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Draw context is nil")
    }

    if (!_enabled)
    {
        return;
    }

    if ([dc orderedRenderingMode])
    {
        [self drawOrderedRenderable:dc];

        if ([dc pickingMode])
        {
            [pickSupport resolvePick:dc layer:pickLayer];
        }
    }
    else
    {
        [self makeOrderedRenderable:dc];
    }
}

//--------------------------------------------------------------------------------------------------------------------//
//-- Methods of Interest Only to Subclasses --//
//--------------------------------------------------------------------------------------------------------------------//

- (void) makeOrderedRenderable:(WWDrawContext*)dc
{
    [self doMakeOrderedRenderable:dc];

    if ([dc pickingMode])
    {
        pickLayer = [dc currentLayer];
    }

    [dc addOrderedRenderable:self];
}

- (void) doMakeOrderedRenderable:(WWDrawContext*)dc
{
    CGSize vs = [[dc navigatorState] viewport].size;
    CGSize is;

    [self assembleActiveTexture:dc];
    if (texture != nil)
    {
        int iw = [texture imageWidth];
        int ih = [texture imageHeight];
        is = [_imageSize sizeForOriginalWidth:iw originalHeight:ih containerWidth:vs.width containerHeight:vs.height];
        [texCoordMatrix setToUnitYFlip];
    }
    else
    {
        is = [_imageSize sizeForOriginalWidth:0 originalHeight:0 containerWidth:vs.width containerHeight:vs.height];
        [texCoordMatrix setToIdentity];
    }

    CGPoint vo = [_screenOffset offsetForWidth:vs.width height:vs.height];
    CGPoint io = [_imageOffset offsetForWidth:is.width height:is.height];
    [mvpMatrix setToIdentity];
    [mvpMatrix multiplyMatrix:[dc screenProjection]];
    [mvpMatrix multiplyByTranslation:vo.x - io.x y:vo.y - io.y z:0];
    [mvpMatrix multiplyByScale:is.width y:is.height z:1];
}

- (void) assembleActiveTexture:(WWDrawContext*)dc
{
    if (_imagePath != nil)
    {
        texture = [[WorldWind resourceLoader] textureForImagePath:_imagePath cache:[dc gpuResourceCache]];
    }
    else
    {
        texture = nil;
    }
}

- (void) drawOrderedRenderable:(WWDrawContext*)dc
{
    [self beginDrawing:dc];

    @try
    {
        [self doDrawOrderedRenderable:dc];
    }
    @finally
    {
        [self endDrawing:dc];
    }
}

- (void) doDrawOrderedRenderable:(WWDrawContext*)dc
{
    WWGpuProgram* program = [dc currentProgram];

    [program loadUniformMatrix:@"mvpMatrix" matrix:mvpMatrix];
    [program loadUniformMatrix:@"texCoordMatrix" matrix:texCoordMatrix];

    if ([dc pickingMode])
    {
        unsigned int pickColor = [dc uniquePickColor];
        [pickSupport addPickableObject:[self createPickedObject:dc colorCode:pickColor]];
        [program loadUniformColorInt:@"color" color:pickColor];
        [program loadUniformBool:@"enableTexture" value:NO];
        [program loadUniformSampler:@"textureSampler" value:0];
    }
    else
    {
        [color setToColor:_imageColor];
        [color preMultiply];
        BOOL textureBound = [texture bind:dc]; // returns NO if activeTexture is nil
        [program loadUniformColor:@"color" color:color];
        [program loadUniformBool:@"enableTexture" value:textureBound];
        [program loadUniformSampler:@"textureSampler" value:0];
    }

    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
}

- (void) beginDrawing:(WWDrawContext*)dc
{
    // Bind the default texture program. This sets the program as the current OpenGL program and the current draw
    // context program.
    WWGpuProgram* program = [dc defaultTextureProgram];

    // Configure the GL shader's vertex attribute arrays to use the unit quad vertex buffer object as the source of
    // vertex point coordinates and vertex texture coordinate.
    glBindBuffer(GL_ARRAY_BUFFER, [dc unitQuadBuffer]);
    int location = [program getAttributeLocation:@"vertexPoint"];
    glEnableVertexAttribArray((GLuint) location);
    glVertexAttribPointer((GLuint) location, 2, GL_FLOAT, GL_FALSE, 0, 0);

    location = [program getAttributeLocation:@"vertexTexCoord"];
    glEnableVertexAttribArray((GLuint) location);
    glVertexAttribPointer((GLuint) location, 2, GL_FLOAT, GL_FALSE, 0, 0);

    // Configure the GL depth state to disable depth testing.
    glDisable(GL_DEPTH_TEST);
}

- (void) endDrawing:(WWDrawContext*)dc
{
    WWGpuProgram* program = [dc currentProgram];

    // Restore the GL shader's vertex attribute array state. This step must be performed before the GL program binding
    // is restored below.
    GLuint location = (GLuint) [program getAttributeLocation:@"vertexPoint"];
    glDisableVertexAttribArray(location);

    location = (GLuint) [program getAttributeLocation:@"vertexTexCoord"];
    glDisableVertexAttribArray(location);

    // Restore the GL program binding, buffer binding, texture binding, and depth state.
    glUseProgram(0);
    glBindBuffer(GL_ARRAY_BUFFER, 0);
    glBindTexture(GL_TEXTURE_2D, 0);
    glEnable(GL_DEPTH_TEST);
}

- (WWPickedObject*) createPickedObject:(WWDrawContext*)dc colorCode:(unsigned int)colorCode
{
    return [[WWPickedObject alloc] initWithColorCode:colorCode
                                          userObject:(_pickDelegate != nil ? _pickDelegate : self)
                                           pickPoint:[dc pickPoint]
                                            position:nil
                                           isTerrain:NO];
}

@end