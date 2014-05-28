/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import "AppUpdateController.h"
#import "WWRetriever.h"
#import "AppConstants.h"
#import "WorldWindConstants.h"

#define UPDATE_CHECK_INTERVAL_HOURS (12)

@implementation AppUpdateController
{
    NSDate* mostRecentUpdateCheckTime;
}

- (AppUpdateController*) init
{
    self = [super init];

    // Set up to check for updates when app comes to the foreground.
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleForegroundNotification:)
                                                 name:UIApplicationWillEnterForegroundNotification object:nil];

    return self;
}

- (void) handleForegroundNotification:(NSNotification*)notification
{
    [self checkForUpdate:NO];
}

- (void) checkForUpdate:(BOOL)force
{
    if (force)
    {
        [self startUpdateCheck];
        return;
    }

    if (mostRecentUpdateCheckTime == nil)
        mostRecentUpdateCheckTime = [[NSDate alloc] init];

    if ([mostRecentUpdateCheckTime timeIntervalSinceNow] >= -UPDATE_CHECK_INTERVAL_HOURS * 3600)
        return;

    [self startUpdateCheck];
}

- (void) startUpdateCheck
{
    dispatch_async(dispatch_get_main_queue(), ^
    {
        NSString* location = [NSString stringWithFormat:@"http://%@/taiga/install/taigaversion.txt", TAIGA_DATA_HOST];
        NSURL* url = [[NSURL alloc] initWithString:location];
        WWRetriever* retriever = [[WWRetriever alloc] initWithUrl:url timeout:10
                                                    finishedBlock:^(WWRetriever* myRetriever)
                                                    {
                                                        [self doUpdateCheck:myRetriever];
                                                    }];
        [retriever performRetrieval];
    });
}

- (void) doUpdateCheck:(WWRetriever*)retriever
{
    if ([retriever status] != WW_SUCCEEDED)
        return;

    NSString* latestVersionString = [[NSString alloc] initWithData:[retriever retrievedData]
                                                          encoding:NSASCIIStringEncoding];
    if (latestVersionString == nil)
        return;

    NSNumberFormatter* formatter = [[NSNumberFormatter alloc] init];
    [formatter setNumberStyle:NSNumberFormatterDecimalStyle];

    NSNumber* latestVersionNumber = [formatter numberFromString:latestVersionString];
    if (latestVersionNumber == nil)
        return;

    NSNumber* currentVersionNumber = [formatter numberFromString:TAIGA_VERSION];

    if ([currentVersionNumber floatValue] < [latestVersionNumber floatValue])
    {
        [self performSelectorOnMainThread:@selector(performAlert) withObject:self waitUntilDone:NO];
    }

    mostRecentUpdateCheckTime = [[NSDate alloc] init];
}

- (void) performAlert
{
    UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:@"New Version Available"
                                                        message:@"A new version of TAIGA is available"
                                                       delegate:self
                                              cancelButtonTitle:@"Dismiss"
                                              otherButtonTitles:@"Install via Safari", nil];
    [alertView show];
}

- (void) alertView:(UIAlertView*)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 1)
    {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://worldwindserver.net/taiga/mobile"]];
    }
}

@end