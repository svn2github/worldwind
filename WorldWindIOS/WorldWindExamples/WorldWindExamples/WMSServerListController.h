/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import <Foundation/Foundation.h>

@class WorldWindView;

@interface WMSServerListController : UITableViewController
{
    NSMutableArray* servers;
}

@property (nonatomic, readonly) WorldWindView* wwv;

- (WMSServerListController*) initWithWorldWindView:(WorldWindView*)wwv;

@end