/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import "WorldWind/Shapes/WWPath.h"
#import "WorldWind/Geometry/WWPosition.h"
#import "WorldWind/WWLog.h"
#import "WorldWind/WorldWindConstants.h"
#import "WorldWind/Render/WWDrawContext.h"
#import "WorldWind/Terrain/WWTerrain.h"
#import "WorldWind/Navigate/WWNavigatorState.h"
#import "WorldWind/Geometry/WWMatrix.h"
#import "WorldWind/Geometry/WWVec4.h"
#import "WorldWind/Terrain/WWGlobe.h"
#import "WorldWind/Geometry/WWBoundingBox.h"
#import "WorldWind/Render/WWGpuProgram.h"
#import "WorldWind/Shapes/WWShapeAttributes.h"
#import "WorldWind/Util/WWMath.h"

// TODO: Draw pole positions as vertical lines.
// TODO: Don't redraw each frame.

@implementation WWPath

- (WWPath*) initWithPositions:(NSArray*)positions
{
    if (positions == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Positions array is nil")
    }

    self = [super init];

    _positions = positions;

    _pathType = WW_LINEAR;
    _terrainConformance = 10;
    _numSubsegments = 10;

    [self setReferencePosition:[positions count] < 1 ? nil : [positions objectAtIndex:0]];

    return self;
}

- (void) dealloc
{
    if (points != nil)
    {
        free(points);
    }
}

- (void) reset
{
    if (points != nil)
    {
        free(points);
        points = nil;
    }

    numPoints = 0;
}

- (void) setDefaultAttributes
{
    [super setDefaultAttributes];

    [defaultAttributes setInteriorEnabled:NO];
    [defaultAttributes setOutlineEnabled:YES];
}

- (void) setPositions:(NSArray*)positions
{
    if (positions == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Positions array is nil")
    }

    _positions = positions;

    [self setReferencePosition:[positions count] < 1 ? nil : [positions objectAtIndex:0]];

    [self reset];
}

- (void) setFollowTerrain:(BOOL)followTerrain
{
    if (_followTerrain != followTerrain)
    {
        [self reset];
    }

    _followTerrain = followTerrain;
}

- (void) setNumSubsegments:(int)numSubsegments
{
    if (numSubsegments < 0)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Number of subsegments is less than 0")
    }

    _numSubsegments = numSubsegments;

    [self reset];
}

- (void) setPathType:(NSString*)pathType
{
    if (pathType == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Path type is nil")
    }

    _pathType = pathType;

    [self reset];
}

- (void) setTerrainConformance:(double)terrainConformance
{
    if (terrainConformance < 0)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Terrain conformance is less than 0")
    }

    _terrainConformance = terrainConformance;

    [self reset];
}

- (void) setExtrude:(BOOL)extrude
{
    _extrude = extrude;

    [self reset];
}

- (BOOL) mustDrawInterior
{
    if (!_extrude || [[self altitudeMode] isEqualToString:WW_ALTITUDE_MODE_CLAMP_TO_GROUND])
    {
        return NO;
    }

    return [super mustDrawInterior];
}

- (BOOL) mustRegenerateGeometry:(WWDrawContext*)dc
{
    if (points == nil || verticalExaggeration != [dc verticalExaggeration])
    {
        return YES;
    }

    if ([_altitudeMode isEqual:WW_ALTITUDE_MODE_ABSOLUTE])
    {
        return NO;
    }

    return YES;
}

- (BOOL) isSurfacePath
{
    return [[self altitudeMode] isEqualToString:WW_ALTITUDE_MODE_CLAMP_TO_GROUND] && _followTerrain;
}

- (void) doMakeOrderedRenderable:(WWDrawContext*)dc
{
    // Free the previously generated tessellation points.
    if (points != nil)
    {
        free(points);
        numPoints = 0;
    }

    // A nil reference position is a signal that there are no positions to render.
    WWPosition* refPos = [self referencePosition];
    if (refPos == nil)
    {
        return;
    }

    // Set the transformation matrix to correspond to the reference position.
    [[dc terrain] surfacePointAtLatitude:[refPos latitude]
                               longitude:[refPos longitude]
                                  offset:[refPos altitude]
                            altitudeMode:[self altitudeMode]
                                  result:referencePoint];
    WWVec4* rpt = referencePoint;
    [transformationMatrix setToTranslation:[rpt x] y:[rpt y] z:[rpt z]];

    // Tessellate the path in geographic coordinates.
    NSArray* tessellatedPositions = [self makeTessellatedPositions:dc];
    if ([tessellatedPositions count] < 2)
    {
        return;
    }

    // Convert the tessellated geographic coordinates to the Cartesian coordinates that will be rendered.
    NSArray* tessellationPoints = [self computeRenderedPath:dc positions:tessellatedPositions];

    // Create the extent from the Cartesian points. Those points are relative to this path's reference point, so
    // translate the computed extent to the reference point.
    WWBoundingBox* box = [[WWBoundingBox alloc] initWithPoints:tessellationPoints];
    [box translate:referencePoint];
    [self setExtent:box];
}

