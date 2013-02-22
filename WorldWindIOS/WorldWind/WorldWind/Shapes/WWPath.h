/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import <Foundation/Foundation.h>
#import "WWAbstractShape.h"

@class WWPosition;

/**
* Displays a line or curve between specified positions.
*
* The path is drawn between input positions to achieve a specified path type, one of WW_GREAT_CIRCLE, WW_RHUMB or
* WW_LINEAR. It can also conform to the underlying terrain.
*
* Altitudes within the path's positions are interpreted according to the path's altitude mode. If the altitude mode is
* WW_ALTITUDE_MODE_ABSOLUTE the default, the altitudes are considered as height above the ellipsoid. If the altitude
* mode is WW_ALTITUDE_MODE_RELATIVE_TO_GROUND the altitudes are added to the elevation of the terrain at the position.
* If the altitude mode is WW_ALTITUDE_MODE_CLAMP_TO_GROUND the altitudes are ignored and the path is drawn on the
* terrain at that point.
*
* Between the specified positions the path is drawn along a curve specified by the path's path type, either
* WW_GREAT_CIRCLE, WW_RHUMB or WW_LINEAR. When the path type is WW_LINEAR the path conforms to terrain only if the
* follow-terrain property is true. Otherwise the path positions are connected by straight lines.
*
* The terrain conformance of WW_GREAT_CIRCLE and WW_RHUMB paths is determined by the path's follow-terrain and
* terrain-conformance properties. When the follow-terrain property is YES, the path segments -- the path
* portions between the specified positions -- follow the shape of the terrain, otherwise they do not. When following
* terrain, the terrain-conformance property governs the precision of conformance and the number of intermediate
* positions generated between the specified positions.
*
* If the follow-terrain property is NO, the number of intermediate positions generated between the specified
* positions is specified by the number-of-subsegments property, which defaults to 10 subsegments.
*
* Paths have separate attributes for normal display and highlighted display. If no attributes are specified, default
* attributes are used.
*/
@interface WWPath : WWAbstractShape
{
@protected
    int numPoints; // the number of tessellated points
    float* points; // the tessellated points
}

/// @name Path Attributes

/// This path's positions. My not be nil.
@property (nonatomic) NSArray* positions;

/// The path type, either WW_GREAT_CIRCLE, WW_RHUMB or WW_LINEAR. May not be nil.
@property (nonatomic) NSString* pathType;

/// Indicates whether the path's segments conform to the terrain.
@property (nonatomic) BOOL followTerrain;

/// Specifies how accurately this path must adhere to the terrain when the path is terrain following. The value
/// specifies the maximum number of pixel between tessellation points. Lower values increase accuracy but decrease
/// performance. The default is 10.
@property (nonatomic) double terrainConformance;

/// Specifies the number of generated positions used between specified positions to achieve the path's path type.
/// Higher values cause the path to conform more closely to the path type but decrease performance. The default is 10.
/// Must be a positive number greater or equal to 0.
@property (nonatomic) int numSubsegments;

/// Specifies whether to extrude a curtain from the path to the terrain. The curtain uses this path's interior
/// attributes.
@property (nonatomic) BOOL extrude;

/// @name Initializing Paths

/**
* Initialize a path with specified positions.
*
* @param positions The path's positions.
*
* @return This path initialized with the specified positions.
*
* @exception NSInvalidArgumentException If the specified positions array is nil.
*/
- (WWPath*) initWithPositions:(NSArray*)positions;

@end