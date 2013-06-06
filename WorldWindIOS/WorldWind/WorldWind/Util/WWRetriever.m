/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import "WorldWind/Util/WWRetriever.h"
#import "WorldWind/WorldWind.h"

@implementation WWRetriever

- (WWRetriever*) initWithUrl:(NSURL*)url
                   timeout:(NSTimeInterval)timeout
             finishedBlock:(void (^) (WWRetriever*))finishedBlock;
{
    if (url == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"URL is nil")
    }

    if (finishedBlock == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Finished block is nil")
    }

    self = [super init];

    _url = url;
    _timeout = timeout;
    finished = finishedBlock;

    _retrievedData = [[NSMutableData alloc] init];

    return self;
}

- (void) main
{
    [self performRetrieval];
}

- (void) performRetrieval
{
    if (![WorldWind isNetworkAvailable])
    {
        _status = WW_CANCELED;
        [self doFinish];
    }
    else
    {
        @try
        {
            [WorldWind setNetworkBusySignalVisible:YES];

            NSURLRequest* request = [[NSURLRequest alloc] initWithURL:_url
                                                          cachePolicy:NSURLRequestReloadIgnoringLocalCacheData
                                                      timeoutInterval:_timeout];
            NSURLConnection* connection = [[NSURLConnection alloc] initWithRequest:request delegate:self
                                                                  startImmediately:YES];

            if (![NSThread isMainThread])
            {
                // Set up this thread to remain running until all the data has been retrieved.
                // See http://www.cocoaintheshell.com/2011/04/nsurlconnection-synchronous-asynchronous/
                // If this is not done, this thread's delegate methods do not get called because they're called on the
                // thread that created the connection (this thread) but that thread exits at the end of this method, which
                // is before the delegates are called. Thus when the connection tries to call the delegates the thread to
                // call them on doesn't exist.
                NSRunLoop* runLoop = [NSRunLoop currentRunLoop];
                [connection scheduleInRunLoop:runLoop forMode:NSDefaultRunLoopMode];
                [connection start];
                [runLoop runUntilDate:[NSDate distantFuture]];
            }
        }
        @catch (NSException* exception)
        {
            [WorldWind setNetworkBusySignalVisible:NO];

            NSString* msg = [NSString stringWithFormat:@"Retrieving %@", _url];
            WWLogE(msg, exception);
        }
    }
}

- (void) connection:(NSURLConnection*)connection didFailWithError:(NSError*)error
{
    [WorldWind setNetworkBusySignalVisible:NO];
    _status = WW_FAILED;
    [self doFinish];
}

- (void) connection:(NSURLConnection*)connection didReceiveResponse:(NSURLResponse*)response
{
    [_retrievedData setLength:0];
}

- (void) connection:(NSURLConnection*)connection didReceiveData:(NSData*)data
{
    [_retrievedData appendData:data];
}

- (void) connectionDidFinishLoading:(NSURLConnection*)connection
{
    [WorldWind setNetworkBusySignalVisible:NO];

    _status = WW_SUCCEEDED;
    [self doFinish];
}

- (void) doFinish
{
    @try
    {
        finished(self);
    }
    @catch (NSException* exception)
    {
        NSString* msg = [NSString stringWithFormat:@"Finishing retrieval of %@", _url];
        WWLogE(msg, exception);
    }
    @finally
    {
        [self stopRunLoop];
    }
}

- (NSCachedURLResponse*) connection:(NSURLConnection*)connection willCacheResponse:(NSCachedURLResponse*)cachedResponse
{
    return nil; // prevent caching in order to avoid excessive memory usage
}

- (void) stopRunLoop
{
    if (![NSThread isMainThread])
    {
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.01]];
    }
}

@end