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

    self->tessellatedPositions = [[NSMutableArray alloc] init];
    self->tessellationPoints = [[NSMutableArray alloc] init];

    return self;
}

- (void) reset
{
    [self->tessellationPoints removeAllObjects];
}

- (BOOL) mustDrawInterior
{
    return NO;
}

- (BOOL) mustRegenerateGeometry:(WWDrawContext*)dc
{
    return [self->tessellationPoints count] == 0 || self->verticalExaggeration != [dc verticalExaggeration];
}

- (BOOL) isSurfacePath
{
    return [[self altitudeMode] isEqualToString:WW_ALTITUDE_MODE_CLAMP_TO_GROUND] && _followTerrain;
}

- (void) doMakeOrderedRenderable:(WWDrawContext*)dc
{
    if ([self referencePosition] == nil)
    {
        return;
    }

    // Set the transformation matrix to correspond to the reference position.
    WWPosition* refPos = [self referencePosition];
    [[dc terrain] surfacePointAtLatitude:[refPos latitude]
                               longitude:[refPos longitude]
                                  offset:[refPos altitude]
                            altitudeMode:[self altitudeMode]
                                  result:self->referencePoint];
    WWVec4* rpt = self->referencePoint;
    [self->transformationMatrix setTranslation:[rpt x] y:[rpt y] z:[rpt z]];

    [self makeTessellatedPositions:dc];
    if ([self->tessellatedPositions count] < 2)
    {
        return;
    }

    [self computeRenderedPath:dc];

    WWBoundingBox* box = [[WWBoundingBox alloc] initWithPoints:self->tessellationPoints];
    [box translate:self->referencePoint];
    [self setExtent:box];

    self->verticalExaggeration = [dc verticalExaggeration];

    if (![[self extent] intersects:[[dc navigatorState] frustumInModelCoordinates]]
            || [dc isSmall:[self extent] numPixels:1])
    {
        return;
    }
}

- (BOOL) orderedRenderableValid:(WWDrawContext*)dc
{
    return [self->tessellationPoints count] > 1;
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
        // This pulls the line forward just a bit to ensure it shows over the terrain.
        WWMatrix* mvp = [[WWMatrix alloc] initWithMatrix:[[dc navigatorState] projection]];
        [mvp offsetPerspectiveDepth:-0.01];

        [mvp multiplyMatrix:[[dc navigatorState] modelview]];
        [mvp multiplyMatrix:self->transformationMatrix];
        [dc.currentProgram loadUniformMatrix:@"mvpMatrix" matrix:mvp];
    }
    else
    {
        [super applyModelviewProjectionMatrix:dc];
    }
}

- (void) doDrawOutline:(WWDrawContext*)dc
{
    int numPoints = [self->tessellationPoints count];
    float* points = malloc((size_t)(numPoints * 3 * sizeof(float_t)));

    for (GLuint i = 0; i < numPoints; i++)
    {
        WWVec4* pt = [self->tessellationPoints objectAtIndex:i];

        int k = 3 * i;
        points[k] = (float) [pt x];
        points[k + 1] = (float) [pt y];
        points[k + 2] = (float) [pt z];
    }

    int location = [dc.currentProgram getAttributeLocation:@"vertexPoint"];
    glVertexAttribPointer((GLuint) location, 3, GL_FLOAT, GL_FALSE, 0, points);
    glDrawArrays(GL_LINE_STRIP, 0, numPoints);

    free(points);
}

- (void) makeTessellatedPositions:(WWDrawContext*)dc
{
    [self->tessellatedPositions removeAllObjects];

    [self->tessellatedPositions addObject:[_positions objectAtIndex:0]];

    WWVec4* ptA = [[WWVec4 alloc] initWithZeroVector];
    WWVec4* ptB = [[WWVec4 alloc] initWithZeroVector];

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
            [self->tessellatedPositions addObject:posB];
        }
        else
        {
            [self makeSegment:dc posA:posA posB:posB ptA:ptA ptB:ptB];
        }

        posA = posB;
        ptA = ptB;
    }
}

