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
@interface WWDAFIFLayer : WWRenderableLayer

/// @name Initializing the DAFIF Layer

- (WWDAFIFLayer*) init;

@end