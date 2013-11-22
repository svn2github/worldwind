/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.

 @version $Id$
 */

#import <Foundation/Foundation.h>

@class WaypointFile;
@class WorldWindView;
@class WWRenderableLayer;

@interface FlightRouteListController : UITableViewController <UINavigationControllerDelegate, UIAlertViewDelegate>
{
@protected
    NSUInteger flightRouteColorIndex;
}

@property (nonatomic, readonly) WaypointFile* waypointFile;

@property (nonatomic, readonly) WorldWindView* wwv;

@property (nonatomic, readonly) WWRenderableLayer* flightRouteLayer;

- (FlightRouteListController*) initWithWaypointFile:(WaypointFile*)waypointFile worldWindView:(WorldWindView*)wwv flightRouteLayer:(WWRenderableLayer*)flightRouteLayer;

@end