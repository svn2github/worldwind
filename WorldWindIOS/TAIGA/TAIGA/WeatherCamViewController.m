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

    return self;
}

- (CGSize) preferredContentSize
{
    return CGSizeMake(IMAGE_WIDTH, IMAGE_HEIGHT);
}

- (void) didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];

    if ([contentView window] == nil) // if content view is not visible
        [self removeImageViews];
}

- (void) setSiteInfo:(NSArray*)siteCameras
{
    [self removeImageViews];

    [scrollView setContentOffset:CGPointZero];

    contentView.frame = CGRectMake(0, 0, IMAGE_WIDTH + ([siteCameras count] - 1) * (IMAGE_WIDTH + MARGIN),
            2 * (IMAGE_HEIGHT + MARGIN));
    [scrollView setContentSize:contentView.frame.size];

    for (NSUInteger cameraNumber = 0; cameraNumber < [siteCameras count]; cameraNumber++)
    {
        [self setCameraInfo:cameraNumber siteInformation:[siteCameras objectAtIndex:cameraNumber]];
    }
}

- (void) removeImageViews
{
    NSArray* contentSubviews = [contentView subviews];
    for (NSUInteger i = 0; i < [contentSubviews count]; i++)
    {
        [[contentSubviews objectAtIndex:i] removeFromSuperview];
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

    // Get the reference image. TODO: Use the correct URL when the reference images are added to the server.
    imageURLString = [[NSString alloc]
            initWithFormat:@"http://worldwind.arc.nasa.gov/alaska/%@/currentimage.jpg", cameraID];
    imageURL = [[NSURL alloc] initWithString:imageURLString];
    retriever = [[WWRetriever alloc] initWithUrl:imageURL timeout:5
                                   finishedBlock:^(WWRetriever* myRetriever)
                                   {
                                       [self loadImage:cameraNumber + 100 retriever:myRetriever];
                                   }];
    [retriever setUserData:cameraID];
    [retriever performRetrieval];
}

- (void) loadImage:(NSUInteger)cameraNumber retriever:(WWRetriever*)retriever
{
    NSString* suffix = cameraNumber < 100 ? @"-currentimage.jpg" : @"-referenceimage.jpg";
    NSString* imageFileName = [[NSString alloc] initWithFormat:@"%@%@", [retriever userData], suffix];
    NSString* imagePath = [imagesCachePath stringByAppendingPathComponent:imageFileName];

    // If the retrieval was successful, cache the retrieved chart.
    if ([[retriever status] isEqualToString:WW_SUCCEEDED] && [[retriever retrievedData] length] > 0)
    {
        [[retriever retrievedData] writeToFile:imagePath atomically:YES];
    }

    if ([[NSFileManager defaultManager] fileExistsAtPath:imagePath])
    {
        UIImageView* imageView = [[UIImageView alloc] init];
        int x = (cameraNumber < 100 ? cameraNumber : cameraNumber - 100) * (IMAGE_WIDTH + MARGIN);
        int y = cameraNumber < 100 ? 0 : IMAGE_HEIGHT + MARGIN;
        imageView.frame = CGRectMake(x, y, IMAGE_WIDTH, IMAGE_HEIGHT);
        imageView.backgroundColor = [UIColor whiteColor];
        imageView.userInteractionEnabled = YES;
        imageView.contentMode = UIViewContentModeScaleAspectFit;
        [imageView setImage:[[UIImage alloc] initWithContentsOfFile:imagePath]];

        [self performSelectorOnMainThread:@selector(addCameraView:) withObject:imageView waitUntilDone:NO];
    }
}

- (void) addCameraView:(UIImageView*)imageView
{
    [contentView addSubview:imageView];
}

@end