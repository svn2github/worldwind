/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import <Foundation/Foundation.h>

@class WWSector;
@class WWLevel;

@interface WWTile : NSObject

@property (readonly) WWSector* sector;
@property (readonly) int level;
@property (readonly) int row;
@property (readonly) int column;

- (WWTile*) initWithSector:(WWSector*)sector level:(int)level row:(int)row column:(int)column;

@end
