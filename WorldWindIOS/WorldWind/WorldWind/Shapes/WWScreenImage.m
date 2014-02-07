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
#import "WorldWind/Shaders/WWBasicTextureProgram.h"
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
            [pickSupport resolvePick:dc];
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

    layer = [dc currentLayer];

    [dc addOrderedRenderable:self];
}

- (void) doMakeOrderedRenderable:(WWDrawContext*)dc
{
    CGSize vs = [[dc navigatorState] viewport].size;
    CGSize is;

    [self assembleActiveTexture:dc];
    if (texture != nil)
    {
        double w = [texture originalImageWidth];
        double h = [texture originalImageHeight];
        is = [_imageSize sizeForOriginalWidth:w originalHeight:h containerWidth:vs.width containerHeight:vs.height];
        [texCoordMatrix setToIdentity];
        [texCoordMatrix multiplyByTextureTransform:texture];
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

    [mvpMatrix multiplyByTranslation:0.5 y:0.5 z:0.5];
    [mvpMatrix multiplyByRotationAxis:1 y:0 z:0 angleDegrees:_imageTilt];
    [mvpMatrix multiplyByRotationAxis:0 y:0 z:1 angleDegrees:_imageRotation];
    [mvpMatrix multiplyByTranslation:-0.5 y:-0.5 z:0];
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
        // Draw the screen image quad only if there is a texture available or, in order to support KML, no image path
        // was specified so the user wants a solid color screen overlay.
        if (texture != nil || _imagePath == nil)
            [self doDrawOrderedRenderable:dc];
    }
    @finally
    {
        [self endDrawing:dc];
    }
}

- (void) doDrawOrderedRenderable:(WWDrawContext*)dc
{
    WWBasicTextureProgram* program = (WWBasicTextureProgram*) [dc currentProgram];
    [program loadModelviewProjection:mvpMatrix];
    [program loadTextureMatrix:texCoordMatrix];

    if ([dc pickingMode])
    {
        unsigned int color = [dc uniquePickColor];
        [pickSupport addPickableObject:[self createPickedObject:dc colorCode:color]];
        [program loadPickColor:color];
        [program loadTextureEnabled:NO];
        [program loadTextureUnit:GL_TEXTURE0];
    }
    else
    {
        BOOL textureBound = [texture bind:dc]; // returns NO if activeTexture is nil
        [program loadColor:_imageColor];
        [program loadOpacity:[layer opacity]];
        [program loadTextureEnabled:textureBound];
        [program loadTextureUnit:GL_TEXTURE0];
    }

    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
}

- (void) beginDrawing:(WWDrawContext*)dc
{
    // Bind the basic texture program. This sets the program as the current OpenGL program and the current draw
    // context's program.
    [dc bindProgramForKey:[WWBasicTextureProgram programKey] class:[WWBasicTextureProgram class]];

    // Configure the GL shader's vertex attribute arrays to use the unit quad vertex buffer object as the source of
    // vertex point coordinates and vertex texture coordinate.
    WWBasicTextureProgram* program = (WWBasicTextureProgram*) [dc currentProgram];
    glBindBuffer(GL_ARRAY_BUFFER, [dc unitQuadBuffer]);
    glVertexAttribPointer([program vertexPointLocation], 2, GL_FLOAT, GL_FALSE, 0, 0);
    glVertexAttribPointer([program vertexTexCoordLocation], 2, GL_FLOAT, GL_FALSE, 0, 0);
    glEnableVertexAttribArray([program vertexPointLocation]);
    glEnableVertexAttribArray([program vertexTexCoordLocation]);

    // Configure the GL depth state to disable depth testing.
    glDisable(GL_DEPTH_TEST);
}

- (void) endDrawing:(WWDrawContext*)dc
{
    // Restore the global OpenGL vertex attribute array state. This step must be performed before the GL program binding
    // is restored below in order to access the vertex attribute array indices from the current program.
    WWBasicTextureProgram* program = (WWBasicTextureProgram*) [dc currentProgram];
    glDisableVertexAttribArray([program vertexPointLocation]);
    glDisableVertexAttribArray([program vertexTexCoordLocation]);

    // Restore the GL program binding, buffer binding, texture binding, and depth state.
    [dc bindProgram:nil];
    glBindBuffer(GL_ARRAY_BUFFER, 0);
    glBindTexture(GL_TEXTURE_2D, 0);
    glEnable(GL_DEPTH_TEST);
}

- (WWPickedObject*) createPickedObject:(WWDrawContext*)dc colorCode:(unsigned int)colorCode
{
    return [[WWPickedObject alloc] initWithColorCode:colorCode
                                           pickPoint:[dc pickPoint]
                                          userObject:(_pickDelegate != nil ? _pickDelegate : self)
                                            position:nil
                                         parentLayer:layer];
}

@end