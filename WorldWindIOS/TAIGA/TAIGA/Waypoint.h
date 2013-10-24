/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.

 @version $Id$
 */

#import <Foundation/Foundation.h>

@class WWLocation;

@interface Waypoint : NSObject

@property (nonatomic, readonly) NSString* key;

@property (nonatomic, readonly) WWLocation* location;

@property (nonatomic) NSString* displayName;

@property (nonatomic) NSString* displayNameLong;

@property (nonatomic) NSDictionary* properties;

- (Waypoint*) initWithKey:(NSString*)key location:(WWLocation*)location;

@end