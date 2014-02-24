/*
 Copyright (C) 2014 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import <ImageIO/ImageIO.h>
#import "ZViewController.h"
#import "WWRetriever.h"
#import "WorldWindConstants.h"
#import "ZView.h"

@implementation ZViewController
{
    NSString* imagePath;
    NSDate* start;
}

- (id) init
{
    self = [super initWithNibName:nil bundle:nil];

    NSString* dir = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask,
            YES) objectAtIndex:0];
//    imagePath = [dir stringByAppendingPathComponent:@"36N120W-2.jp2"];
    imagePath = [dir stringByAppendingPathComponent:@"Anchorage93North.jp2"];

    [self retrieveMasterImage];

    return self;
}

- (void) retrieveMasterImage
{
//    if (![[NSFileManager defaultManager] fileExistsAtPath:imagePath])
    {
//        NSURL* url = [[NSURL alloc] initWithString:@"http://worldwindserver.net/36N120W-2.jp2"];
        NSURL* url = [[NSURL alloc] initWithString:@"http://worldwindserver.net/Anchorage93North.jp2"];
        WWRetriever* retriever = [[WWRetriever alloc] initWithUrl:url timeout:5
                                                    finishedBlock:^(WWRetriever* myRetriever)
                                                    {
                                                        [self saveImage:myRetriever];
                                                    }];
        start = [[NSDate alloc] init];
        [retriever performRetrieval];
    }
}

- (void) saveImage:(WWRetriever*)retriever
{
    NSDate* end = [[NSDate alloc] init];
    NSTimeInterval delta = [end timeIntervalSinceDate:start];
    NSLog(@"DOWNLOAD TIME: %f", delta);

    if ([[retriever status] isEqualToString:WW_SUCCEEDED] && [[retriever retrievedData] length] > 0)
    {
        [[retriever retrievedData] writeToFile:imagePath atomically:YES];
    }
}
//
//- (void) getProperties
//{
//    NSURL* url = [NSURL fileURLWithPath:imagePath];
//    CGImageSourceRef imageSource = CGImageSourceCreateWithURL((__bridge CFURLRef)url, nil);
//    NSDictionary* props = (__bridge NSDictionary*) CGImageSourceCopyProperties(imageSource, nil);
//    NSLog(@"DONE");
//}

- (void) loadView
{
    ZView* zview = [[ZView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    [zview setImageFilePath:imagePath];

    self.view = zview;
    self.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.view.autoresizesSubviews = YES;
}

- (void) viewDidLoad
{
    [super viewDidLoad];

    [self.view setBackgroundColor:[UIColor greenColor]];
}

@end