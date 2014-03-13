/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import "Settings.h"
#import "AppConstants.h"

@implementation Settings

+ (void) setObject:(id)object forName:(NSString*)name
{
    [[NSUserDefaults standardUserDefaults] setObject:object forKey:name];
    [[NSUserDefaults standardUserDefaults] synchronize];

    [[NSNotificationCenter defaultCenter] postNotificationName:TAIGA_SETTING_CHANGED object:name];
}

+ (id) getObjectForName:(NSString*)name defaultValue:(id)defaultValue
{
    id object = [[NSUserDefaults standardUserDefaults] objectForKey:name];
    if (object != nil)
        return object;

    [[NSUserDefaults standardUserDefaults] setObject:defaultValue forKey:name];

    return defaultValue;
}

+ (id) getObjectForName:(NSString*)name
{
    return [[NSUserDefaults standardUserDefaults] objectForKey:name];
}

+ (void) setFloat:(float)value forName:(NSString*)name
{
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithFloat:value] forKey:name];
    [[NSUserDefaults standardUserDefaults] synchronize];

    [[NSNotificationCenter defaultCenter] postNotificationName:TAIGA_SETTING_CHANGED object:name];
}

+ (float) getFloatForName:(NSString*)name defaultValue:(float)defaultValue
{
    NSNumber* value = [[NSUserDefaults standardUserDefaults] objectForKey:name];
    if (value != nil)
        return value.floatValue;

    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithFloat:defaultValue] forKey:name];

    return defaultValue;
}

+ (float) getFloatForName:(NSString*)name
{
    NSNumber* value = [[NSUserDefaults standardUserDefaults] objectForKey:name];

    return value != nil ? [value floatValue] : 0;
}

+ (void) setDouble:(double)value forName:(NSString*)name
{
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithDouble:value] forKey:name];
    [[NSUserDefaults standardUserDefaults] synchronize];

    [[NSNotificationCenter defaultCenter] postNotificationName:TAIGA_SETTING_CHANGED object:name];
}

+ (double) getDoubleForName:(NSString*)name defaultValue:(double)defaultValue
{
    NSNumber* value = [[NSUserDefaults standardUserDefaults] objectForKey:name];
    if (value != nil)
        return value.doubleValue;

    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithDouble:defaultValue] forKey:name];

    return defaultValue;
}

+ (double) getDoubleForName:(NSString*)name
{
    NSNumber* value = [[NSUserDefaults standardUserDefaults] objectForKey:name];

    return value != nil ? [value doubleValue] : 0;
}

+ (void) setInt:(int)value forName:(NSString*)name
{
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInt:value] forKey:name];
    [[NSUserDefaults standardUserDefaults] synchronize];

    [[NSNotificationCenter defaultCenter] postNotificationName:TAIGA_SETTING_CHANGED object:name];
}

+ (int) getIntForName:(NSString*)name defaultValue:(int)defaultValue
{
    NSNumber* value = [[NSUserDefaults standardUserDefaults] objectForKey:name];
    if (value != nil)
        return value.intValue;

    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInt:defaultValue] forKey:name];

    return defaultValue;
}

+ (int) getIntForName:(NSString*)name
{
    NSNumber* value = [[NSUserDefaults standardUserDefaults] objectForKey:name];

    return value != nil ? [value intValue] : 0;
}

+ (void) setLong:(long)value forName:(NSString*)name
{
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithLong:value] forKey:name];
    [[NSUserDefaults standardUserDefaults] synchronize];

    [[NSNotificationCenter defaultCenter] postNotificationName:TAIGA_SETTING_CHANGED object:name];
}

+ (long) getLongForName:(NSString*)name defaultValue:(long)defaultValue
{
    NSNumber* value = [[NSUserDefaults standardUserDefaults] objectForKey:name];
    if (value != nil)
        return value.longValue;

    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithLong:defaultValue] forKey:name];

    return defaultValue;
}

+ (long) getLongForName:(NSString*)name
{
    NSNumber* value = [[NSUserDefaults standardUserDefaults] objectForKey:name];

    return value != nil ? [value longValue] : 0;
}

+ (void) setBool:(BOOL)value forName:(NSString*)name
{
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:value] forKey:name];
    [[NSUserDefaults standardUserDefaults] synchronize];

    [[NSNotificationCenter defaultCenter] postNotificationName:TAIGA_SETTING_CHANGED object:name];
}

+ (BOOL) getBoolForName:(NSString*)name defaultValue:(BOOL)defaultValue
{
    NSNumber* value = [[NSUserDefaults standardUserDefaults] objectForKey:name];
    if (value != nil)
        return value.boolValue;

    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:defaultValue] forKey:name];

    return defaultValue;
}

+ (BOOL) getBoolForName:(NSString*)name
{
    NSNumber* value = [[NSUserDefaults standardUserDefaults] objectForKey:name];

    return value != nil ? [value boolValue] : 0;
}

@end