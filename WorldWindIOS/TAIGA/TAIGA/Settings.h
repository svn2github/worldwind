/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import <Foundation/Foundation.h>

@interface Settings : NSObject

+ (void) setFloat:(float)value forName:(NSString*)name;
+ (float) getFloatForName:(NSString*)name defaultValue:(float)defaultValue;
+ (float) getFloatForName:(NSString*)name;

@end