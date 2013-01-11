/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import "WorldWind/WorldWindConstants.h"
#import "WorldWind/WWLog.h"

/**
* Provides access to World Wind singletons.
*/
@interface WorldWind : NSObject

/**
* Returns the singleton World Wind retrieval queue.
*
* @return The World Wind retrieval queue.
*/
+ (NSOperationQueue*) retrievalQueue;

@end
