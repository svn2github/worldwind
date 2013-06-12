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
@class WWOffset;
@class WWPickedObject;
@class WWPickSupport;
@class WWSize;
@class WWTexture;
@class WWVec4;

@interface WWScreenImage : NSObject <WWOrderedRenderable>
{
@protected
    // Rendering attributes.
    WWMatrix* mvpMatrix;
    WWMatrix* texCoordMatrix;
    WWTexture* texture;
    WWColor* color;
    // Picking attributes.
    WWPickSupport* pickSupport;
    WWLayer* pickLayer;
}

/// @name Attributes

@property (nonatomic) NSString* displayName;

@property (nonatomic) BOOL enabled;

@property (nonatomic) WWOffset* screenOffset;

@property (nonatomic) NSString* imagePath;

@property (nonatomic) WWColor* imageColor;

@property (nonatomic) WWOffset* imageOffset;

@property (nonatomic) WWSize* imageSize;

@property (nonatomic) id pickDelegate;

@property (nonatomic) double eyeDistance;

@property (nonatomic) NSTimeInterval insertionTime;

/// A field for application-specific use, typically used to associate application data with the shape.
@property (nonatomic) id userObject;

/// @name Initializing Screen Images

- (WWScreenImage*) initWithScreenOffset:(WWOffset*)screenOffset imagePath:(NSString*)imagePath;

/// @name Methods of Interest Only to Subclasses

- (void) makeOrderedRenderable:(WWDrawContext*)dc;

- (void) doMakeOrderedRenderable:(WWDrawContext*)dc;

- (void) assembleActiveTexture:(WWDrawContext*)dc;

- (void) drawOrderedRenderable:(WWDrawContext*)dc;

- (void) doDrawOrderedRenderable:(WWDrawContext*)dc;

- (void) beginDrawing:(WWDrawContext*)dc;

- (void) endDrawing:(WWDrawContext*)dc;

- (WWPickedObject*) createPickedObject:(WWDrawContext*)dc colorCode:(unsigned int)colorCode;

@end