/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import <Foundation/Foundation.h>

@interface Settings : NSObject

+ (void) setObject:(id)object forName:(NSString*)name;
+ (id) getObjectForName:(NSString*)name defaultValue:(id)defaultValue;
+ (id) getObjectForName:(NSString*)name;

+ (void) setFloat:(float)value forName:(NSString*)name;
+ (float) getFloatForName:(NSString*)name defaultValue:(float)defaultValue;
+ (float) getFloatForName:(NSString*)name;

+ (void) setDouble:(double)value forName:(NSString*)name;
+ (double) getDoubleForName:(NSString*)name defaultValue:(double)defaultValue;
+ (double) getDoubleForName:(NSString*)name;

+ (void) setInt:(int)value forName:(NSString*)name;
+ (int) getIntForName:(NSString*)name defaultValue:(int)defaultValue;
+ (int) getIntForName:(NSString*)name;

+ (void) setLong:(long)value forName:(NSString*)name;
+ (long) getLongForName:(NSString*)name defaultValue:(long)defaultValue;
+ (long) getLongForName:(NSString*)name;

+ (void) setBool:(BOOL)value forName:(NSString*)name;
+ (BOOL) getBoolForName:(NSString*)name defaultValue:(BOOL)defaultValue;
+ (BOOL) getBoolForName:(NSString*)name;

@end