/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import <Foundation/Foundation.h>
#import "WorldWind/Layer/WWLayer.h"
#import "WorldWind/Util/WWTileFactory.h"

@class WWLayer;
@class WWLevelSet;
@class WWSector;
@class WWLocation;
@class WWDrawContext;
@class WWTextureTile;
@protocol WWUrlBuilder;
@class WWLevel;
@class WWMemoryCache;

/**
* Provides a layer that displays multi-resolution imagery arranged as adjacent tiles. This is the primary World
* Wind base class for displaying imagery of this type. While it may be used as a stand-alone class,
* it is typically subclassed by classes that identify the remote image server and the local cache path.
*
* By default this class retrieves images from a remote server and caches them in the local file system once retrieved.
* Thereafter the local versions are used.
*
* While the image tiles for this class are typically drawn from a remote server such as a WMS server. The actual
* retrieval protocol is independent of this class and encapsulated by a class implementing the WWUrlBuilder
* protocol and associated with instances of this class as a property.
*
* There is no requirement that image tiles of this class be remote, they may be local or procedurally generated. For
* such cases the subclass overrides this class' retrieveTileImage method.
*
* Image retrieval occurs on a separate thread from the event dispatch thread. See retrieveTilImage for more
* information.
*/
@interface WWTiledImageLayer : WWLayer <WWTileFactory>
{
@protected
    WWLevelSet* levels;
    NSMutableArray* topLevelTiles;
    double detailHintOrigin;
    WWMemoryCache* tileCache;

    // Stuff computed each frame.
    NSMutableArray* currentTiles;
    WWTextureTile* currentAncestorTile;

    // The following field is used to prevent duplicate retrievals.
    NSMutableSet* currentRetrievals;
    NSMutableSet* currentLoads;
}

/// @name Attributes

/// The file system path to the local directory holding this instance's cached imagery.
@property(nonatomic, readonly) NSString* cachePath;

/// The image format to request from the remote server. The default is _image/png_.
@property(nonatomic, readonly) NSString* retrievalImageFormat;

/// A class implementing the WWUrlBuilder protocol for creating the URL identifying a specific image tile. For WMS
// tiled image layers the specified instance generates an HTTP URL for the WMS protocol. This property must be
// specified prior to using the layer. Although it is initialized to nil, it may not be nil when the layer becomes
// active.
@property(nonatomic) id <WWUrlBuilder> urlBuilder;

/// The current detail hint.
@property(nonatomic) double detailHint; // TODO: Document this per setDetailHint in the desktop/android version

/// The texture format to use for the OpenGL texture. One of WW_TEXTURE_RGBA_8888, WW_TEXTURE_RGBA_5551
// or WW_TEXTURE_PVRTC_4BPP. If nil, the texture is passed as RGBA 8888.
@property (nonatomic) NSString* textureFormat;

/// Indicates when this layer's textures should be considered invalid and re-retrieved from the associated server.
@property (nonatomic) NSDate* expiration;

/// @name Initializing Tiled Image Layers

/**
* Initializes a tiled image layer.
*
* @param sector The sector this layer covers.
* @param levelZeroDelta The size in latitude and longitude of level zero (lowest resolution) tiles.
* @param numLevels The number of levels to define for the layer. Each level is successively one power of two higher
* resolution than the next lower-numbered level. (0 is the lowest resolution level, 1 is twice that resolution, etc.)
* Each level contains four times as many tiles as the next lower-numbered level, each 1/4 the geographic size.
* @param retrievalImageFormat The mime type of the image format for the layer's tiles, e.g., _image/png_.
* @param cachePath The local file system location in which to store the layer's retrieved imagery.
*
* @return This tiled image layer, initialized.
*
* @exception NSInvalidArgumentException If the sector, level zero delta, image format or cache path are nil,
* or the specified number of levels is less than one.
*/
- (WWTiledImageLayer*) initWithSector:(WWSector*)sector
                       levelZeroDelta:(WWLocation*)levelZeroDelta
                            numLevels:(int)numLevels
                 retrievalImageFormat:(NSString*)retrievalImageFormat
                            cachePath:(NSString*)cachePath;

/// @name Methods of Interest Only to Subclasses

/**
* Once an image tile is determined to be in view and visible at the current eye position,
* adds the tile to the list of tiles to draw in the current frame.
*
* This method initiates image retrieval by calling retrieveTileImage if the image is not in the local image cache. In
 * that case, the tile is not added to the list of tiles to draw.
 *
 * This method is typically not overridden by subclasses.
*
* @param dc The current draw context.
* @param tile The tile to add.
*/
- (void) addTile:(WWDrawContext*)dc tile:(WWTextureTile*)tile;

/**
* Once a tile is determined to be in view, determines whether the tile or its descendants are added to the list of
* tiles to draw in the current frame.
*
* This method is typically not overridden by subclasses.
*
* @param dc The current draw context.
* @param tile The image tile to consider.
*/
- (void) addTileOrDescendants:(WWDrawContext*)dc tile:(WWTextureTile*)tile;

/**
* Determines which image tiles to display in the current frame.
*
* This method is typically not overridden by subclasses.
*
* @param dc The current draw context.
*/
- (void) assembleTiles:(WWDrawContext*)dc;

