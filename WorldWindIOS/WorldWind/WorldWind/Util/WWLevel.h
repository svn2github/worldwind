/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import <Foundation/Foundation.h>

@class WWLocation;
@protocol WWUrlBuilder;
@class WWLevelSet;
@class WWSector;

/**
* Provides a class representing one level within a WWLevelSet. Applications typically do not interact with this class.
*/
@interface WWLevel : NSObject

/// @name Attributes

/// The WWLevelSet this level is a member of.
@property (nonatomic, readonly, weak) WWLevelSet* parent;

/// The number of this level.
@property (nonatomic, readonly) int levelNumber;

/// The geographic size of tiles in this level.
@property (nonatomic, readonly) WWLocation* tileDelta;

/// The size of pixels or elevation cells in this level.
@property (nonatomic, readonly) double texelSize;

/**
* Indicates the width in pixels or cells of the tile's resource.
*
* @return The width of the tile's resource in this level.
*/
- (int) tileWidth;

/**
* Indicates the height in pixels or cells of the tile's resource.
*
* @return The height of the tile's resource in this level.
*/
- (int) tileHeight;

/**
* Indicates the sector spanned by this level.
*
* @return The sector spanned by this level.
*/
- (WWSector*) sector;

/// @name Initializing Levels

/**
* Initialize this level.
*
* @param levelNumber The level's level number.
* @param tileDelta The geographic size of tiles in this level.
* @param parent The WWLevelSet this level is a member of.
*
* @return This level, initialized.
*/
- (WWLevel*) initWithLevelNumber:(int)levelNumber tileDelta:(WWLocation*)tileDelta parent:(WWLevelSet*)parent;

@end
