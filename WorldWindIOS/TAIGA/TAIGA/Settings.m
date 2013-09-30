/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import "Settings.h"
#import "AppConstants.h"

@implementation Settings

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

@end