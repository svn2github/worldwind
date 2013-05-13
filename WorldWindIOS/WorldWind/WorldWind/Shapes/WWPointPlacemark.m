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
#import "WorldWind/Terrain/WWTerrain.h"
#import "WorldWind/Util/WWColor.h"
#import "WorldWind/Util/WWGpuResourceCache.h"
#import "WorldWind/Util/WWMath.h"
#import "WorldWind/Util/WWOffset.h"
#import "WorldWind/Util/WWResourceLoader.h"
#import "WorldWind/WorldWind.h"
#import "WorldWind/WorldWindConstants.h"
#import "WorldWind/WWLog.h"

@implementation WWPointPlacemark

//--------------------------------------------------------------------------------------------------------------------//
//-- Initializing Point Placemarks --//
//--------------------------------------------------------------------------------------------------------------------//

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
    screenPoint = [[WWVec4 alloc] initWithZeroVector];
    screenOffset = [[WWVec4 alloc] initWithZeroVector];
    imageTransform = [[WWMatrix alloc] initWithIdentity];

    // Rendering support.
    mvpMatrix = [[WWMatrix alloc] initWithIdentity];
    color = [[WWColor alloc] init];
    pickSupport = [[WWPickSupport alloc] init];

    _displayName = @"Placemark";
    _highlighted = NO;
    _enabled = YES;
    _position = position;
    _altitudeMode = WW_ALTITUDE_MODE_ABSOLUTE;

    return self;
}

//--------------------------------------------------------------------------------------------------------------------//
//-- Renderable Interface --//
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
    if (CGRectIsEmpty(imageRect))
    {
        return;
    }

    if (![self intersectsFrustum:dc])
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
    [[dc terrain] surfacePointAtLatitude:[_position latitude]
                               longitude:[_position longitude]
                                  offset:[_position altitude]
                            altitudeMode:_altitudeMode
                                  result:placePoint];

    _eyeDistance = [[[dc navigatorState] eyePoint] distanceTo3:placePoint];

    if (![[dc navigatorState] project:placePoint result:screenPoint])
    {
        imageRect = CGRectMake(0, 0, 0, 0);
        return; // The place point is clipped by the near plane or the far plane.
    }

    if (activeTexture != nil)
    {
        double w = [activeTexture imageWidth];
        double h = [activeTexture imageHeight];
        double s = [activeAttributes imageScale];
        [screenOffset setToZeroVector];
        [[activeAttributes imageOffset] offsetForWidth:w height:h xScale:s yScale:s result:screenOffset];
        [imageTransform setToIdentity];
        [imageTransform setTranslation:[screenPoint x] - [screenOffset x] y:[screenPoint y] - [screenOffset y] z:[screenPoint z]];
        [imageTransform setScale:w * s y:h * s z:1];
    }
    else
    {
        double s = [activeAttributes imageScale];
        [screenOffset setToZeroVector];
        [[activeAttributes imageOffset] offsetForWidth:s height:s xScale:1 yScale:1 result:screenOffset];
        [imageTransform setTranslation:[screenPoint x] - [screenOffset x] y:[screenPoint y] - [screenOffset y] z:[screenPoint z]];
        [imageTransform setScale:s y:s z:1];
    }

    imageRect = [WWMath boundingRectForUnitQuad:imageTransform];
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

- (BOOL) intersectsFrustum:(WWDrawContext*)dc
{
    return CGRectIntersectsRect([[dc navigatorState] viewport], imageRect);
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

    [mvpMatrix setToMatrix:[dc screenProjection]];
    [mvpMatrix multiplyMatrix:imageTransform];
    [program loadUniformMatrix:@"mvpMatrix" matrix:mvpMatrix];

    if ([dc pickingMode])
    {
        unsigned int pickColor = [dc uniquePickColor];
        [pickSupport addPickableObject:[self createPickedObject:dc colorCode:pickColor]];
        [program loadUniformColorInt:@"color" color:pickColor];
        [program loadUniformBool:@"enableTexture" value:NO];
    }
    else
    {
        [color setToColor:[activeAttributes imageColor]];
        [color preMultiply];
        [program loadUniformColor:@"color" color:color];

        BOOL enableTexture = [activeTexture bind:dc]; // returns NO if activeTexture is nil
        [program loadUniformBool:@"enableTexture" value:enableTexture];
        [program loadUniformSampler:@"textureSampler" value:0];
    }

    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);

    if ([dc pickingMode])
    {
        [pickSupport resolvePick:dc layer:pickLayer];
    }
}

- (void) beginDrawing:(WWDrawContext*)dc
{
    // Bind the default texture program.
    WWGpuProgram* program = [dc defaultTextureProgram];

    // Bind the unit quad vertex buffer object.
    glBindBuffer(GL_ARRAY_BUFFER, [dc unitQuadBuffer]);

    // Configure the GL shader's vertex attribute arrays to use the unit quad vertex buffer object as the source of
    // vertex point coordinates and vertex texture coordinate.
    GLuint location = (GLuint) [program getAttributeLocation:@"vertexPoint"];
    glEnableVertexAttribArray(location);
    glVertexAttribPointer(location, 2, GL_FLOAT, GL_FALSE, 0, 0);

    location = (GLuint) [program getAttributeLocation:@"vertexTexCoord"];
    glEnableVertexAttribArray(location);
    glVertexAttribPointer(location, 2, GL_FLOAT, GL_FALSE, 0, 0);

    // Configure the GL depth state to suppress depth buffer writes.
    glDepthMask(GL_FALSE);
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

    // Restore the GL program binding, buffer binding and texture binding.
    glUseProgram(0);
    glBindBuffer(GL_ARRAY_BUFFER, 0);
    glBindTexture(GL_TEXTURE_2D, 0);

    // Restore the GL depth state.
    glDepthMask(GL_TRUE);
}

- (WWPickedObject*) createPickedObject:(WWDrawContext*)dc colorCode:(unsigned int)colorCode
{
    return [[WWPickedObject alloc] initWithColorCode:colorCode
                                          userObject:(_delegateOwner != nil ? _delegateOwner : self)
                                           pickPoint:[dc pickPoint]
                                            position:_position
                                           isTerrain:NO];
}

@end