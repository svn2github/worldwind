/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import "WorldWind/Util/WWRetriever.h"
#import "WorldWind/Util/WWUtil.h"
#import "WorldWind/WorldWind.h"

@implementation WWRetriever

- (WWRetriever*) initWithUrl:(NSURL*)url filePath:(NSString*)filePath object:(id)object
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

    return self;
}

- (void) main
{
    NSMutableDictionary* dict = [[NSMutableDictionary alloc] init];
    [dict setObject:_filePath forKey:WW_FILE_PATH];
    [dict setObject:_url forKey:WW_URL];
    NSNotification* notification = [NSNotification notificationWithName:WW_RETRIEVAL_STATUS
                                                                 object:_object
                                                               userInfo:dict];
    @try
    {
        if (![self isCancelled])
        {
            if ([WWUtil retrieveUrl:_url toFile:_filePath])
            {
                [dict setObject:WW_RETRIEVAL_SUCCEEDED forKey:WW_RETRIEVAL_STATUS];
            }
            else
            {
                [dict setObject:WW_RETRIEVAL_FAILED forKey:WW_RETRIEVAL_STATUS];
            }
        }
        else
        {
            [dict setObject:WW_RETRIEVAL_CANCELED forKey:WW_RETRIEVAL_STATUS];
        }
    }
    @catch (NSException* exception)
    {
        [dict setObject:WW_RETRIEVAL_FAILED forKey:WW_RETRIEVAL_STATUS];

        NSString* msg = [NSString stringWithFormat:@"Retrieving %@ to %@", _url, _filePath];
        WWLogE(msg, exception);
    }
    @finally
    {
        [[NSNotificationCenter defaultCenter] postNotification:notification];
    }
}

- (void) addToQueue:(WWRetriever*)retriever
{
    if (retriever == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Retriever is nil")
    }

    [[WorldWind retrievalQueue] addOperation:retriever];
}

@end