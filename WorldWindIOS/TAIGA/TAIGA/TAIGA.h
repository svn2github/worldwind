/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import <Foundation/Foundation.h>

@class AppUpdateController;
@class UnitsFormatter;

@interface TAIGA : NSObject

+ (AppUpdateController*) appUpdateController;

+ (UnitsFormatter*) unitsFormatter;

+ (NSArray*) waypoints;

+ (void) setWaypoints:(NSArray*)waypoints;

@end