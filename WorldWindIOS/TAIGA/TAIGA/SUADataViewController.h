/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.

 @version $Id$
 */

#import <Foundation/Foundation.h>

@interface SUADataViewController : UITableViewController

@property(nonatomic) NSDictionary* entries;

- (SUADataViewController*) init;

- (void) flashScrollIndicator;

@end