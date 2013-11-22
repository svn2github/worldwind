/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import <Foundation/Foundation.h>

@interface WeatherCamViewController : UIViewController <UIScrollViewDelegate>

-(WeatherCamViewController*)init;

- (void) setSiteInfo:(NSObject*) entries;

@end