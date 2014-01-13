/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.

 @version $Id$
 */

#import "WorldWind/Util/WWResourceLoader.h"
#import "WorldWind/Render/WWTexture.h"
#import "WorldWind/Util/WWGpuResourceCache.h"
#import "WorldWind/WorldWind.h"
#import "WorldWind/WorldWindView.h"

@implementation WWResourceLoader

- (WWResourceLoader*) init
{
    self = [super init];

    currentLoads = [[NSMutableSet alloc] init];

    // Set up to handle resource loading notifications.
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleLoadNotification:)
                                                 name:WW_REQUEST_STATUS // opening file on disk
                                               object:self];

    return self;
}

- (void) dealloc
{
    [self dispose];
}

- (void) dispose
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (WWTexture*) textureForImagePath:(NSString*)imagePath cache:(WWGpuResourceCache*)cache
{
    if (imagePath == nil || [imagePath length] == 0)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Image path is nil or zero length")
    }

    if (cache == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Resource cache is nil")
    }

    WWTexture* texture = [cache textureForKey:imagePath];
    if (texture != nil)
    {
        return texture; // use the cached texture
    }
    else if ([currentLoads containsObject:imagePath]) // already loading the image path
    {
        return nil;
    }
    else // asynchronously load the image path, then put it in the cache and notify this object when done
    {
        [currentLoads addObject:imagePath]; // prevent duplicate resource loads
        texture = [[WWTexture alloc] initWithImagePath:imagePath cache:cache object:self];
        [[WorldWind loadQueue] addOperation:texture];
        return nil;
    }
}

- (void) handleLoadNotification:(NSNotification*)notification
{
    NSDictionary* avList = [notification userInfo];
    NSString* retrievalStatus = [avList valueForKey:WW_REQUEST_STATUS];
    NSString* imagePath = [avList valueForKey:WW_FILE_PATH];

    [currentLoads removeObject:imagePath]; // enable subsequent loads of this image path

    if ([retrievalStatus isEqualToString:WW_SUCCEEDED])
    {
        [WorldWindView requestRedraw];
    }
}

@end