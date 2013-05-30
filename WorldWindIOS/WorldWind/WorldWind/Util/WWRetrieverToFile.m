/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import "WorldWind/Util/WWRetrieverToFile.h"
#import "WorldWind/WorldWind.h"

@implementation WWRetrieverToFile

- (WWRetrieverToFile*) initWithUrl:(NSURL*)url
                          filePath:(NSString*)filePath
                            object:(id)object
                           timeout:(NSTimeInterval)timeout
{
    if (url == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"URL is nil")
    }

    if (filePath == nil || [filePath length] == 0)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"File path is nil or empty")
    }

    self = [super init];

    _url = url;
    _filePath = filePath;
    _object = object;
    _timeout = timeout;

    responseDictionary = [[NSMutableDictionary alloc] init];
    [responseDictionary setObject:_filePath forKey:WW_FILE_PATH];
    [responseDictionary setObject:_url forKey:WW_URL];

    retrievedData = [[NSMutableData alloc] init];

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
        [responseDictionary setObject:WW_CANCELED forKey:WW_RETRIEVAL_STATUS];
        [self sendNotification];
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
                                                                  startImmediately:NO];

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

            NSString* msg = [NSString stringWithFormat:@"Retrieving %@ to %@", _url, _filePath];
            WWLogE(msg, exception);

            [responseDictionary setObject:WW_FAILED forKey:WW_RETRIEVAL_STATUS];
            [self sendNotification];
        }
    }
}

- (void) connection:(NSURLConnection*)connection didFailWithError:(NSError*)error
{
    [WorldWind setNetworkBusySignalVisible:NO];

    [responseDictionary setObject:WW_FAILED forKey:WW_RETRIEVAL_STATUS];
    [self sendNotification];
    [self stopRunLoop];
}

- (void) connection:(NSURLConnection*)connection didReceiveResponse:(NSURLResponse*)response
{
    [retrievedData setLength:0];
}

- (void) connection:(NSURLConnection*)connection didReceiveData:(NSData*)data
{
    [retrievedData appendData:data];
}

- (void) connectionDidFinishLoading:(NSURLConnection*)connection
{
    [WorldWind setNetworkBusySignalVisible:NO];
    [self writeDataToFile];
    [self sendNotification];
    [self stopRunLoop];
}

- (NSCachedURLResponse*) connection:(NSURLConnection*)connection willCacheResponse:(NSCachedURLResponse*)cachedResponse
{
    return nil; // prevent caching in order to avoid excessive memory usage
}

- (void) writeDataToFile
{
    @try
    {
        // Ensure that the directory for the file exists.
        NSError* error = nil;
        NSString* pathDir = [_filePath stringByDeletingLastPathComponent];
        [[NSFileManager defaultManager] createDirectoryAtPath:pathDir
                                  withIntermediateDirectories:YES attributes:nil error:&error];
        if (error != nil)
        {
            [responseDictionary setObject:WW_FAILED forKey:WW_RETRIEVAL_STATUS];
            WWLog("@Error \"%@\" creating path %@", [error description], _filePath);
            return;
        }

        // Write the data to the file.
        [retrievedData writeToFile:_filePath options:NSDataWritingAtomic error:&error];
        if (error != nil)
        {
            [responseDictionary setObject:WW_FAILED forKey:WW_RETRIEVAL_STATUS];
            WWLog("@Error \"%@\" writing file %@", [error description], _filePath);
            return;
        }

        [responseDictionary setObject:WW_SUCCEEDED forKey:WW_RETRIEVAL_STATUS];
    }
    @catch (NSException* exception)
    {
        [responseDictionary setObject:WW_FAILED forKey:WW_RETRIEVAL_STATUS];

        NSString* msg = [NSString stringWithFormat:@"Saving %@ to %@", _url, _filePath];
        WWLogE(msg, exception);
    }
}

- (void) sendNotification
{
    NSNotification* notification = [NSNotification notificationWithName:WW_RETRIEVAL_STATUS
                                                                 object:_object
                                                               userInfo:responseDictionary];
    [[NSNotificationCenter defaultCenter] postNotification:notification];
}

- (void) stopRunLoop
{
    if (![NSThread isMainThread])
    {
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.01]];
    }
}
@end