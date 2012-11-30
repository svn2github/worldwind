/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import <Foundation/Foundation.h>

@class WWSector; // forward delcaration for use in externs below

extern WWSector* WWSECTOR_ZERO;
extern WWSector* WWSECTOR_FULL_SPHERE;

@interface WWSector : NSObject <NSCopying>

@property double minLatitude;
@property double maxLatitude;
@property double minLongitude;
@property double maxLongitude;

- (WWSector*) initWithDegreesMinLatitude:(double)minLatitude
                             maxLatitude:(double)maxLatitude
                            minLongitude:(double)minLongitude
                            maxLongitude:(double)maxLongitude;

@end
