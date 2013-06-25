/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import "WorldWind/Terrain/WWGlobe.h"
#import "WorldWind/Terrain/WWEarthElevationModel.h"
#import "WorldWind/Terrain/WWTessellator.h"
#import "WorldWind/Geometry/WWLine.h"
#import "WorldWind/Geometry/WWPosition.h"
#import "WorldWind/Geometry/WWSector.h"
#import "WorldWind/Geometry/WWVec4.h"
#import "WorldWind/Util/WWMath.h"
#import "WorldWind/WWLog.h"

@implementation WWGlobe : NSObject

- (WWGlobe*) init
{
    self = [super init];

    _equatorialRadius = 6378137.0;
    _polarRadius = 6356752.3;
    _es = 0.00669437999013;
    _minElevation = 0;
    _tessellator = [[WWTessellator alloc] initWithGlobe:self];
    _elevationModel = [[WWEarthElevationModel alloc] init];

    return self;
}

- (WWTerrainTileList*) tessellate:(WWDrawContext*)dc
{
    if (dc == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Draw context is nil")
    }

    if (_tessellator == nil)
    {
        WWLOG_AND_THROW(NSInternalInconsistencyException, @"Tessellator is nil")
    }

    return [_tessellator tessellate:dc];
}

- (void) computePointFromPosition:(double)latitude
                        longitude:(double)longitude
                         altitude:(double)altitude
                      outputPoint:(WWVec4*)result
{
    if (result == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Result pointer is nil")
    }

    double cosLat = cos(RADIANS(latitude));
    double sinLat = sin(RADIANS(latitude));
    double cosLon = cos(RADIANS(longitude));
    double sinLon = sin(RADIANS(longitude));

    double rpm = _equatorialRadius / sqrt(1.0 - _es * sinLat * sinLat);

    result.x = (rpm + altitude) * cosLat * sinLon;
    result.y = (rpm * (1.0 - _es) + altitude) * sinLat;
    result.z = (rpm + altitude) * cosLat * cosLon;
}

- (void) computePointsFromPositions:(WWSector*)sector
                             numLat:(int)numLat
                             numLon:(int)numLon
                    metersElevation:(double[])metersElevation
                    borderElevation:(double)borderElevation
                             offset:(WWVec4*)offset
                        outputArray:(float[])result
                       outputStride:(int)stride
{
    if (sector == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Sector is nil")
    }

    if (numLat <= 0 || numLon <= 0)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Number of latitude or longitude points is <= 0")
    }

    if (!metersElevation)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Elevations is NULL")
    }

    if (result == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Result pointer is nil")
    }

    if (stride < 3)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Stride is less than 3")
    }

    double minLat = RADIANS([sector minLatitude]);
    double maxLat = RADIANS([sector maxLatitude]);
    double minLon = RADIANS([sector minLongitude]);
    double maxLon = RADIANS([sector maxLongitude]);
    double deltaLat = (maxLat - minLat) / (numLat > 1 ? numLat - 1 : 1);
    double deltaLon = (maxLon - minLon) / (numLon > 1 ? numLon - 1 : 1);

    double offsetX = [offset x];
    double offsetY = [offset y];
    double offsetZ = [offset z];

    int numLatPoints = numLat + 2;
    int numLonPoints = numLon + 2;
    int vertexOffset = 0;
    int elevOffset = 0;

    // Iterate over the latitude coordinates in the specified sector and compute the cosine and sine of each longitude
    // value required to compute Cartesian points for the specified sector. This eliminates the need to re-compute the
    // same cosine and sine results for each row of latitude.
    double lon = minLon;
    double cosLon[numLonPoints];
    double sinLon[numLonPoints];
    for (int i = 0; i < numLonPoints; i++)
    {
        // Explicitly set the first and last row to minLon and maxLon, respectively, rather than using the
        // accumulated lon value, in order to ensure that the Cartesian points of adjacent sectors match perfectly.
        if (i <= 1) // Border and first longitude.
            lon = minLon;
        else if (i >= numLon) // Border and last longitude.
            lon = maxLon;
        else
            lon += deltaLon;

        cosLon[i] = cos(lon);
        sinLon[i] = sin(lon);
    }

    // Iterate over the latitude and longitude coordinates in the specified sector, computing the Cartesian point
    // corresponding to each latitude and longitude.
    double lat = minLat;
    for (int j = 0; j < numLatPoints; j++)
    {
        // Explicitly set the first and last row to minLat and maxLat, respectively, rather than using the
        // accumulated lat value, in order to ensure that the Cartesian points of adjacent sectors match perfectly.
        if (j <= 1) // Border and first latitude.
            lat = minLat;
        else if (j >= numLat) // Border and last latitude.
            lat = maxLat;
        else
            lat += deltaLat;

        // Latitude is constant for each row, therefore values depending on only latitude can be computed once per row.
        double cosLat = cos(lat);
        double sinLat = sin(lat);
        double rpm = _equatorialRadius / sqrt(1.0 - _es * sinLat * sinLat);

        for (int i = 0; i < numLon + 2; i++)
        {
            double elev = (j == 0 || j == numLat + 1 || i == 0 || i == numLon + 1)
                    ? borderElevation : metersElevation[elevOffset++];

            result[vertexOffset] = (float) ((rpm + elev) * cosLat * sinLon[i] - offsetX);
            result[vertexOffset + 1] = (float) ((rpm * (1.0 - _es) + elev) * sinLat - offsetY);
            result[vertexOffset + 2] = (float) ((rpm + elev) * cosLat * cosLon[i] - offsetZ);
            vertexOffset += stride;
        }
    }
}

