/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import <Foundation/Foundation.h>
#import "WWAbstractShape.h"

@class WWPosition;

@interface WWPath : WWAbstractShape
{
@protected
    NSMutableArray* tessellatedPositions;
    NSMutableArray* tessellationPoints;
}

@property (nonatomic) NSArray* positions;
@property (nonatomic) WWPosition* referencePosition;
@property (nonatomic) NSString* pathType;
@property (nonatomic) BOOL followTerrain;
@property (nonatomic) double terrainConformance;
@property (nonatomic) int numSubsegments;

- (WWPath*) initWithPositions:(NSArray*)positions;

@end