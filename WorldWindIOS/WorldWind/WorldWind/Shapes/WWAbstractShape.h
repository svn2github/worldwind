/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import <Foundation/Foundation.h>
#import "WorldWind/Shapes/WWOutlinedShape.h"
#import "WorldWind/Render/WWOrderedRenderable.h"

@class WWShapeAttributes;
@class WWMatrix;
@class WWColor;
@class WWVec4;
@class WWPosition;
@protocol WWExtent;
@class WWDrawContext;
@class WWGpuProgram;
@class WWGpuResourceCache;
@class WWGlobe;

@interface WWAbstractShape : NSObject <WWOutlinedShape, WWOrderedRenderable>
{
@protected
    WWShapeAttributes* defaultAttributes;
    WWShapeAttributes* activeAttributes;
    WWMatrix* transformationMatrix;
    WWVec4* referencePoint;

    // Volatile values used only during frame generation.
    NSString* programKey;
    WWColor* currentColor;
}

@property(nonatomic) WWShapeAttributes* attributes;
@property(nonatomic) WWShapeAttributes* highlightAttributes;
@property(nonatomic) BOOL highlighted;
@property(nonatomic) BOOL visible;
@property(nonatomic) NSString* altitudeMode;
@property(nonatomic) BOOL batchRendering;
@property(nonatomic) id delegateOwner;
@property(nonatomic) WWPosition* referencePosition;
@property(nonatomic) double eyeDistance;
@property(nonatomic) id <WWExtent> extent;

- (WWAbstractShape*) init;

- (void) setDefaultAttributes;

- (void) drawOrderedRenderable:(WWDrawContext*)dc;

- (void) doDrawOrderedRenderable:(WWDrawContext*)dc;

- (void) makeOrderedRenderable:(WWDrawContext*)dc;

- (void) doMakeOrderedRenderable:(WWDrawContext*)dc;

- (void) determineActiveAttributes;

- (BOOL) mustRegenerateGeometry:(WWDrawContext*)dc;

- (BOOL) orderedRenderableValid:(WWDrawContext*)dc;

- (BOOL) mustDrawInterior;

- (BOOL) mustDrawOutline;

- (void) beginDrawing:(WWDrawContext*)dc;

- (void) endDrawing:(WWDrawContext*)dc;

- (void) applyModelviewProjectionMatrix:(WWDrawContext*)dc;

- (void) prepareToDrawInterior:(WWDrawContext*)dc attributes:(WWShapeAttributes*)attributes;

- (void) prepareToDrawOutline:(WWDrawContext*)dc attributes:(WWShapeAttributes*)attributes;

- (void) doDrawInterior:(WWDrawContext*)dc;

- (void) doDrawOutline:(WWDrawContext*)dc;

- (WWGpuProgram*) gpuProgram:(WWDrawContext*)dc;

@end