/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import <Foundation/Foundation.h>

@class WorldWindView;

@interface WMSServerListController : UITableViewController <UIAlertViewDelegate>
{
    NSMutableArray* servers;
    UIBarButtonItem* addButton;
}

@property (nonatomic, readonly) WorldWindView* wwv; // TODO: This may not be needed

- (WMSServerListController*) initWithWorldWindView:(WorldWindView*)wwv;

@end