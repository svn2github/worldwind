/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.

 @version $Id$
 */

#import <Foundation/Foundation.h>

@class AircraftTrackLayer;

@interface AircraftTrackDetailController : UITableViewController
{
@protected
    NSMutableArray* tableCells;
}

@property (readonly, nonatomic, weak) AircraftTrackLayer* layer;

- (id) initWithLayer:(AircraftTrackLayer*)layer;

@end