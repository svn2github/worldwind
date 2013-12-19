/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.

 @version $Id$
 */

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import "WorldWind/Shapes/WWAbstractShape.h"

@interface AircraftShape : WWAbstractShape
{
@protected
    BOOL sizeIsPixels; // indicates whether the size was specified in pixels
    double sizeInMeters; // value used to scale the unit-length aircraft shape
    WWPosition* position;
}

/// This aircraft's geographic position and course.
@property (nonatomic) CLLocation* location;

/// This aircraft's size. Use isSizeInPixels to determine whether the value is in pixels rather than meters.
///
/// This indicates the length from the nose of the aircraft to the end of its tail, and is expressed either in meters
/// or in screen pixels. The aircraft's width and height are scaled to maintain their size relative to the length.
@property (nonatomic) double size;

@property (nonatomic) double minSize;

@property (nonatomic) double maxSize;

/// Indicates whether this aircraft's size was specified in pixels rather than meters.
- (BOOL) isSizeInPixels;

- (AircraftShape*) initWithSize:(double)size;

- (AircraftShape*) initWithSizeInPixels:(double)size;

- (AircraftShape*) initWithSizeInPixels:(double)size minSize:(double)minSize maxSize:(double)maxSize;

@end