- (BOOL) isOrderedRenderableValid:(WWDrawContext*)dc
{
    return points != nil && numPoints > 1;
}

- (void) addOrderedRenderable:(WWDrawContext*)dc
{
    if ([self isSurfacePath])
    {
        [dc addOrderedRenderableToBack:self];
    }
    else
    {
        [dc addOrderedRenderable:self];
    }
}

- (void) applyModelviewProjectionMatrix:(WWDrawContext*)dc
{
    if ([self isSurfacePath])
    {
        // Modify the standard modelview-projection matrix by applying a depth offset to the perspective matrix.
        // This pulls the path towards the eye just a bit to ensure it shows over the terrain.
        WWMatrix* mvp = [[WWMatrix alloc] initWithMatrix:[[dc navigatorState] projection]];
        [mvp offsetProjectionDepth:-0.01];

        [mvp multiplyMatrix:[[dc navigatorState] modelview]];
        [mvp multiplyMatrix:transformationMatrix];
        [dc.currentProgram loadUniformMatrix:@"mvpMatrix" matrix:mvp];
    }
    else
    {
        [super applyModelviewProjectionMatrix:dc];
    }
}

- (void) doDrawOutline:(WWDrawContext*)dc
{
    int location = [dc.currentProgram getAttributeLocation:@"vertexPoint"];
    BOOL extrudeIt = [self mustDrawInterior];
    int stride = extrudeIt ? 24 : 12;
    int nPts = extrudeIt ? numPoints / 2 : numPoints;
    glVertexAttribPointer((GLuint) location, 3, GL_FLOAT, GL_FALSE, stride, points);
    glDrawArrays(GL_LINE_STRIP, 0, nPts);
}

- (void) doDrawInterior:(WWDrawContext*)dc
{
    int location = [dc.currentProgram getAttributeLocation:@"vertexPoint"];
    glVertexAttribPointer((GLuint) location, 3, GL_FLOAT, GL_FALSE, 0, points);
    glDrawArrays(GL_TRIANGLE_STRIP, 0, numPoints);
}

- (NSArray*) makeTessellatedPositions:(WWDrawContext*)dc
{
    NSMutableArray* tessellatedPositions = [[NSMutableArray alloc] init];

    [tessellatedPositions addObject:[_positions objectAtIndex:0]];

    WWVec4* ptA = [[WWVec4 alloc] initWithZeroVector]; // temp variable
    WWVec4* ptB = [[WWVec4 alloc] initWithZeroVector]; // temp variable

    WWPosition* posA = [_positions objectAtIndex:0];

    [[dc terrain] surfacePointAtLatitude:[posA latitude]
                               longitude:[posA longitude]
                                  offset:[posA altitude]
                            altitudeMode:[self altitudeMode]
                                  result:ptA];

    id <WWNavigatorState> navState = [dc navigatorState];
    for (NSUInteger i = 1; i < [_positions count]; i++)
    {
        WWPosition* posB = [_positions objectAtIndex:i];
        [[dc terrain] surfacePointAtLatitude:[posB latitude]
                                   longitude:[posB longitude]
                                      offset:[posB altitude]
                                altitudeMode:[self altitudeMode]
                                      result:ptB];

        double eyeDistance = [[navState eyePoint] distanceTo3:ptA];
        double pixelSize = [navState pixelSizeAtDistance:eyeDistance];
        if ([ptA distanceTo3:ptB] < pixelSize * 8)
        {
            [tessellatedPositions addObject:posB]; // distance is short, so no need for subsegments
        }
        else
        {
            [self makeSegment:dc posA:posA posB:posB ptA:ptA ptB:ptB positions:tessellatedPositions];
        }

        posA = posB;
        [ptA set:[ptB x] y:[ptB y] z:[ptB z]];
    }

    return tessellatedPositions;
}