- (void) computePositionFromPoint:(double)x
                                y:(double)y
                                z:(double)z
                   outputPosition:(WWPosition*)result
{
    if (result == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Result pointer is nil")
    }

    // Contributed by Nathan Kronenfeld. Updated on 1/24/2011. Brings this calculation in line with Vermeille's most
    // recent update.

    // According to H. Vermeille, "An analytical method to transform geocentric into geodetic coordinates"
    // http://www.springerlink.com/content/3t6837t27t351227/fulltext.pdf
    // Journal of Geodesy, accepted 10/2010, not yet published
    double X = z;
    double Y = x;
    double Z = y;
    double XXpYY = X * X + Y * Y;
    double sqrtXXpYY = sqrt(XXpYY);

    double a = _equatorialRadius;
    double ra2 = 1 / (a * a);
    double e2 = _es;
    double e4 = e2 * e2;

    // Step 1
    double p = XXpYY * ra2;
    double q = Z * Z * (1 - e2) * ra2;
    double r = (p + q - e4) / 6;

    double h;
    double phi;

    double evoluteBorderTest = 8 * r * r * r + e4 * p * q;
    if (evoluteBorderTest > 0 || q != 0)
    {
        double u;

        if (evoluteBorderTest > 0)
        {
            // Step 2: general case
            double rad1 = sqrt(evoluteBorderTest);
            double rad2 = sqrt(e4 * p * q);

            // 10*e2 is my arbitrary decision of what Vermeille means by "near... the cusps of the evolute".
            if (evoluteBorderTest > 10 * e2)
            {
                double rad3 = cbrt((rad1 + rad2) * (rad1 + rad2));
                u = r + 0.5 * rad3 + 2 * r * r / rad3;
            }
            else
            {
                u = r + 0.5 * cbrt((rad1 + rad2) * (rad1 + rad2)) + 0.5 * cbrt((rad1 - rad2) * (rad1 - rad2));
            }
        }
        else
        {
            // Step 3: near evolute
            double rad1 = sqrt(-evoluteBorderTest);
            double rad2 = sqrt(-8 * r * r * r);
            double rad3 = sqrt(e4 * p * q);
            double atan = 2 * atan2(rad3, rad1 + rad2) / 3;

            u = -4 * r * sin(atan) * cos(M_PI / 6 + atan);
        }

        double v = sqrt(u * u + e4 * q);
        double w = e2 * (u + v - q) / (2 * v);
        double k = (u + v) / (sqrt(w * w + u + v) + w);
        double D = k * sqrtXXpYY / (k + e2);
        double sqrtDDpZZ = sqrt(D * D + Z * Z);

        h = (k + e2 - 1) * sqrtDDpZZ / k;
        phi = 2 * atan2(Z, sqrtDDpZZ + D);
    }
    else
    {
        // Step 4: singular disk
        double rad1 = sqrt(1 - e2);
        double rad2 = sqrt(e2 - p);
        double e = sqrt(e2);

        h = -a * rad1 * rad2 / e;
        phi = rad2 / (e * rad2 + rad1 * sqrt(p));
    }

    // Compute lambda
    double lambda;
    double s2 = sqrt(2);
    if ((s2 - 1) * Y < sqrtXXpYY + X)
    {
        // case 1 - -135deg < lambda < 135deg
        lambda = 2 * atan2(Y, sqrtXXpYY + X);
    }
    else if (sqrtXXpYY + Y < (s2 + 1) * X)
    {
        // case 2 - -225deg < lambda < 45deg
        lambda = -M_PI * 0.5 + 2 * atan2(X, sqrtXXpYY - Y);
    }
    else
    {
        // if (sqrtXXpYY-Y<(s2=1)*X) {  // is the test, if needed, but it's not
        // case 3: - -45deg < lambda < 225deg
        lambda = M_PI * 0.5 - 2 * atan2(X, sqrtXXpYY + Y);
    }

    [result setDegreesLatitude:DEGREES(phi) longitude:DEGREES(lambda) altitude:h];
}

- (void) surfaceNormalAtLatitude:(double)latitude longitude:(double)longitude result:(WWVec4*)result;
{
    if (result == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Result pointer is nil")
    }

    double cosLat = cos(RADIANS(latitude));
    double cosLon = cos(RADIANS(longitude));
    double sinLat = sin(RADIANS(latitude));
    double sinLon = sin(RADIANS(longitude));

    double eqSquared = _equatorialRadius * _equatorialRadius;
    double polSquared = _polarRadius * _polarRadius;

    double x = cosLat * sinLon / eqSquared;
    double y = (1 - _es) * sinLat / polSquared;
    double z = cosLat * cosLon / eqSquared;

    [result set:x y:y z:z];
    [result normalize3];
}

