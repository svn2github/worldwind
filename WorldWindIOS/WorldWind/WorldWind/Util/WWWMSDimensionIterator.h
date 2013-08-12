/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import <Foundation/Foundation.h>

/**
* Provides an iterator over the values in a WMS layer dimension.
*/
@protocol WWWMSDimensionIterator <NSObject>

/**
* Indicates whether the iterator has another value.
*
* @return YES if another value exists, otherwise NO.
*/
- (BOOL) hasNext;

/**
* Returns the next value of the iterator.
*
* If no more values exist then nil is returned and a log message is generated.
*
* @return The next dimension value.
*/
- (NSString*) next;

@end