/**
* Creates an image tile corresponding to a specified sector and level. Implements the method of WWTileFactory.
*
* This method creates image tiles for the layer. The default implementation generates the file path to the tile's
* image file in the local file system cache and specifies that when initializing the newly created tile.
*
* This method is typically not overridden by subclasses.
*
* @param sector The sector over which the tile spans.
* @param level The tile's level.
* @param row The tile's row.
* @param column The tile's column.
*
* @return The new tile, initialized.
*/
- (WWTile*) createTile:(WWSector*)sector level:(WWLevel*)level row:(int)row column:(int)column;

/**
* Creates the top-level image tiles for this layer.
*
* This method creates the image tiles associated with level 0, the lowest resolution level.
*
* This method is typically not overridden by subclasses.
*/
- (void) createTopLevelTiles;

/**
* Overrides the doRender method of the WWLayer base class in order to draw the layer.
*
* @param dc The current draw context.
*/
- (void) doRender:(WWDrawContext*)dc;

/**
* Determines whether this layer has any region potentially within the view of the current frame.
*
* This method is called by the render method of WWLayer and should be overridden by subclasses if visibility is
* dependent on more than containment within the current visible sector or the current view frustum.
*
* @param dc The current draw context.
*
* @return YES if the layer is potentially in view, otherwise NO.
*/
- (BOOL) isLayerInView:(WWDrawContext*)dc;

/**
* Determines whether a specified tile of this layer is potentially within the view of the current frame.
*
* This method is called by assembleTiles to determine the potential visibility of individual tiles. It is typically
* not overridden by subclasses unless criteria other than view frustum containment exist.
*
* @param dc The current draw context.
* @param tile The tile to consider.
*
* @return YES if the tile is potentially visible, otherwise NO.
*/
- (BOOL) isTileVisible:(WWDrawContext*)dc tile:(WWTextureTile*)tile;

/**
* Forms the URL used to retrieve the specified tile's image. Called by retrieveTileImage.
*
* The default implementation of this method obtains the URL from the WWUrlBuilder associated with this layer instance.
*
* This method is called on a thread separate from the UI thread.
*
* @param tile The tile whose image URL is requested.
* @param imageFormat The image format of the requested image.
*
* @return The newly formed URL.
*
* @exception NSInvalidArgumentException If the tile is nil or the image format string is nil or empty.
* @exception NSInconsistentStateException If this layer instance has no WWUrlBuilder associated with it.
*/
- (NSURL*) resourceUrlForTile:(WWTile*)tile imageFormat:(NSString*)imageFormat;

/**
* Retrieves or reads from disk the image associated with a specified image tile of the layer.
*
* If the image file is already on disk, this method spawns a thread to read it and add it to the texture cache,
* otherwise
* this method retrieves the specified tile's image and writes it to the local file system image cache. By default the
 * image is retrieved using the URL generated by the WWUrlBuilder associated with this instance. It is saved to the
 * file system cache specified at initialization using a file name generated by this instance's createTile method.
 *
 * Subclasses may override this method to obtain or save the image in other ways. When the method terminates the
 * image should exist in the local file system image cache or be in the texture cache if it's already on disk.
 *
 * This method is called on a thread separate from the UI thread.
 *
 * If an error occurs reading, retrieving or saving the image an error message is logged.
 *
 * @param dc The current draw context.
 * @param tile The tile whose image to retrieve.
*/
- (void) loadOrRetrieveTileImage:(WWDrawContext*)dc tile:(WWTextureTile*)tile;

/**
* Indicates whether a specified tile meets the resolution criteria determining whether it is drawn in the current
* frame.
*
* @param dc The current draw context.
* @param tile The tile to consider.
*
* @return YES if the tile meets the render criteria, otherwise NO.
*/
- (BOOL) tileMeetsRenderCriteria:(WWDrawContext*)dc tile:(WWTextureTile*)tile;

/**
* Indicates whether a tile's texture image is in the memory cache.
*
* @param dc The current draw context.
* @param tile The tile in question.
*
* @return YES if the tile's texture is in the texture cache, otherwise NO.
*/
- (BOOL) isTileTextureInMemory:(WWDrawContext*)dc tile:(WWTextureTile*)tile;

/**
* Responds to WW_RETRIEVAL_STATUS notifications.
*
* @param notification The notification, which contains the URL (WW_URL), image path (WW_FILE_PATH) and retrieval
* status (WW_RETRIEVAL_STATUS) in its dictionary. The retrieval status is one of WW_SUCCEEDED,
* WW_FAILED or WW_CANCELED.
*/
- (void) handleTextureRetrievalNotification:(NSNotification*)notification;

/**
* Responds to WW_REQUEST_STATUS notifications.
*
* @param notification The notification, which contains the image path (WW_FILE_PATH) and retrieval
* status (WW_RETRIEVAL_STATUS) in its dictionary. The retrieval status is one of WW_SUCCEEDED,
* WW_FAILED or WW_CANCELED.
*/
- (void) handleTextureReadNotification:(NSNotification*)notification;

@end