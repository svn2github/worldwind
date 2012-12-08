/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import <Foundation/Foundation.h>

@interface WWLocation : NSObject <NSCopying>

@property (nonatomic) double latitude;
@property (nonatomic) double longitude;

- (WWLocation*) initWithDegreesLatitude:(double)latitude longitude:(double)longitude;

- (WWLocation*) add:(WWLocation*)location;
- (WWLocation*) subtract:(WWLocation*)location;


@end
