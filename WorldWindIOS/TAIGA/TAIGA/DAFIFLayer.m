/*
 Copyright (C) 2014 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import "WWRenderableLayer.h"
#import "DAFIFLayer.h"
#import "WorldWindView.h"
#import "AppConstants.h"
#import "WorldWind.h"

@implementation DAFIFLayer

- (DAFIFLayer*) init
{
    self = [super init];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleRefreshNotification:)
                                                 name:TAIGA_REFRESH
                                               object:nil];

    return self;
}

- (void) handleRefreshNotification:(NSNotification*)notification
{
    if ([WorldWind isNetworkAvailable])
    {
        [self performSelectorOnMainThread:@selector(doHandleRefreshNotification:) withObject:notification
                            waitUntilDone:NO];
    }
    else
    {
        UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:@"Unable to Refresh"
                                                            message:@"Cannot refresh DAFIF data because network is unavailable"
                                                           delegate:self
                                                  cancelButtonTitle:@"Dismiss"
                                                  otherButtonTitles:nil];
        [alertView show];
    }
}

- (void) doHandleRefreshNotification:(NSNotification*)notification
{
    if ([[notification name] isEqualToString:TAIGA_REFRESH]
            && ([notification object] == nil || [notification object] == self))
    {
        NSDate* justBeforeNow = [[NSDate alloc] initWithTimeIntervalSinceNow:-1];

        for (WWTiledImageLayer* layer in [self renderables])
        {
            [layer setExpiration:justBeforeNow];
        }

        [WorldWindView requestRedraw];
    }
}

@end