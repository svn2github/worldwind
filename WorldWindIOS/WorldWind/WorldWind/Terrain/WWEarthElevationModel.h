/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.

@version $Id $
 */

#import <Foundation/Foundation.h>
#import "WorldWind/Terrain/WWBasicElevationModel.h"

/**
* Provides an elevation model for Earth.
*/
@interface WWEarthElevationModel : WWBasicElevationModel

/// @name Initializing the Earth Elevation Model

/**
* Initializes an Earth Elevation Model.
*
* @return The initialized elevation model.
*/
- (WWEarthElevationModel*) init;

@end