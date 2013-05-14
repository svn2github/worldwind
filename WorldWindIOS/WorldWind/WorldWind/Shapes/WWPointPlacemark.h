/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.

 @version $Id$
 */

#import <Foundation/Foundation.h>
#import <CoreGraphics/CGGeometry.h>
#import "WorldWind/Render/WWOrderedRenderable.h"

@class WWColor;
@class WWLayer;
@class WWMatrix;
@class WWPickedObject;
@class WWPickSupport;
@class WWPointPlacemarkAttributes;
@class WWPosition;
@class WWTexture;
@class WWVec4;

@interface WWPointPlacemark : NSObject <WWOrderedRenderable>
{
@protected
    // Placemark attributes.
    WWPointPlacemarkAttributes* defaultAttributes;
    WWPointPlacemarkAttributes* activeAttributes;
    WWTexture* activeTexture;
    // Placemark geometry.
    WWVec4* placePoint;
    WWVec4* screenPoint;
    WWVec4* screenOffset;
    WWMatrix* imageTransform;
    CGRect imageRect;
    // Rendering and picking support.
    WWMatrix* matrix;
    WWColor* color;
    WWLayer* pickLayer;
    WWPickSupport* pickSupport;
}

/// @name Point Placemark Attributes

@property (nonatomic) NSString* displayName;

@property (nonatomic) WWPointPlacemarkAttributes* attributes;

@property (nonatomic) WWPointPlacemarkAttributes* highlightAttributes;

@property (nonatomic) BOOL highlighted;

@property (nonatomic) BOOL enabled;

@property (nonatomic) WWPosition* position;

@property (nonatomic) NSString* altitudeMode;

@property (nonatomic) id pickDelegate;

@property (nonatomic) double eyeDistance;

@property (nonatomic) NSTimeInterval insertionTime;

/// @name Initializing Point Placemarks

- (WWPointPlacemark*) initWithPosition:(WWPosition*)position;

/// @name Methods of Interest Only to Subclasses

- (void) setDefaultAttributes;

- (void) makeOrderedRenderable:(WWDrawContext*)dc;

- (void) doMakeOrderedRenderable:(WWDrawContext*)dc;

- (void) determineActiveAttributes:(WWDrawContext*)dc;

- (BOOL) intersectsFrustum:(WWDrawContext*)dc;

- (void) drawOrderedRenderable:(WWDrawContext*)dc;

- (void) doDrawOrderedRenderable:(WWDrawContext*)dc;

- (void) beginDrawing:(WWDrawContext*)dc;

- (void) endDrawing:(WWDrawContext*)dc;

- (WWPickedObject*) createPickedObject:(WWDrawContext*)dc colorCode:(unsigned int)colorCode;

@end