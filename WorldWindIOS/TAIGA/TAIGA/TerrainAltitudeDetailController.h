/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import <Foundation/Foundation.h>

@class WWElevationShadingLayer;

@interface TerrainAltitudeDetailController : UITableViewController

@property (readonly, nonatomic, weak) WWElevationShadingLayer* layer;

- (TerrainAltitudeDetailController*) initWithLayer:(WWElevationShadingLayer*)layer;

@end