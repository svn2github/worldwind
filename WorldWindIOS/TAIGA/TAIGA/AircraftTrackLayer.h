/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.

 @version $Id$
 */

#import <Foundation/Foundation.h>
#import "WorldWind/Layer/WWLayer.h"

@class WWPosition;
@class WWShapeAttributes;

@interface AircraftTrackLayer : WWLayer
{
@protected
    NSMutableArray* markers;
    WWShapeAttributes* shapeAttrs;
    double unmarkedDistance;
    BOOL locationTrackingEnabled;
    BOOL savingState;
}

@property (nonatomic) WWPosition* position;

@property (nonatomic) double markerDistance;

- (id) init;

- (void) removeAllMarkers;

@end