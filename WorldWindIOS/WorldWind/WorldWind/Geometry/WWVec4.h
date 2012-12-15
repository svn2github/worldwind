/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import <Foundation/Foundation.h>

@interface WWVec4 : NSObject <NSCopying>

@property (nonatomic) double x;
@property (nonatomic) double y;
@property (nonatomic) double z;
@property (nonatomic) double w;

- (WWVec4*) initWithCoordinates:(double)x y:(double)y z:(double)z;
- (WWVec4*) initWithCoordinates:(double)x y:(double)y z:(double)z w:(double)w;
- (WWVec4*) initWithZeroVector;
- (WWVec4*) initWithUnitVector;

- (WWVec4*) set:(double)x y:(double)y;

- (WWVec4*) set:(double)x y:(double)y z:(double)z;

- (WWVec4*) set:(double)x y:(double)y z:(double)z w:(double)w;

- (double) getLength3;

- (WWVec4*) normalize3;

- (WWVec4*) add3:(WWVec4*)vector;

- (WWVec4*) subtract3:(WWVec4*)vector;

@end
