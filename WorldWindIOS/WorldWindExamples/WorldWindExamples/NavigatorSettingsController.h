/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import <Foundation/Foundation.h>

@class WorldWindView;

@interface NavigatorSettingsController : UITableViewController
{
@protected
    NSArray* modelTypes;
    id selectedModelType;
}

@property (nonatomic, readonly) WorldWindView* wwv;

- (NavigatorSettingsController*) initWithWorldWindView:(WorldWindView*)wwv;

@end