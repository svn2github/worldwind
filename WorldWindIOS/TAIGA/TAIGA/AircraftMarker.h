/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.

 @version $Id$
 */

#import <Foundation/Foundation.h>
#import "WorldWind/Render/WWRenderable.h"

@class WWColor;
@class WWPosition;
@class WWShapeAttributes;
@class WWSphere;

@interface AircraftMarker : NSObject <WWRenderable>
{
@protected
    WWSphere* shape;
    WWShapeAttributes* shapeAttrs;
}

/// Indicates this aircraft's display name.
@property (nonatomic) NSString* displayName;

/// Indicates whether this aircraft should be displayed.
@property (nonatomic) BOOL enabled;

/// Indicates this aircraft's last known position.
@property (nonatomic) WWPosition* position;

/// Indicates this aircraft marker's color.
@property (nonatomic) WWColor* color;

- (AircraftMarker*) init;

@end