/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import "WeatherCamViewController.h"
#import "WWRetriever.h"
#import "WorldWindConstants.h"

#define IMAGE_WIDTH (640)
#define IMAGE_HEIGHT (480)

@implementation WeatherCamViewController
{
    NSString* imagesCachePath;
    UIImageView* imageView;
    NSDictionary* siteInfo;
}

- (WeatherCamViewController*)init
{
    self = [super init];

    self.view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, IMAGE_WIDTH, IMAGE_HEIGHT)];

    NSString* cacheDir = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    imagesCachePath = [cacheDir stringByAppendingPathComponent:@"weathercams"];

    imageView = [[UIImageView alloc] init];
    imageView.frame = CGRectMake(0, 0, IMAGE_WIDTH, IMAGE_HEIGHT);
    imageView.backgroundColor = [UIColor whiteColor];
    imageView.userInteractionEnabled = YES;
    imageView.contentMode = UIViewContentModeScaleAspectFit;
    [[self view] addSubview:imageView];

    return self;
}

- (CGSize) preferredContentSize
{
    return CGSizeMake(IMAGE_WIDTH, IMAGE_HEIGHT);
}

-(void) setSiteInfo:(NSObject*)siteInformation
{
    siteInfo = (NSDictionary*)siteInformation;
    NSString* cameraID = [siteInfo objectForKey:@"cameraID"];
    NSString* imageURLString = [[NSString alloc]
            initWithFormat:@"http://worldwind.arc.nasa.gov/alaska/%@/currentimage.jpg", cameraID];
    NSURL* imageURL = [[NSURL alloc] initWithString:imageURLString];
    WWRetriever* retriever = [[WWRetriever alloc] initWithUrl:imageURL timeout:5
                                                finishedBlock:^(WWRetriever* myRetriever)
                                                {
                                                    [self loadImage:myRetriever];
                                                }];
    [retriever setUserData:cameraID];
    [retriever performRetrieval];
}

- (void) loadImage:(WWRetriever*)retriever
{
    NSString* imageFileName = [[NSString alloc] initWithFormat:@"%@-currentimage.jpg", [retriever userData]];
    NSString* imagePath = [imagesCachePath stringByAppendingPathComponent:imageFileName];

    // If the retrieval was successful, cache the retrieved chart.
    if ([[retriever status] isEqualToString:WW_SUCCEEDED] && [[retriever retrievedData] length] > 0)
    {
        [[retriever retrievedData] writeToFile:imagePath atomically:YES];
    }

    if ([[NSFileManager defaultManager] fileExistsAtPath:imagePath])
    {
        [imageView setImage:[[UIImage alloc] initWithContentsOfFile:imagePath]];
    }
}

@end