- (void) surfaceNormalAtPoint:(double)x y:(double)y z:(double)z result:(WWVec4*)result
{
    if (result == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Result pointer is nil")
    }

    double eSquared = _equatorialRadius * _equatorialRadius;
    double polSquared = _polarRadius * _polarRadius;

    double nx = x / eSquared;
    double ny = y / polSquared;
    double nz = z / eSquared;

    [result set:nx y:ny z:nz];
    [result normalize3];
}

- (void) northTangentAtLatitude:(double)latitude longitude:(double)longitude result:(WWVec4*)result
{
    if (result == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Result pointer is nil")
    }

    // The north-pointing tangent is derived by rotating the vector (0, 1, 0) about the Y-axis by longitude degrees,
    // then rotating it about the X-axis by -latitude degrees. The latitude angle must be inverted because latitude
    // is a clockwise rotation about the X-axis, and standard rotation matrices assume counter-clockwise rotation.
    // The combined rotation can be represented by a combining two rotation matrices Rlat, and Rlon, then
    // transforming the vector (0, 1, 0) by the combined transform:
    //
    // NorthTangent = (Rlon * Rlat) * (0, 1, 0)
    //
    // This computation can be simplified and encoded inline by making two observations:
    // - The vector's X and Z coordinates are always 0, and its Y coordinate is always 1.
    // - Inverting the latitude rotation angle is equivalent to inverting sinLat. We know this by the trigonimetric
    //   identities cos(-x) = cos(x), and sin(-x) = -sin(x).

    double cosLat = cos(RADIANS(latitude));
    double cosLon = cos(RADIANS(longitude));
    double sinLat = sin(RADIANS(latitude));
    double sinLon = sin(RADIANS(longitude));

    double x = -sinLat * sinLon;
    double y = cosLat;
    double z = -sinLat * cosLon;

    [result set:x y:y z:z];
    [result normalize3];
}

- (void) northTangentAtPoint:(double)x y:(double)y z:(double)z result:(WWVec4*)result;
{
    if (result == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Result pointer is nil")
    }

    WWPosition* pos = [[WWPosition alloc] initWithZeroPosition];
    [self computePositionFromPoint:x y:y z:z outputPosition:pos];
    [self northTangentAtLatitude:[pos latitude] longitude:[pos longitude] result:result];
}

- (BOOL) intersectWithRay:(WWLine*)ray result:(WWVec4*)result
{
    if (ray == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Ray is nil")
    }

    if (result == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Result pointer is nil")
    }

    // Taken from "Mathematics for 3D Game Programming and Computer Graphics, Second Edition", Section 5.2.4.
    //
    // Note that the parameter n from in equations 5.70 and 5.71 is omitted here. For an ellipsoidal globe this
    // parameter is always 1, so its square and its product with any other value simplifies to the identity.

    double m = _equatorialRadius / _polarRadius; // ratio of the x semi-axis length to the y semi-axis length
    double m2 = m * m;
    double r2 = _equatorialRadius * _equatorialRadius; // nominal radius squared

    double vx = [[ray direction] x];
    double vy = [[ray direction] y];
    double vz = [[ray direction] z];
    double sx = [[ray origin] x];
    double sy = [[ray origin] y];
    double sz = [[ray origin] z];

    double a = vx * vx + m2 * vy * vy + vz * vz;
    double b = 2 * (sx * vx + m2 * sy * vy + sz * vz);
    double c = sx * sx + m2 * sy * sy + sz * sz - r2;
    double d = b * b - 4 * a * c; // discriminant

    if (d < 0)
    {
        return NO;
    }
    else
    {
        double t = (-b - sqrt(d)) / (2 * a);
        [ray pointAt:t result:result];
        return YES;
    }
}

- (NSDate*) elevationTimestamp
{
    return [_elevationModel timestamp];
}

- (double) elevationForLatitude:(double)latitude longitude:(double)longitude
{
    return [_elevationModel elevationForLatitude:latitude longitude:longitude];
}

- (double) elevationsForSector:(WWSector*)sector
                        numLat:(int)numLat
                        numLon:(int)numLon
              targetResolution:(double)targetResolution
          verticalExaggeration:(double)verticalExaggeration
                        result:(double[])result
{
    if (sector == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Sector is nil")
    }

    if (result == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Output array is nil")
    }

    if (numLat <=0 || numLon <= 0)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"A dimension is <= 0")
    }

    return [_elevationModel elevationsForSector:sector
                                         numLat:numLat
                                         numLon:numLon
                               targetResolution:targetResolution
                           verticalExaggeration:verticalExaggeration
                                         result:result];
}

- (void) minAndMaxElevationsForSector:(WWSector*)sector result:(double[])result
{
    if (sector == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Sector is nil")
    }

    if (result == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Output array is nil")
    }

    [_elevationModel minAndMaxElevationsForSector:sector result:result];
}

@end