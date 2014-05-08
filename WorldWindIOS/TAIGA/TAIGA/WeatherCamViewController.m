/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import "WeatherCamViewController.h"
#import "WWRetriever.h"
#import "WorldWindConstants.h"
#import "DotsView.h"

#define IMAGE_WIDTH (640)
#define IMAGE_HEIGHT (480)
#define MARGIN (10)

@implementation WeatherCamViewController
{
    NSString* imagesCachePath;
    UIView* contentView;
    UIScrollView* scrollView;
    DotsView* dotsView;
    CGPoint dotsCenter;
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

    dotsCenter = CGPointMake(IMAGE_WIDTH / 2, 0.85 * IMAGE_HEIGHT);

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

    if (dotsView != nil)
        [dotsView removeFromSuperview];

    dotsView = [[DotsView alloc] initWithCenter:dotsCenter dotCount:[siteCameras count]];
    [[self view] addSubview:dotsView];

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

    // Get the reference image.
    imageURLString = [[NSString alloc]
//            initWithFormat:@"http://avcams.faa.gov/images/clearday/%@-clearday.jpg", cameraID];
            initWithFormat:@"http://worldwind.arc.nasa.gov/alaska/%@/referenceimage.jpg", cameraID];
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

        [self performSelectorOnMainThread:@selector(addView:) withObject:imageView waitUntilDone:NO];

        if (cameraNumber >= 100)
        {
            CGRect labelFrame = CGRectMake(imageView.frame.origin.x, imageView.frame.origin.y, IMAGE_WIDTH, 50);
            UILabel* label = [[UILabel alloc] initWithFrame:labelFrame];
            [label setText:@"CLEARDAY IMAGE"];
            [label setTextAlignment:NSTextAlignmentCenter];
            [label setTextColor:[UIColor redColor]];
            [label setFont:[UIFont fontWithName:@"Helvetica-Bold" size:30]];
            [self performSelectorOnMainThread:@selector(addView:) withObject:label waitUntilDone:NO];
        }
    }
}

- (void) addView:(UIView*)view
{
    [contentView addSubview:view];
}

- (void) scrollViewDidScroll:(UIScrollView*)sv
{
    int cameraNumber = (int) ((IMAGE_WIDTH / 2 + [sv contentOffset].x) / IMAGE_WIDTH);
    if ([dotsView highlightedDot] != cameraNumber)
        [dotsView setNeedsDisplay];
    [dotsView setHighlightedDot:cameraNumber];
}

@end