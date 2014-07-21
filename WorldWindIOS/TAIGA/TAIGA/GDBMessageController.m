/*
 Copyright (C) 2014 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import "GDBMessageController.h"
#import "WWRetriever.h"
#import "AppConstants.h"
#import "Settings.h"
#import "WorldWindConstants.h"

#define DEFAULT_GDB_DEVICE_ADDRESS @"http://worldwindserver.net/taiga/install/taigaversion.txt"

@implementation GDBMessageController
{
    NSTimer* timer;
}

+ (void) setDefaultGDBDeviceAddress
{
    [Settings setObject:DEFAULT_GDB_DEVICE_ADDRESS forName:TAIGA_GDB_DEVICE_ADDRESS];
}

- (GDBMessageController*) init
{
    self = [super init];

    timer = [NSTimer scheduledTimerWithTimeInterval:10 target:self selector:@selector(pollDevice)
                                           userInfo:nil repeats:YES];

    [self pollDevice];

    return self;
}

- (void) dispose
{
    [timer invalidate];
    timer = nil;
}

- (void) pollDevice
{
    NSString* address = (NSString*) [Settings getObjectForName:TAIGA_GDB_DEVICE_ADDRESS];
    if (address == nil || address.length == 0)
        return;

    NSURL* url = [[NSURL alloc] initWithString:address];
    if (url == nil)
        return;

    WWRetriever* retriever = [[WWRetriever alloc] initWithUrl:url timeout:5
                                                finishedBlock:^(WWRetriever* myRetriever)
                                                {
                                                    [self processRetrieval:myRetriever];
                                                }];
    [retriever performRetrieval];
}

- (void) processRetrieval:(WWRetriever*)retriever
{
    if (![[retriever status] isEqualToString:WW_SUCCEEDED]
            || [[retriever retrievedData] length] == 0
            || [retriever httpStatusCode] != 200)
    {
        // Send a notification that the message is not available.
        [[NSNotificationCenter defaultCenter] postNotificationName:TAIGA_GDB_MESSAGE object:nil];
        return;
    }

    NSString* allSentences = [[NSString alloc] initWithData:[retriever retrievedData] encoding:NSASCIIStringEncoding];
    NSMutableArray* lines = [[NSMutableArray alloc] init];
    [allSentences enumerateLinesUsingBlock:^(NSString* line, BOOL* stop)
    {
        if (line.length > 0)
            [lines addObject:line];
    }];

    [self distributeMessage:lines];

//    NSMutableDictionary* unparsedSentences = [[NSMutableDictionary alloc] initWithCapacity:4];
//    [allSentences enumerateLinesUsingBlock:^(NSString* line, BOOL* stop)
//    {
//        if (![line hasPrefix:@"$"])
//            return;
//
//        NSArray* splitSentence = [line componentsSeparatedByCharactersInSet:
//                [NSCharacterSet characterSetWithCharactersInString:@","]];
//
//        if ([splitSentence count] > 0)
//            [unparsedSentences setObject:line forKey:[splitSentence objectAtIndex:0]];
//    }];

    NSMutableDictionary* parsedSentences = [[NSMutableDictionary alloc] initWithCapacity:4];
//    for (NSString* sentence in [unparsedSentences allValues])
//    {
//        NMEASentence* parsedSentence = [[NMEASentence alloc] initWithString:sentence];
//        if (parsedSentence != nil)
//        {
//            NSString* sentenceType = [parsedSentence sentenceType];
//            if (sentenceType != nil)
//                [parsedSentences setObject:parsedSentence forKey:sentenceType];
//        }
//    }
//
//    if (![self distributeCurrentPosition:parsedSentences])
//    {
//        // Send a notification that the GPS fix is not available.
//        [[NSNotificationCenter defaultCenter] postNotificationName:TAIGA_GPS_QUALITY object:nil];
//        return;
//    }
//
//    [self distributeSignalInfo:parsedSentences];
}

- (void) distributeMessage:(NSArray*) lines
{
    if (!lines.count > 0)
        return;

    [[NSNotificationCenter defaultCenter] postNotificationName:TAIGA_GDB_MESSAGE
                                                        object:[lines objectAtIndex:lines.count - 1]];
}

@end