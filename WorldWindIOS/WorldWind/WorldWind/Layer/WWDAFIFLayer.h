/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import <Foundation/Foundation.h>
#import "WorldWind/Layer/WWTiledImageLayer.h"

/**
* Provides a multi-resolution layer for a version of the Digital Aeronautical Flight Information File (DAFIF) hosted on
* an ESRI ArcGIS server at http://faaservices-1551414968.us-east-1.elb.amazonaws.com/ArcGIS/. This data set displays
* aeronautical placemarks and shapes indicating airports, runways, airspaces, and routes. As for all layers, this layer
* must be added to the World Wind layer list in order to be displayed.
*
* The DAFIF data is retrieved from the ArcGIS Map Service resource located in the server's REST hierarchy at
* /rest/services/201101_AirportsGIS_BH/Dafif/MapServer. The data displayed depends on the current resolution, and is
* determined by the ArcGIS server. In general, the quantity and detail of map information increases with resolution.
*/
@interface WWDAFIFLayer : WWTiledImageLayer

/// @name Initializing the DAFIF Layer

/**
* Initializes this DAFIF layer with the specified ArcGIS data layers and cache name.
*
* @param layers Indicates which ArcGIS data layers are displayed by this layer. This may be an empty string indicating
* that all layers are displayed, or a list of layers to include or exclude. See [WWArcGisUrlBuilder layers] for more
* information.
* @param cacheName A unique alphanumeric string representing this layer's cache name.
*
* @return The initialized layer.
*/
- (WWDAFIFLayer*) initWithLayers:(NSString*)layers cacheName:(NSString*)cacheName;

/// @name Creating Pre-Configured DAFIF Layers

/**
* Returns an allocated and initialized WWDAFIFLayer configured to display all DAFIF data layers.
*
* The layer's maximum active altitude is configured so that the DAFIF layers are displayed at the appropriate altitude.
*
* @return A layer initialized to display all DAFIF data layers.
*/
+ (WWDAFIFLayer*) dafifAll;

/**
* Returns an allocated and initialized WWDAFIFLayer configured to display DAFIF layers related to airports.
*
* The layer's maximum active altitude is configured so that the DAFIF layers are displayed at the appropriate altitude.
*
* @return A layer initialized to display DAFIF airport layers.
*/
+ (WWDAFIFLayer*) dafifAirports;

/**
* Returns an allocated and initialized WWDAFIFLayer configured to display DAFIF layers related to VFR and IFR flight
* planning and navigation.
*
* The layer's maximum active altitude is configured so that the DAFIF layers are displayed at the appropriate altitude.
*
* @return A layer initialized to display DAFIF navigation layers.
*/
+ (WWDAFIFLayer*) dafifNavigation;

/**
* Returns an allocated and initialized WWDAFIFLayer configured to display DAFIF layers that delimit areas in which
* military and other activities may interfere with or preclude General Aviation flight.
*
* The layer's maximum active altitude is configured so that the DAFIF layers are displayed at the appropriate altitude.
*
* @return A layer initialized to display DAFIF General Aviation obstacle layers.
*/
+ (WWDAFIFLayer*) dafifObstacles;

@end