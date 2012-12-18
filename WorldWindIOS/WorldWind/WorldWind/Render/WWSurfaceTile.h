/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

@class WWSector;
@class WWDrawContext;
@class WWMatrix;

@protocol WWSurfaceTile

- (WWSector*) sector;

- (BOOL) bind:(WWDrawContext*)dc;

@end