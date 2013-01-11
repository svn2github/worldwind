/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import "WorldWind/WorldWind.h"

@implementation WorldWind

static NSOperationQueue* wwRetrievalQueue; // singleton instance

+ (void) initialize
{
    static BOOL initialized = NO; // protects against erroneous explicit calls to this method
    if (!initialized)
    {
        initialized = YES;
        wwRetrievalQueue = [[NSOperationQueue alloc] init];
    }
}

+ (NSOperationQueue*) retrievalQueue
{
    return wwRetrievalQueue;
}

@end
