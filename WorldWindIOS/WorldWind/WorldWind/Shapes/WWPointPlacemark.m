/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.

 @version $Id$
 */

#import "WorldWind/Shapes/WWPointPlacemark.h"
#import "WorldWind/Shapes/WWPointPlacemarkAttributes.h"
#import "WorldWind/Geometry/WWMatrix.h"
#import "WorldWind/Geometry/WWPosition.h"
#import "WorldWind/Geometry/WWVec4.h"
#import "WorldWind/Navigate/WWNavigatorState.h"
#import "WorldWind/Pick/WWPickedObject.h"
#import "WorldWind/Pick/WWPickSupport.h"
#import "WorldWind/Render/WWDrawContext.h"
#import "WorldWind/Render/WWGpuProgram.h"
#import "WorldWind/Render/WWTexture.h"
#import "WorldWind/Shaders/WWBasicTextureProgram.h"
#import "WorldWind/Terrain/WWTerrain.h"
#import "WorldWind/Util/WWColor.h"
#import "WorldWind/Util/WWGpuResourceCache.h"
#import "WorldWind/Util/WWMath.h"
#import "WorldWind/Util/WWOffset.h"
#import "WorldWind/Util/WWResourceLoader.h"
#import "WorldWind/WorldWind.h"

#define DEFAULT_DEPTH_OFFSET -0.01

// Temporary objects shared by all point placemarks and used during rendering.
static WWVec4* point;
static WWMatrix* matrix;
static WWPickSupport* pickSupport;
static WWTexture* currentTexture;

@implementation WWPointPlacemark

//--------------------------------------------------------------------------------------------------------------------//
//-- Initializing Point Placemarks --//
//--------------------------------------------------------------------------------------------------------------------//

+ (void) initialize
{
    static BOOL initialized = NO; // protects against erroneous explicit calls to this method
    if (!initialized)
    {
        initialized = YES;

        point = [[WWVec4 alloc] initWithZeroVector];
        matrix = [[WWMatrix alloc] initWithIdentity];
        pickSupport = [[WWPickSupport alloc] init];
    }
}

