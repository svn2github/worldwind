/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import "WorldWind/Layer/WWBMNGOneImageLayer.h"
#import "WorldWind/Shapes/WWSurfaceImage.h"
#import "WorldWind/Geometry/WWSector.h"
#import "WOrldWind/WWLog.h"


@implementation WWBMNGOneImageLayer

- (WWBMNGOneImageLayer*) init
{
    self = [super init];

    NSString* networkLocation = @"http://worldwindserver.net";
    NSString* imageFileName = @"BMNG_world.topo.bathy.200405.3.2048x1024.jpg";

    NSString* cacheDir = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask,
            YES) objectAtIndex:0];
    NSString* filePath = [cacheDir stringByAppendingPathComponent:imageFileName];
    BOOL fileExists = [[NSFileManager defaultManager] fileExistsAtPath:filePath];
    if (!fileExists)
    {
        [self retrieveImage:imageFileName atLocation:networkLocation toFilePath:filePath];
        fileExists = [[NSFileManager defaultManager] fileExistsAtPath:filePath];
    }

    if (!fileExists)
    {
        WWLog(@"Unable to find or retrieve BMNG image %@", imageFileName);
        return nil;
    }

    WWSector* sector = [[WWSector alloc] initWithFullSphere];
    _surfaceImage = [[WWSurfaceImage alloc] initWithImagePath:sector imagePath:filePath];

    return self;
}

- (void) retrieveImage:(NSString*)fileName atLocation:(NSString*)location toFilePath:(NSString*)path
{
    NSString* urlPath = [NSString stringWithFormat:@"%@/%@", location, fileName];
    NSURL* url = [NSURL URLWithString:urlPath];

    NSError* error = nil;
    NSData* data = [NSData dataWithContentsOfURL:url options:0 error:&error];
    if (error != nil)
    {
        WWLog("@Error \"%@\" retrieving %@", [error description], [url absoluteString]);
        return;
    }

    [data writeToFile:path options:0 error:&error];
    if (error != nil)
    {
        WWLog("@Error \"%@\" writing file %@", [error description], path);
        return;
    }
}

- (void) render:(WWDrawContext*)dc
{
    if (_surfaceImage != nil)
    {
        [_surfaceImage render:dc];
    }
}

@end