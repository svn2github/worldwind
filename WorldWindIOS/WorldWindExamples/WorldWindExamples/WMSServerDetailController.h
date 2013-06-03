/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import <Foundation/Foundation.h>

@class WWWMSCapabilities;
@class WorldWindView;

/**
* Displays the details of a WMS server and allows selection of its layers.
*/
@interface WMSServerDetailController : UITableViewController
{
    UIBarButtonItem* refreshButton;
}

/// @name WMS Server Detail Controller Attributes

/// The World Wind View specified at initialization.
@property(nonatomic, readonly) WorldWindView* wwv;

/// The WMS server capabilities specified at initialization.
@property(nonatomic, readonly) WWWMSCapabilities* capabilities;

/// The web address of the WMS server.
@property(nonatomic, readonly) NSString* serverAddress;

/// @name Initializing WMS Server Detail Controller

/**
* Initialize this instance.
*
* @param capabilities The WMS capabilities of the associated server.
* @param serverAddress The web address of the WMS server.
* @param wwv The application's World Wind View.
*
* @return The initialized instance.
*
* @exception NSInvalidArgumentException If the specified server capabilities is nil.
* @exception NSInvalidArgumentException If the specified server address is nil or empty.
* @exception NSInvalidArgumentException If the specified World Wind View is nil.
*/
- (WMSServerDetailController*) initWithCapabilities:(WWWMSCapabilities*)capabilities
                                      serverAddress:(NSString*)serverAddress
                                             wwview:(WorldWindView*)wwv;

@end