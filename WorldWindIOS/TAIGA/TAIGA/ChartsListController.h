/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import <Foundation/Foundation.h>

@class ChartsScreenController;

@interface ChartsListController : UITableViewController

- (ChartsListController*)initWithParent:(ChartsScreenController*)parent;
- (void) selectChart:(NSString*)chartFileName chartName:(NSString*)chartName;

@end