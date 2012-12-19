/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.

 @version $Id$
 */

#import <Foundation/Foundation.h>
#import "WorldWind/Geometry/WWLocation.h"

@interface WWPosition : WWLocation

@property (nonatomic) double elevation;

- (WWPosition*) initWithDegreesLatitude:(double)latitude longitude:(double)longitude elevation:(double)elevation;

- (WWPosition*) setDegreesLatitude:(double)latitude longitude:(double)longitude elevation:(double)elevation;

@end
