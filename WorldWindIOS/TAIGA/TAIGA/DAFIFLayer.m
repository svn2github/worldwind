/*
 Copyright (C) 2014 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import "WWRenderableLayer.h"
#import "DAFIFLayer.h"
#import "WorldWindView.h"
#import "AppConstants.h"

@implementation DAFIFLayer

- (DAFIFLayer*) init
{
    self = [super init];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleRefreshNotification:)
                                                 name:TAIGA_REFRESH
                                               object:self];

    return self;
}

- (void) handleRefreshNotification:(NSNotification*)notification
{
    if ([[notification name] isEqualToString:TAIGA_REFRESH] && [notification object] == self)
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