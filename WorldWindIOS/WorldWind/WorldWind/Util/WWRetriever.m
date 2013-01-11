/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import "WorldWind/Util/WWRetriever.h"
#import "WorldWind/Util/WWUtil.h"
#import "WorldWind/WorldWind.h"

@implementation WWRetriever

- (WWRetriever*) initWithUrl:(NSURL*)url filePath:(NSString*)filePath notification:(NSNotification*)notification
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
    _notification = notification;

    return self;
}

- (void) main
{
    @try
    {
        if (![self isCancelled])
        {
            if ([WWUtil retrieveUrl:_url toFile:_filePath] && _notification != nil)
            {
                [[NSNotificationCenter defaultCenter] postNotification:_notification];
            }
        }
    }
    @catch (NSException* exception)
    {
        NSString* msg = [NSString stringWithFormat:@"Retrieving %@ to %@", _url, _filePath];
        WWLogE(msg, exception);
    }
    @finally
    {
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