- (WWPointPlacemark*) initWithPosition:(WWPosition*)position
{
    if (position == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Position is nil")
    }

    self = [super init];

    // Placemark attributes.
    defaultAttributes = [[WWPointPlacemarkAttributes alloc] init];
    [self setDefaultAttributes];

    // Placemark geometry.
    placePoint = [[WWVec4 alloc] initWithZeroVector];
    imageTransform = [[WWMatrix alloc] initWithIdentity];
    texCoordMatrix = [[WWMatrix alloc] initWithIdentity];

    _displayName = @"Placemark";
    _highlighted = NO;
    _enabled = YES;
    _position = position;
    _altitudeMode = WW_ALTITUDE_MODE_ABSOLUTE;

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

- (void) setDefaultAttributes
{
    // Configure the default attributes to display a white 5x5 point centered on the placemark's position. We set only
    // imageScale since the remaining attributes default to appropriate values: imagePath=nil, imageColor=white and
    // imageOffset=center.
    [defaultAttributes setImageScale:5];
}

- (void) makeOrderedRenderable:(WWDrawContext*)dc
{
    [self determineActiveAttributes:dc];
    if (activeAttributes == nil)
    {
        return;
    }

    [self doMakeOrderedRenderable:dc];
    if (CGRectIsEmpty(imageBounds))
    {
        return;
    }

    if (![self isPlacemarkVisible:dc])
    {
        return;
    }

    if ([dc pickingMode])
    {
        pickLayer = [dc currentLayer];
    }

    [dc addOrderedRenderable:self];
}

- (void) doMakeOrderedRenderable:(WWDrawContext*)dc
{
    // Compute the placemark's model point and corresponding distance to the eye point.
    [[dc terrain] surfacePointAtLatitude:[_position latitude]
                               longitude:[_position longitude]
                                  offset:[_position altitude]
                            altitudeMode:_altitudeMode
                                  result:placePoint];

    _eyeDistance = [[[dc navigatorState] eyePoint] distanceTo3:placePoint];

    // Compute the placemark's screen point in the OpenGL coordinate system of the WorldWindow by projecting its model
    // coordinate point onto the viewport. Apply a depth offset in order to cause the placemark to appear above nearby
    // terrain. When a placemark is displayed near the terrain portions of its geometry are often behind the terrain,
    // yet as a screen element the placemark is expected to be visible. We adjust its depth values rather than moving
    // the placemark itself to avoid obscuring its actual position.
    if (![[dc navigatorState] project:placePoint result:point depthOffset:DEFAULT_DEPTH_OFFSET])
    {
        imageBounds = CGRectMake(0, 0, 0, 0);
        return; // The place point is clipped by the near plane or the far plane.
    }

    // Compute the placemark's transform matrix and texture coordinate matrix according to its screen point, image size,
    // image offset and image scale. The image offset is defined with its origin at the image's bottom-left corner and
    // axes that extend up and to the right from the origin point. When the placemark has no active texture the image
    // scale defines the image size and no other scaling is applied.
    if (activeTexture != nil)
    {
        double w = [activeTexture originalImageWidth];
        double h = [activeTexture originalImageHeight];
        double s = [activeAttributes imageScale];
        CGPoint offset = [[activeAttributes imageOffset] offsetForWidth:w height:h];
        [imageTransform setTranslation:[point x] - offset.x * s y:[point y] - offset.y * s z:[point z]];
        [imageTransform setScale:w * s y:h * s z:1];
        [texCoordMatrix setToIdentity];
        [texCoordMatrix multiplyByTextureTransform:activeTexture];
    }
    else
    {
        double s = [activeAttributes imageScale];
        CGPoint offset = [[activeAttributes imageOffset] offsetForWidth:s height:s];
        [imageTransform setTranslation:[point x] - offset.x y:[point y] - offset.y z:[point z]];
        [imageTransform setScale:s y:s z:1];
        [texCoordMatrix setToIdentity];
    }

    // Compute the rectangle bounding the placemark in the OpenGL coordinate system of the WorldWindow.
    imageBounds = [WWMath boundingRectForUnitQuad:imageTransform];
}

- (void) determineActiveAttributes:(WWDrawContext*)dc
{
    if (_highlighted && _highlightAttributes != nil)
    {
        activeAttributes = _highlightAttributes;
    }
    else if (_attributes != nil)
    {
        activeAttributes = _attributes;
    }
    else
    {
        activeAttributes = defaultAttributes;
    }

    NSString* imagePath = [activeAttributes imagePath];
    if (imagePath != nil)
    {
        activeTexture = [[WorldWind resourceLoader] textureForImagePath:imagePath cache:[dc gpuResourceCache]];
    }
    else
    {
        activeTexture = nil;
    }
}

- (BOOL) isPlacemarkVisible:(WWDrawContext*)dc
{
    CGRect viewport = [[dc navigatorState] viewport];

    if ([dc pickingMode])
    {
        // Convert the pick point from UIKit screen coordinates to OpenGL screen coordinates.
        WWVec4* glPickPoint = [[dc navigatorState] convertPointToViewport:[dc pickPoint]];
        CGPoint point = CGPointMake((CGFloat) [glPickPoint x], (CGFloat) [glPickPoint y]);
        return CGRectContainsPoint(imageBounds, point);
    }
    else
    {
        return CGRectIntersectsRect(imageBounds, viewport);
    }
}

- (void) drawOrderedRenderable:(WWDrawContext*)dc
{
    [self beginDrawing:dc];

    @try
    {
        [self doDrawOrderedRenderable:dc];
        [self doDrawBatchOrderedRenderables:dc];
    }
    @finally
    {
        [self endDrawing:dc];
    }
}

- (void) doDrawOrderedRenderable:(WWDrawContext*)dc;
{
    WWBasicTextureProgram* program = (WWBasicTextureProgram*) [dc currentProgram];

    [matrix setToMatrix:[dc screenProjection]];
    [matrix multiplyMatrix:imageTransform];
    [program loadModelviewProjection:matrix];
    [program loadTextureMatrix:texCoordMatrix];

    if ([dc pickingMode])
    {
        unsigned int color = [dc uniquePickColor];
        [pickSupport addPickableObject:[self createPickedObject:dc colorCode:color]];
        [program loadPickColor:color];
    }
    else
    {
        [program loadColor:[activeAttributes imageColor]];

        if (currentTexture != activeTexture) // avoid unnecessary texture state changes
        {
            BOOL textureBound = [activeTexture bind:dc]; // returns NO if activeTexture is nil or cannot be bound
            [program loadTextureEnabled:textureBound];
            currentTexture = activeTexture;
        }
    }

    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
}

- (void) doDrawBatchOrderedRenderables:(WWDrawContext*)dc
{
    // Draw any subsequent point placemarks in the ordered renderable queue, removing each from the queue as it's
    // processed. This avoids reduces the overhead of setting up and tearing down OpenGL state for each placemark.

    id <WWOrderedRenderable> or = nil;
    Class selfClass = [self class];

    while ((or = [dc peekOrderedRenderable]) != nil && [or isKindOfClass:selfClass])
    {
        [dc popOrderedRenderable]; // Remove it from the ordered renderable queue.

        @try
        {
            [(WWPointPlacemark*) or doDrawOrderedRenderable:dc];
        }
        @catch (NSException* exception)
        {
            NSString* msg = [NSString stringWithFormat:@"rendering shape"];
            WWLogE(msg, exception);
            // Keep going. Render the rest of the ordered renderables.
        }
    }
}

- (void) beginDrawing:(WWDrawContext*)dc
{
    // Bind the default texture program. This sets the program as the current OpenGL program and the current draw
    // context program.
    WWBasicTextureProgram* program = (WWBasicTextureProgram*) [dc defaultTextureProgram];

    // Configure the GL shader's vertex attribute arrays to use the unit quad vertex buffer object as the source of
    // vertex point coordinates and vertex texture coordinate.
    glBindBuffer(GL_ARRAY_BUFFER, [dc unitQuadBuffer]);
    glVertexAttribPointer([program vertexPointLocation], 2, GL_FLOAT, GL_FALSE, 0, 0);
    glVertexAttribPointer([program vertexTexCoordLocation], 2, GL_FLOAT, GL_FALSE, 0, 0);

    // Disable texturing when in picking mode. This uniform variable does not change during the program's execution over
    // multiple point placemarks.
    if ([dc pickingMode])
    {
        [program loadTextureEnabled:NO];
    }

    // Configure the GL depth state to suppress depth buffer writes.
    glDepthMask(GL_FALSE);

    // Clear the current texture reference. This ensures that the first texture used by a placemark is bound.
    currentTexture = nil;
}

- (void) endDrawing:(WWDrawContext*)dc
{
    // Restore the GL program binding, buffer binding, texture binding, and depth state.
    [dc setCurrentProgram:nil];
    glUseProgram(0);
    glBindBuffer(GL_ARRAY_BUFFER, 0);
    glBindTexture(GL_TEXTURE_2D, 0);
    glDepthMask(GL_TRUE);

    // Avoid keeping a dangling reference to the current texture.
    currentTexture = nil;
}

- (WWPickedObject*) createPickedObject:(WWDrawContext*)dc colorCode:(unsigned int)colorCode
{
    return [[WWPickedObject alloc] initWithColorCode:colorCode
                                          userObject:(_pickDelegate != nil ? _pickDelegate : self)
                                           pickPoint:[dc pickPoint]
                                            position:_position
                                           isTerrain:NO];
}

@end