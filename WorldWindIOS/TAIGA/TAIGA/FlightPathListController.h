/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.

 @version $Id$
 */

#import <Foundation/Foundation.h>
#import "FlightPathDelegate.h"

@class WWRenderableLayer;

@interface FlightPathListController : UITableViewController <UINavigationControllerDelegate, UIAlertViewDelegate, FlightPathDelegate>
{
@protected
    NSMutableArray* waypointDatabase;
}

@property (nonatomic, readonly) WWRenderableLayer* layer;

- (FlightPathListController*) initWithLayer:(WWRenderableLayer*)layer;

@end