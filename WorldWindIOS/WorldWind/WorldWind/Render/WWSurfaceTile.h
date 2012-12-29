/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

@class WWSector;
@class WWDrawContext;
@class WWMatrix;

/**
* Declares methods implemented by surface tiles to be rendered by WWSurfaceTileRenderer. Surface tiles
* manage a texture for display on a globe's terrain.
*/
@protocol WWSurfaceTile

/// @name Surface Tile Attributes

/**
* Returns the sector covered by this surface tile.
*
* @return The sector covered by this surface tile.
*/
- (WWSector*) sector;

/// @name Making a Surface Tile Active

/**
* Cause this surface tile's texture to be active, typically by calling glBindTexture.
*
* @param dc The current draw context.
*
* @return Yes if the resource was successfully bound, otherwise NO.
*/
- (BOOL) bind:(WWDrawContext*)dc;

@end