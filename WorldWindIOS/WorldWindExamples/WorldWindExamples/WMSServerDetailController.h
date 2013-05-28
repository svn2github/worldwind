/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import <Foundation/Foundation.h>

@class WWWMSCapabilities;
@class WorldWindView;

@interface WMSServerDetailController : UITableViewController

@property(nonatomic, readonly) WorldWindView* wwv;
@property(nonatomic, readonly) WWWMSCapabilities* capabilities;
@property(nonatomic, readonly) NSString* serverAddress;

- (WMSServerDetailController*) initWithCapabilities:(WWWMSCapabilities*)capabilities
                                      serverAddress:(NSString*)serverAddress
                                               size:(CGSize)size
                                             wwview:(WorldWindView*)wwv;

@end