- (void) makeSegment:(WWDrawContext*)dc
                posA:(WWPosition*)posA
                posB:(WWPosition*)posB
                 ptA:(WWVec4*)ptA
                 ptB:(WWVec4*)ptB
           positions:(NSMutableArray*)tessellatedPositions
{
    double arcLength = [[self pathType] isEqualToString:WW_LINEAR]
            ? [ptA distanceTo3:ptB] : [self computeSegmentLength:dc posA:posA posB:posB];

    if (arcLength <= 0 || ([[self pathType] isEqualToString:WW_LINEAR] && !_followTerrain))
    {
        // Segment is zero length or a straight line.
        if (![ptA isEqual:ptB])
        {
            [tessellatedPositions addObject:posB];
        }
        return;
    }

    id <WWNavigatorState> navState = [dc navigatorState];
    WWVec4* eyePoint = [navState eyePoint];

    double segmentAzimuth;
    double segmentDistance;
    if ([_pathType isEqualToString:WW_LINEAR])
    {
        segmentAzimuth = [WWLocation linearAzimuth:posA endLocation:posB];
        segmentDistance = [WWLocation linearDistance:posA endLocation:posB];
    }
    else if ([_pathType isEqualToString:WW_RHUMB])
    {
        segmentAzimuth = [WWLocation rhumbAzimuth:posA endLocation:posB];
        segmentDistance = [WWLocation rhumbDistance:posA endLocation:posB];
    }
    else
    {
        segmentAzimuth = [WWLocation greatCircleAzimuth:posA endLocation:posB];
        segmentDistance = [WWLocation greatCircleDistance:posA endLocation:posB];
    }

    for (double s = 0, p = 0; s < 1;) // p is length along path. s is relative length ([0,1]) along path.
    {
        if (_followTerrain)
        {
            p += _terrainConformance * [navState pixelSizeAtDistance:[ptA distanceTo3:eyePoint]];
        }
        else
        {
            p += arcLength / _numSubsegments;
        }

        WWPosition* pos;

        s = p / arcLength;
        if (s >= 1)
        {
            pos = posB;
        }
        else if ([_pathType isEqualToString:WW_LINEAR])
        {
            double distance = s * segmentDistance;
            WWLocation* tmp = [[WWLocation alloc] initWithDegreesLatitude:0 longitude:0];
            [WWLocation linearLocation:posA azimuth:segmentAzimuth distance:distance outputLocation:tmp];
            pos = [[WWPosition alloc] initWithDegreesLatitude:[tmp latitude] longitude:[tmp longitude]
                                                     altitude:(1 - s) * [posA altitude] + s * [posB altitude]];
        }
        else if ([_pathType isEqualToString:WW_RHUMB])
        {
            double distance = s * segmentDistance;
            WWLocation* tmp = [[WWLocation alloc] initWithDegreesLatitude:0 longitude:0];
            [WWLocation rhumbLocation:posA azimuth:segmentAzimuth distance:distance outputLocation:tmp];
            pos = [[WWPosition alloc] initWithDegreesLatitude:[tmp latitude] longitude:[tmp longitude]
                                                     altitude:(1 - s) * [posA altitude] + s * [posB altitude]];
        }
        else
        {
            double distance = s * segmentDistance;
            WWLocation* tmp = [[WWLocation alloc] initWithDegreesLatitude:0 longitude:0];
            [WWLocation greatCircleLocation:posA azimuth:segmentAzimuth distance:distance outputLocation:tmp];
            pos = [[WWPosition alloc] initWithDegreesLatitude:[tmp latitude] longitude:[tmp longitude]
                                                     altitude:(1 - s) * [posA altitude] + s * [posB altitude]];
        }

        [tessellatedPositions addObject:pos];

        ptA = ptB;
    }
}

- (double) computeSegmentLength:(WWDrawContext*)dc posA:(WWPosition*)posA posB:(WWPosition*)posB
{
    double length = RADIANS([WWLocation greatCircleDistance:posA endLocation:posB]) * [[dc globe] equatorialRadius];

    if (![[self altitudeMode] isEqualToString:WW_ALTITUDE_MODE_CLAMP_TO_GROUND])
    {
        double height = 0.5 * ([posA altitude] + [posB altitude]);
        length += height * [dc verticalExaggeration];
    }

    return length;
}

- (NSArray*) computeRenderedPath:(WWDrawContext*)dc positions:(NSArray*)tessellatedPositions
{
    BOOL extrudeIt = [self mustDrawInterior];

    id <WWTerrain> terrain = [dc terrain];
    NSString* altMode = [self altitudeMode];
    double eyeDistSquared = DBL_MAX;
    WWVec4* eyePoint = [[dc navigatorState] eyePoint];

    numPoints = (extrudeIt ? 2 : 1) * [tessellatedPositions count];
    NSMutableArray* tessellationPoints = [[NSMutableArray alloc] initWithCapacity:(NSUInteger) numPoints];

    points = malloc((size_t) numPoints * 3 * sizeof(float));

    int stride = extrudeIt ? 6 : 3;
    for (NSUInteger i = 0; i < [tessellatedPositions count]; i++)
    {
        WWPosition* pos = [tessellatedPositions objectAtIndex:i];
        double lat = [pos latitude];
        double lon = [pos longitude];

        WWVec4* pt = [[WWVec4 alloc] initWithZeroVector];
        [terrain surfacePointAtLatitude:lat longitude:lon offset:[pos altitude] altitudeMode:altMode result:pt];

        double dSquared = [pt distanceSquared3:eyePoint];
        if (dSquared < eyeDistSquared)
        {
            eyeDistSquared = dSquared;
        }

        [pt subtract3:referencePoint];
        [tessellationPoints addObject:pt];

        int k = stride * i;
        points[k] = (float) [pt x];
        points[k + 1] = (float) [pt y];
        points[k + 2] = (float) [pt z];

        if (extrudeIt)
        {
            [terrain surfacePointAtLatitude:lat longitude:lon offset:0 result:pt];

            dSquared = [pt distanceSquared3:eyePoint];
            if (dSquared < eyeDistSquared)
            {
                eyeDistSquared = dSquared;
            }

            [pt subtract3:referencePoint];
            [tessellationPoints addObject:pt];

            points[k + 3] = (float) [pt x];
            points[k + 4] = (float) [pt y];
            points[k + 5] = (float) [pt z];
        }
    }

    [self setEyeDistance:sqrt(eyeDistSquared)];

    return tessellationPoints;
}

@end