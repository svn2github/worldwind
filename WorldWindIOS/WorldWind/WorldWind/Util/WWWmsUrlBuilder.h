/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import <Foundation/Foundation.h>
#import "WorldWind/Util/WWUrlBuilder.h"

/**
* Provides a WWUrlBuilder implementation for forming WMS URLs.
*/
@interface WWWmsUrlBuilder : NSObject <WWUrlBuilder>
{
@protected
    NSString* urlTemplate; // the common elements of the URL, computed once then cached here
}

/// @name Attributes

/// The URL scheme, host and path to the WMS server, e.g., _http://data.worldwind.arc.nasa.gov/wms_
@property(nonatomic, readonly) NSString* serviceLocation;

/// The comma separated layer names to include in the URL.
@property(nonatomic, readonly) NSString* layerNames;

/// The comma separated style names to include in the URL.
@property(nonatomic, readonly) NSString* styleNames;

/// The WMS version to include in the URL, e.g. _1.3.0_
@property(nonatomic, readonly) NSString* wmsVersion;

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
* @param serviceLocation The URL scheme, host and path to the WMS server, e.g.,
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
- (WWWmsUrlBuilder*) initWithServiceLocation:(NSString*)serviceLocation
                                  layerNames:(NSString*)layerNames
                                  styleNames:(NSString*)styleNames
                                  wmsVersion:(NSString*)wmsVersion;

@end