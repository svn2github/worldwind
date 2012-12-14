/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import <Foundation/Foundation.h>

@class WWLocation;

@interface WWSector : NSObject <NSCopying>

@property(nonatomic) double minLatitude;
@property(nonatomic) double maxLatitude;
@property(nonatomic) double minLongitude;
@property(nonatomic) double maxLongitude;

- (WWSector*) initWithDegreesMinLatitude:(double)minLatitude
                             maxLatitude:(double)maxLatitude
                            minLongitude:(double)minLongitude
                            maxLongitude:(double)maxLongitude;

- (WWSector*) initWithFullSphere;

- (void) centroidLocation:(WWLocation*)result;

- (double) deltaLat;
- (double) deltaLon;
- (double) minLatitudeRadians;
- (double) maxLatitudeRadians;
- (double) minLongitudeRadians;
- (double) maxLongitudeRadians;

- (BOOL) intersects:(WWSector*)sector;

@end
