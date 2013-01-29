/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import <UIKit/UIKit.h>
#import "LocationController.h"

@class WorldWindView;

@interface ViewController : UIViewController
{
@protected
    LocationController* initialLocationController;
    LocationController* trackingLocationController;
    UITapGestureRecognizer* doubleTapGestureRecognizer;
}

@property (nonatomic, readonly) WorldWindView* wwv;
@property (nonatomic, readonly) UIToolbar* toolbar;


@end