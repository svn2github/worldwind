/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.

 @version $Id$
 */

#import <Foundation/Foundation.h>
#import "WorldWind/Util/WWUrlBuilder.h"

/**
* Provides a WWUrlBuilder implementation for forming URLs for the ArcGIS Export Map operation. This implementation
* provides support for generating Export Map URLs with the following parameters: _bbox_, _size_, _imageSR_, _bboxSR_,
* _format_, _layers_, and _transparent_. All remaining parameters are left unspecified. See the following ESRI help
* document for more information on the ArcGIS API:
* http://resources.arcgis.com/en/help/rest/apiref/
*/
@interface WWArcGisUrlBuilder : NSObject <WWUrlBuilder>

/// @name Attributes

/**
 * The URL scheme, host and path to the ArcGIS Map Service resource, e.g.,
 * _http://<catalog-url>/<serviceName>/MapServer_
 *
 * Indicates the ArcGIS server as well as the desired service within the ArcGIS REST hierarchy. If this URL builder is
 * used to configure a WWTiledImageLayer, the service location must indicate a Map Service resource that supports the
 * Export Map operation.
 *
 * To inject custom request parameters into the URL returned by urlForTile:imageFormat:, specify a service location with
 * the following format: _http://<catalog-url>/<serviceName>/MapServer/export?customParam1=customValue1_.
 * WWArcGisUrlBuilder preserves custom request parameters specified in the service location by adding URL components
 * only when they are not included in the service location. The following URL components are automatically included by
 * WWArcGisUrlBuilder:
 *
 * - Path for the Export Map operation _/export_
 * - Query string delimiter _?_
 * - Query parameter delimiter _&_
 */
@property(nonatomic, readonly) NSString* serviceLocation;

/**
 * The _layers_ parameter of the URL, e.g. _layers=show:0,1,2_
 *
 * Indicates which ArcGIS layers are included in the ArcGIS server's image response. This may be an empty string
 * indicating that all layers are included, or a list of layers to include or exclude. The list of layers consists of
 * one or more layer IDs defined by the Map Service resource. There are four ways to specify the list of layers:
 *
 * - show:layerId1,layerId2 - Only the specified layers are included.
 * - hide:layerId1,layerId2 - All layers except the specified layers are included.
 * - include:layerId1,layerId2 - Include all default layers and add the specified layers.
 * - exclude:layerId1,layerId2 - Include all default layers but remove the specified layers.
 */
@property(nonatomic, readonly) NSString* layers;

/**
* The _v_ parameter of the URL, e.g. _v=10.0_
*
* Indicates the version of the ArcGIS server that the URL request is intended for, and the version of the ArcGIS server
* response that this client expects. Defaults to "10.0" if the arcGisVersion parameter specified during initialization is
* nil.
*/
@property(nonatomic, readonly) NSString* arcGisVersion;

/**
 * The _imageSR_ spatial reference parameter of the URL, e.g. _imageSR=4326_
 *
 * Indicates the spatial reference of the ArcGIS server's image response. Can be either a well-known ID or a spatial
 * reference JSON object. Defaults to "4326".
 */
@property(nonatomic) NSString* imageSR;

/**
* The _transparent_ parameter of the URL, e.g. _transparent=true_
*
* Indicates whether the ArcGIS server's image response contains transparent pixels or the map background color in
* regions with no data. YES indicates transparent pixels, while NO indicates the map background color. This has no
* effect if the image format is anything other than png. Defaults to YES.
*/
@property(nonatomic) BOOL transparent;

/// @name Initializing a URL Builder

/**
* Initializes this ArcGIS URL builder.
*
* @param serviceLocation The URL scheme, host and path to the ArcGIS Map Service resource, e.g.,
* _http://<catalog-url>/<serviceName>/MapServer_
* @param layers The _layers_ parameter of the URL, e.g. _layers=show:0,1,2_
* @param arcGisVersion The _v_ parameter of the URL, e.g. _v=10.0_
*
* @return The initialized URL builder.
*
* @exception NSInvalidArgumentException if the service location or layer names are nil.
*/
- (WWArcGisUrlBuilder*) initWithServiceLocation:(NSString*)serviceLocation
                                         layers:(NSString*)layers
                                  arcGisVersion:(NSString*)arcGisVersion;

@end