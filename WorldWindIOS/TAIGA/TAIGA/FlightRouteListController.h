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
    WaypointFile* waypointFile;
    NSUInteger flightRouteColorIndex;
}

@property (nonatomic, readonly) WorldWindView* wwv;

@property (nonatomic, readonly) WWRenderableLayer* layer;

- (FlightRouteListController*) initWithWorldWindView:(WorldWindView*)wwv layer:(WWRenderableLayer*)layer;

@end