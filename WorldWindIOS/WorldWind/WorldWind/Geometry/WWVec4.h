/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import <Foundation/Foundation.h>

@interface WWVec4 : NSObject <NSCopying>

@property double x;
@property double y;
@property double z;
@property double w;

- (WWVec4*) initWithCoordinates:(double)x y:(double)y z:(double)z;
- (WWVec4*) initWithCoordinates:(double)x y:(double)y z:(double)z w:(double)w;
- (WWVec4*) initWithZeroVector;
- (WWVec4*) initWithUnitVector;

- (WWVec4*) add3:(WWVec4*)vector;
- (WWVec4*) subtract3:(WWVec4*)vector;


@end
