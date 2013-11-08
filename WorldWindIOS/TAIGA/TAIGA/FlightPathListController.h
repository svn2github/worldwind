/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.

 @version $Id$
 */

#import <Foundation/Foundation.h>
#import "FlightPathDelegate.h"

@class WaypointFile;
@class WWRenderableLayer;

@interface FlightPathListController : UITableViewController <UINavigationControllerDelegate, UIAlertViewDelegate, FlightPathDelegate>
{
@protected
    WaypointFile* waypointFile;
    NSUInteger flightPathColorIndex;
}

@property (nonatomic, readonly) WWRenderableLayer* layer;

- (FlightPathListController*) initWithLayer:(WWRenderableLayer*)layer;

@end