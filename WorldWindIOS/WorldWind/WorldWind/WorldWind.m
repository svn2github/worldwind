/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import "SystemConfiguration/SystemConfiguration.h"
#import "UIKit/UIKit.h"
#import "WorldWind/WorldWind.h"
#import "WorldWind/Util/WWResourceLoader.h"

@implementation WorldWind

static NSOperationQueue* wwRetrievalQueue; // singleton instance
static NSOperationQueue* wwLoadQueue; // singleton instance
static WWResourceLoader* wwResourceLoader; // singleton instance
static NSLock* wwNetworkBusySignalLock;
static BOOL wwOfflineMode = NO;
static NSLock* wwOfflineModeLock;

+ (void) initialize
{
    static BOOL initialized = NO; // protects against erroneous explicit calls to this method
    if (!initialized)
    {
        initialized = YES;

        wwRetrievalQueue = [[NSOperationQueue alloc] init];
        [wwRetrievalQueue setMaxConcurrentOperationCount:4];

        wwLoadQueue = [[NSOperationQueue alloc] init];
        [wwLoadQueue setMaxConcurrentOperationCount:4];

        wwResourceLoader = [[WWResourceLoader alloc] init];

        wwNetworkBusySignalLock = [[NSLock alloc] init];
        wwOfflineModeLock = [[NSLock alloc] init];
    }
}

+ (NSOperationQueue*) retrievalQueue
{
    return wwRetrievalQueue;
}

+ (NSOperationQueue*) loadQueue
{
    return wwLoadQueue;
}

+ (WWResourceLoader*) resourceLoader
{
    return wwResourceLoader;
}

+ (void) setNetworkBusySignalVisible:(BOOL)visible
{
    static int numCalls = 0;

    @synchronized (wwNetworkBusySignalLock)
    {
        if (visible)
            ++numCalls;
        else
            --numCalls;

        if (numCalls < 0)
            numCalls = 0;

        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:numCalls > 0];
    }
}

+ (void) setOfflineMode:(BOOL)offlineMode
{
    @synchronized (wwOfflineModeLock)
    {
        wwOfflineMode = offlineMode;
    }
}

+ (BOOL) isOfflineMode
{
    @synchronized (wwOfflineModeLock)
    {
        return wwOfflineMode;
    }
}

+ (BOOL) isNetworkAvailable
{
    SCNetworkReachabilityFlags flags;
    BOOL receivedFlags;

    SCNetworkReachabilityRef reachability = SCNetworkReachabilityCreateWithName(CFAllocatorGetDefault(),
            [@"google.com" UTF8String]);
    receivedFlags = SCNetworkReachabilityGetFlags(reachability, &flags);
    CFRelease(reachability);

    if (!receivedFlags || (flags == 0))
    {
        return NO;
    } else
    {
        return YES;
    }
}

@end
