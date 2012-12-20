/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import "WWUtil.h"


@implementation WWUtil

+ (NSString*) generateUUID
{
    // Taken from here: http://stackoverflow.com/questions/8684551/generate-a-uuid-string-with-arc-enabled

    CFUUIDRef uuid = CFUUIDCreate(NULL);
    NSString *uuidStr = (__bridge_transfer NSString *)CFUUIDCreateString(NULL, uuid);
    CFRelease(uuid);

    return uuidStr;
}

@end