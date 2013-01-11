/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import "WorldWind/Layer/WWBMNGOneImageLayer.h"
#import "WorldWind/Shapes/WWSurfaceImage.h"
#import "WorldWind/Geometry/WWSector.h"
#import "WorldWind/WWLog.h"
#import "WorldWind/Render/WWDrawContext.h"


@implementation WWBMNGOneImageLayer

- (WWBMNGOneImageLayer*) init
{
    self = [super init];

    NSString* networkLocation = @"http://worldwindserver.net"; // TODO: change location, and perhaps image type (PVRTC)
    NSString* imageFileName = @"BMNG_world.topo.bathy.200405.3.2048x1024.jpg";

    NSString* cacheDir = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask,
            YES) objectAtIndex:0];
    NSString* filePath = [cacheDir stringByAppendingPathComponent:imageFileName];
    BOOL fileExists = [[NSFileManager defaultManager] fileExistsAtPath:filePath];
    if (!fileExists)
    {
        [self retrieveImageWithName:imageFileName atLocation:networkLocation toFilePath:filePath];
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

- (void) retrieveImageWithName:(NSString*)fileName atLocation:(NSString*)atLocation toFilePath:(NSString*)toFilePath
{
    NSString* urlPath = [NSString stringWithFormat:@"%@/%@", atLocation, fileName];
    NSURL* url = [NSURL URLWithString:urlPath];

    NSError* error = nil;
    NSData* data = [NSData dataWithContentsOfURL:url options:0 error:&error];
    if (error != nil)
    {
        WWLog("@Error \"%@\" retrieving %@", [error description], [url absoluteString]);
        return;
    }

    [data writeToFile:toFilePath options:0 error:&error];
    if (error != nil)
    {
        WWLog("@Error \"%@\" writing file %@", [error description], toFilePath);
        return;
    }
}

- (void) doRender:(WWDrawContext*)dc
{
    if (_surfaceImage != nil)
    {
        [_surfaceImage render:dc];
    }
}

@end