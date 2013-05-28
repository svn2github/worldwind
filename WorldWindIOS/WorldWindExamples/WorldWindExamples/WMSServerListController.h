/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import <Foundation/Foundation.h>

@class WorldWindView;

/**
* A view controller showing the list of available WMS servers and providing a way to add and delete them and view
* their details. The server list is persisted across application sessions.
*/
@interface WMSServerListController : UITableViewController <UIAlertViewDelegate>
{
    NSMutableArray* servers; // The servers in the list. Each entry holds the server address and sever title.
    UIBarButtonItem* addButton;
}

/// @name Server List Controller Attributes

/// Returns the World Wind View specified at initialization.
@property (nonatomic, readonly) WorldWindView* wwv;

/// @name Initializing Server List Controllers

/**
* Initializes this instance.
*
* @param wwv The application's World Wind View.
*
* @return The initialized instance.
*
* @exception NSInvalidArgumentException if the specified World Wind View is nil.
*/
- (WMSServerListController*) initWithWorldWindView:(WorldWindView*)wwv;

@end