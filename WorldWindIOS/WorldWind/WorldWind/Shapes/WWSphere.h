/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import <Foundation/Foundation.h>
#import "WorldWind/Shapes/WWAbstractShape.h"

@class WWPosition;
@class WWDrawContext;

/**
* Displays a sphere of a specified radius at a specified position. The radius may be specified in either meters or
* pixels.
*
* The sphere's altitude is interpreted according to the sphere's altitude mode. If the altitude mode is
* WW_ALTITUDE_MODE_ABSOLUTE, the default, the altitude is considered as the height above the ellipsoid. If the
* altitude mode is WW_ALTITUDE_MODE_RELATIVE_TO_GROUND, the altitude is added to the elevation of the terrain at the
* sphere's position. If the altitude mode is WW_ALTITUDE_MODE_CLAMP_TO_GROUND, the specified altitude is ignored and
* the sphere is drawn with its center on the terrain.
*
* Spheres have separate attributes for normal display and highlighted display. If no attributes are specified, default
* attributes are used. Spheres do not have an outline, only an interior, so outline attributes are ignored.
*/
@interface WWSphere : WWAbstractShape
{
@protected
    BOOL radiusIsPixels; // indicates whether the radius was specified in pixels
    double radiusInMeters; // The radius used to draw the sphere, in meters
    NSString* verticesVboCacheKey; // the cache key for the VBO of vertices
    NSString* indicesVboCacheKey; // the cache key for the VBO of indices
}

/// @name Sphere Attributes

/// This sphere's center position.
@property(nonatomic) WWPosition* position;

/// This sphere's radius. Use isRadiusInPixels to determine whether the value is in pixels rather than meters.
@property(nonatomic) double radius;

/// This sphere's minimum radius in meters. Limits the sphere's radius when the value is in pixels.
@property (nonatomic) double minRadius;

/// This sphere's maximum radius in meters. Limits the sphere's radius when the value is in pixels.
@property (nonatomic) double maxRadius;

/// Indicates whether the radius was specified in pixels rather than meters.
- (BOOL) isRadiusInPixels;

/// @name Initializing Spheres

/**
*  Initialize this sphere with a specified position and a radius in meters.
*
*  @param position The sphere's center position.
*  @param radius The sphere's radius in meters.
*
*  @return This sphere initialized to the specified position and radius in meters.
*
*  @exception NSInvalidArgumentException If the specified position is nil or the radius is less than or equal to 0.
*/
- (WWSphere*) initWithPosition:(WWPosition*)position radius:(double)radius;

/**
*  Initialize this sphere with a specified position and a radius in pixels.
*
*  @param position The sphere's center position.
*  @param radius The sphere's radius in pixels.
*
*  @return This sphere initialized to the specified position and radius in pixels.
*
*  @exception NSInvalidArgumentException If the specified position is nil or the radius is less than or equal to 0.
*/
- (WWSphere*) initWithPosition:(WWPosition*)position radiusInPixels:(double)radius;

/**
*  Initialize this sphere with a specified position, a radius in pixels, and a minimum/maximum radius in meters.
*
*  @param position The sphere's center position.
*  @param radius The sphere's radius in pixels.
*  @param minRadius The sphere's minimum radius in meters.
*  @param maxRadius The sphere's maximum radius in meters.
*
*  @return This sphere initialized to the specified position, radius in pixels, and minimum/maximum radius in meters.
*
*  @exception NSInvalidArgumentException If the specified position is nil if the radius is less than or equal to 0,
*  if the minimum radius is less than 0, or if the maximum radius is less than or equal to 0.
*/
- (WWSphere*) initWithPosition:(WWPosition*)position radiusInPixels:(double)radius minRadius:(double)minRadius maxRadius:(double)maxRadius;

/// @name Methods of Interest Only to Subclasses

/**
* Creates the vertices and tri-strip indices for a unit sphere.
*
* The vertices and indices are stored in their respective VBOs.
*
* @param dc The current draw context.
*/
- (void) tessellateSphere:(WWDrawContext*)dc;

@end