/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import <Foundation/Foundation.h>

@class WorldWindView;
@class WWWMSCapabilities;

@interface WMSLayerDetailController : UITableViewController
{
    NSString* layerID;
}

@property(nonatomic, readonly) WWWMSCapabilities* serverCapabilities;
@property(nonatomic, readonly) NSDictionary* layerCapabilities;
@property(nonatomic, readonly) WorldWindView* wwv;

- (WMSLayerDetailController*) initWithLayerCapabilities:(WWWMSCapabilities*)serverCapabilities
                                      layerCapabilities:(NSDictionary*)layerCapabilities
                                                   size:(CGSize)size
                                                 wwView:(WorldWindView*)wwv;

@end