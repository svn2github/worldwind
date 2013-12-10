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
#define MARGIN (10)

@implementation WeatherCamViewController
{
    NSString* imagesCachePath;
    UIView* contentView;
    UIScrollView* scrollView;
    UIImageView* referenceImage;
}

- (WeatherCamViewController*) init
{
    self = [super init];

    self.view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, IMAGE_WIDTH, IMAGE_HEIGHT)];

    NSString* cacheDir = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    imagesCachePath = [cacheDir stringByAppendingPathComponent:@"weathercams"];

    contentView = [[UIView alloc] init];

    scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, IMAGE_WIDTH, IMAGE_HEIGHT)];
    [scrollView setDelegate:self];
    [scrollView addSubview:contentView];

    [[self view] addSubview:scrollView];

    referenceImage = [[UIImageView alloc] init];
    referenceImage.backgroundColor = [UIColor whiteColor];
    referenceImage.userInteractionEnabled = YES;
    referenceImage.contentMode = UIViewContentModeScaleAspectFit;
    NSString* referenceImagePath =
            [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"wx_cam_reference_placeholder.jpg"];
    [referenceImage setImage:[[UIImage alloc] initWithContentsOfFile:referenceImagePath]];

    return self;
}

- (CGSize) preferredContentSize
{
    return CGSizeMake(IMAGE_WIDTH, IMAGE_HEIGHT);
}

- (void) setSiteInfo:(NSArray*)siteCameras
{
    NSArray* contentSubviews = [contentView subviews];
    for (NSUInteger i = 0; i < [contentSubviews count]; i++)
    {
        [[contentSubviews objectAtIndex:i] removeFromSuperview];
    }

    [scrollView setContentOffset:CGPointZero];

    referenceImage.frame = CGRectMake([siteCameras count] * (IMAGE_WIDTH + MARGIN), 0, IMAGE_WIDTH, IMAGE_HEIGHT);
    [contentView addSubview:referenceImage];

    for (NSUInteger cameraNumber = 0; cameraNumber < [siteCameras count]; cameraNumber++)
    {
        [self setCameraInfo:cameraNumber siteInformation:[siteCameras objectAtIndex:cameraNumber]];
    }
}

- (void) setCameraInfo:(NSUInteger)cameraNumber siteInformation:(NSDictionary*)cameraInfo
{
    NSString* cameraID = [cameraInfo objectForKey:@"cameraID"];
    NSString* imageURLString = [[NSString alloc]
            initWithFormat:@"http://worldwind.arc.nasa.gov/alaska/%@/currentimage.jpg", cameraID];
    NSURL* imageURL = [[NSURL alloc] initWithString:imageURLString];
    WWRetriever* retriever = [[WWRetriever alloc] initWithUrl:imageURL timeout:5
                                                finishedBlock:^(WWRetriever* myRetriever)
                                                {
                                                    [self loadImage:cameraNumber retriever:myRetriever];
                                                }];
    [retriever setUserData:cameraID];
    [retriever performRetrieval];
}

- (void) loadImage:(NSUInteger)cameraNumber retriever:(WWRetriever*)retriever
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
        UIImageView* imageView = [[UIImageView alloc] init];
        imageView.frame = CGRectMake(cameraNumber * (IMAGE_WIDTH + MARGIN), 0, IMAGE_WIDTH, IMAGE_HEIGHT);
        imageView.backgroundColor = [UIColor whiteColor];
        imageView.userInteractionEnabled = YES;
        imageView.contentMode = UIViewContentModeScaleAspectFit;
        [imageView setImage:[[UIImage alloc] initWithContentsOfFile:imagePath]];

        [self performSelectorOnMainThread:@selector(adjustContentView:) withObject:imageView waitUntilDone:NO];
    }
}

- (void) adjustContentView:(UIImageView*)imageView
{
    [contentView addSubview:imageView];
    contentView.frame = CGRectMake(0, 0, IMAGE_WIDTH + ([contentView.subviews count] - 1) * (IMAGE_WIDTH + MARGIN),
            IMAGE_HEIGHT);
    [scrollView setContentSize:contentView.frame.size];
}

@end