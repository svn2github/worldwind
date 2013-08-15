/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import <Foundation/Foundation.h>
#import "WorldWind/Util/WWUrlBuilder.h"

@class WWWMSCapabilities;
@class WWWMSDimension;

/**
* Provides a WWUrlBuilder implementation for forming WMS URLs.
*/
@interface WWWMSUrlBuilder : NSObject <WWUrlBuilder>
{
@protected
    NSString* urlTemplate; // the common elements of the URL, computed once then cached here
    BOOL isWMS13OrGreater;
}

/// @name Attributes

/// The URL scheme, host and path to the WMS server, e.g., _http://data.worldwind.arc.nasa.gov/wms_
@property(nonatomic, readonly) NSString* serviceAddress;

/// The comma separated layer names to include in the URL.
@property(nonatomic, readonly) NSString* layerNames;

/// The comma separated style names to include in the URL.
@property(nonatomic, readonly) NSString* styleNames;

/// The WMS version to include in the URL, e.g. _1.3.0_
@property(nonatomic, readonly) NSString* wmsVersion;

/// The WMS dimension associated with this builder's layer.
@property (nonatomic) WWWMSDimension* dimension;

/// The WMS dimension string associated with this builder's layer.
@property (nonatomic) NSString* dimensionString;

/// The reference system parameter, e.g. _&crs=CRS:84_, to include in the URL. This parameter is determined from the
// WMS version during initialization.
@property(nonatomic) NSString* crs;

/// Indicates the sense of the _transparent_ parameter in the URL. YES (the default) implies TRUE,
// NO implies FALSE.
@property (nonatomic) BOOL transparent;

/// @name Initializing a URL Builder

/**
* Initialize a URL builder.
*
* @param serviceAddress The URL scheme, host and path to the WMS server, e.g.,
* _http://data.worldwind.arc.nasa.gov/wms_.
* @param layerNames A comma separated list of layer names to include in the URL.
* @param styleNames A comma separated list of style names to include in the URL. May be nil indicating no styles.
* @param wmsVersion The WMS version to include in the URL, e.g. _1.3.0_. May be nil indicating the most recent
* version supported.
*
* @return The initialized URL builder.
*
* @exception NSInvalidArgumentException if the service location or layer names are nil.
*/
- (WWWMSUrlBuilder*) initWithServiceAddress:(NSString*)serviceAddress
                                 layerNames:(NSString*)layerNames
                                 styleNames:(NSString*)styleNames
                                 wmsVersion:(NSString*)wmsVersion;

- (WWWMSUrlBuilder*) initWithServiceCapabilities:(WWWMSCapabilities*)serviceCaps
                                       layerCaps:(NSDictionary*)layerCaps;

/// @name Methods used only by subclasses

/**
* Returns the WMS layer names for the current request.
*
* This method may consult the provided draw context to determine the layer names. For example,
* it may return different layer names depending on the tile's resolution.
*
* @param tile The tile for which to determine the layer names.
*/
- (NSString*)layersParameter:(WWTile*)tile;

/**
* Returns the WMS style names for the current request.
*
* This method may consult the provided tile to determine the style names. For example,
* it may return different layer names depending on the tile's resolution.
*
* @param tile The tile for which to determine the layer names.
*/
- (NSString*)stylesParameter:(WWTile*)tile;

@end