/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import <Foundation/Foundation.h>

@class WorldWindView;


@interface LayerListController : UITableViewController

@property (nonatomic, readonly) WorldWindView* wwv;

- (LayerListController*) initWithWorldWindView:(WorldWindView*)wwv;

@end