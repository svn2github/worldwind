/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.

 @version $Id$
 */

#import <Foundation/Foundation.h>

@interface WaypointFileControl : UIView<UISearchBarDelegate, UITableViewDataSource, UITableViewDelegate>
{
@protected
    NSMutableArray* filteredWaypoints;
    UISearchBar* waypointSearchBar;
    UITableView* waypointTable;
}

@property (nonatomic, readonly, weak) id target;

@property (nonatomic, readonly) SEL action;

@property (nonatomic) NSArray* waypoints;

- (WaypointFileControl*) initWithFrame:(CGRect)frame target:(id)target action:(SEL)action;

- (void) flashScrollIndicators;

@end