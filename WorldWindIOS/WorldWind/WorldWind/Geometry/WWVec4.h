/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import <Foundation/Foundation.h>

@class WWVec4; // forward delcaration for use in externs below

extern WWVec4 const * WWVEC4_ZERO;
extern WWVec4 const * WWVEC4_ONE;
extern WWVec4 const * WWVEC4_UNIT_X;
extern WWVec4 const * WWVEC4_UNIT_Y;
extern WWVec4 const * WWVEC4_UNIT_Z;

@interface WWVec4 : NSObject <NSCopying>

@property double x;
@property double y;
@property double z;
@property double w;

- (WWVec4*) initWithCoordinates:(double)x y:(double)y z:(double)z;
- (WWVec4*) initWithCoordinates:(double)x y:(double)y z:(double)z w:(double)w;

- (WWVec4*) add3:(WWVec4*)vector;
- (WWVec4*) subtract3:(WWVec4*)vector;


@end
