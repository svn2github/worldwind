/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.

 @version $Id$
 */

#import <Foundation/Foundation.h>

@class WaypointFile;

@interface WaypointChooserControl : UIView<UISearchBarDelegate, UITableViewDataSource, UITableViewDelegate>
{
@protected
    NSArray* waypoints;
    UISearchBar* waypointSearchBar;
    UITableView* waypointTable;
}

@property (nonatomic, readonly) id target;

@property (nonatomic, readonly) SEL action;

@property (nonatomic) WaypointFile* dataSource;

- (WaypointChooserControl*) initWithFrame:(CGRect)frame target:(id)target action:(SEL)action;

@end