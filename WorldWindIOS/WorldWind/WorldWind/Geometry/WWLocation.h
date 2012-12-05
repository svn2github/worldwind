/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import <Foundation/Foundation.h>

@interface WWLocation : NSObject <NSCopying>

@property double latitude;
@property double longitude;

- (WWLocation*) initWithDegreesLatitude:(double)latitude longitude:(double)longitude;

- (WWLocation*) add:(WWLocation*)location;
- (WWLocation*) subtract:(WWLocation*)location;


@end