- (void) makeSegment:(WWDrawContext*)dc posA:(WWPosition*)posA posB:(WWPosition*)posB ptA:(WWVec4*)ptA ptB:(WWVec4*)ptB
{
    double arcLength = [[self pathType] isEqualToString:WW_LINEAR]
            ? [ptA distanceTo3:ptB] : [self computeSegmentLength:dc posA:posA posB:posB];

    if (arcLength <= 0 || ([[self pathType] isEqualToString:WW_LINEAR] && !_followTerrain))
    {
        if (![ptA isEqual:ptB])
        {
            [self->tessellatedPositions addObject:posB];
        }
        return;
    }

    id <WWNavigatorState> navState = [dc navigatorState];
    WWVec4* eyePoint = [navState eyePoint];

    double segmentAzimuth;
    double segmentDistance;
    if ([_pathType isEqualToString:WW_RHUMB] || [_pathType isEqualToString:WW_LINEAR])
    {
        segmentAzimuth = [WWLocation rhumbAzimuth:posA endLocation:posB];
        segmentDistance = [WWLocation rhumbDistance:posA endLocation:posB];
    }
    else
    {
        segmentAzimuth = [WWLocation greatCircleAzimuth:posA endLocation:posB];
        segmentDistance = [WWLocation greatCircleDistance:posA endLocation:posB];
    }

    for (double s = 0, p = 0; s < 1;)
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
        else if ([_pathType isEqualToString:WW_RHUMB] || [_pathType isEqualToString:WW_LINEAR])
        {
            double distance = s * segmentDistance;
            WWLocation* latLon = [[WWLocation alloc] initWithDegreesLatitude:0 longitude:0];
            [WWLocation rhumbLocation:posA azimuth:segmentAzimuth distance:distance outputLocation:latLon];
            pos = [[WWPosition alloc] initWithDegreesLatitude:[latLon latitude] longitude:[latLon longitude]
                                                     altitude:(1 - s) * [posA altitude] + s * [posB altitude]];
        }
        else
        {
            double distance = s * segmentDistance;
            WWLocation* latLon = [[WWLocation alloc] initWithDegreesLatitude:0 longitude:0];
            [WWLocation greatCircleLocation:posA azimuth:segmentAzimuth distance:distance outputLocation:latLon];
            pos = [[WWPosition alloc] initWithDegreesLatitude:[latLon latitude] longitude:[latLon longitude]
                                                     altitude:(1 - s) * [posA altitude] + s * [posB altitude]];
        }

        [self->tessellatedPositions addObject:pos];

        ptA = ptB;
    }
}

- (double) computeSegmentLength:(WWDrawContext*)dc posA:(WWPosition*)posA posB:(WWPosition*)posB
{
    double length = [WWLocation greatCircleDistance:posA endLocation:posB] * [[dc globe] equatorialRadius];

    if (![[self altitudeMode] isEqualToString:WW_ALTITUDE_MODE_CLAMP_TO_GROUND])
    {
        double height = 0.5 * ([posA altitude] + [posB altitude]);
        length += height * [dc verticalExaggeration];
    }

    return length;
}

- (void) computeRenderedPath:(WWDrawContext*)dc
{
    id <WWTerrain> terrain = [dc terrain];
    NSString* altMode = [self altitudeMode];
    double eyeDist2 = DBL_MAX;
    WWVec4* eyePoint = [[dc navigatorState] eyePoint];

    [self->tessellationPoints removeAllObjects];

    for (GLuint i = 0; i < [self->tessellatedPositions count]; i++)
    {
        WWPosition* pos = [self->tessellatedPositions objectAtIndex:i];

        WWVec4* pt = [[WWVec4 alloc] initWithZeroVector];
        [terrain surfacePointAtLatitude:[pos latitude] longitude:[pos longitude] offset:[pos altitude]
                           altitudeMode:altMode result:pt];

        double d2 = [pt distanceTo3:eyePoint];
        if (d2 < eyeDist2)
        {
            eyeDist2 = d2;
        }

        [pt subtract3:self->referencePoint];

        [self->tessellationPoints addObject:pt];
    }

    [self setEyeDistance:sqrt(eyeDist2)];

    [self->tessellatedPositions removeAllObjects];
}

@end