/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import "ChartsListController.h"
#import "WWRetriever.h"
#import "WorldWindConstants.h"
#import "WWLog.h"
#import "ChartsScreenController.h"

@implementation ChartsListController
{
    id parentController;
    NSString* chartsServer;
    NSString* airportsCachePath;
    NSArray* airportCharts;
    UIRefreshControl* refreshControl;
}

- (ChartsListController*) initWithParent:(id)parent
{
    self = [super initWithStyle:UITableViewStylePlain];

    [[self navigationItem] setTitle:@"Charts"];

    parentController = parent;

    self.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.view.autoresizesSubviews = YES;

    chartsServer = @"http://worldwindserver.net/taiga/charts/airports";

    NSString* cacheDir = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    airportsCachePath = [cacheDir stringByAppendingPathComponent:@"charts/airports"];
    NSError* error = nil;
    [[NSFileManager defaultManager] createDirectoryAtPath:airportsCachePath
                              withIntermediateDirectories:YES attributes:nil error:&error];

    refreshControl = [[UIRefreshControl alloc] init];
    [refreshControl addTarget:self action:@selector(handleRefresh) forControlEvents:UIControlEventValueChanged];
    [self setRefreshControl:refreshControl];

    [self loadChartsTOC];

    return self;
}

- (void) loadChartsTOC
{
    NSURL* url = [[NSURL alloc] initWithString:[NSString stringWithFormat:@"%@/TOC.txt", chartsServer]];
    WWRetriever* retriever = [[WWRetriever alloc] initWithUrl:url timeout:5
                                                finishedBlock:^(WWRetriever* myRetriever)
                                                {
                                                    [self makeAirportChartsTOC:myRetriever];
                                                }];
    [retriever performRetrieval];

}

- (void) handleRefresh
{
    [refreshControl beginRefreshing];
    [self loadChartsTOC];
}

- (void) makeAirportChartsTOC:(WWRetriever*)retriever
{
    NSString* tocPath = [airportsCachePath stringByAppendingPathComponent:@"TOC.txt"];

    // If the retrieval was successful, cache the retrieved TOC.
    if ([[retriever status] isEqualToString:WW_SUCCEEDED] && [[retriever retrievedData] length] > 0)
    {
        [[retriever retrievedData] writeToFile:tocPath atomically:YES];
    }

    // Load the TOC into memory.
    NSError* error = nil;
    NSString* tocString = [[NSString alloc] initWithContentsOfFile:tocPath encoding:NSASCIIStringEncoding
                                                             error:&error];
    if (error != nil || tocString == nil)
    {
        WWLog("@Unable to find airport charts table of contents (%@)", error != nil ? [error description] : @"");
        [refreshControl endRefreshing];
        return;
    }

    NSMutableArray* unsortedList = [[NSMutableArray alloc] init];
    [tocString enumerateLinesUsingBlock:^(NSString* line, BOOL* stop)
    {
        [unsortedList addObject:line];
    }];

    // Sort the TOC.
    airportCharts = [unsortedList sortedArrayUsingComparator:^NSComparisonResult(id a, id b)
    {
        NSString* nameA = [a componentsSeparatedByString:@","][1];
        NSString* nameB = [b componentsSeparatedByString:@","][1];

        return [nameA compare:nameB];
    }];

    [[self tableView] reloadData];

    [refreshControl endRefreshing];
}

- (NSInteger) numberOfSectionsInTableView:(UITableView*)tableView
{
    return 1;
}

- (NSInteger) tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section
{
    return airportCharts != nil ? [airportCharts count] : 0;
}

- (UITableViewCell*) tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
    static NSString* cellIdentifier = @"itemCell";

    UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (cell == nil)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
    }

    NSString* chartLine = [airportCharts objectAtIndex:(NSUInteger) [indexPath row]];
    [[cell textLabel] setText:[chartLine componentsSeparatedByString:@","][1]];

    return cell;
}

- (void) tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath
{
    NSString* chartLine = [airportCharts objectAtIndex:(NSUInteger) [indexPath row]];
    NSString* chartFileName = [chartLine componentsSeparatedByString:@","][0];
    NSString* chartName = [chartLine componentsSeparatedByString:@","][1];

    [self selectChart:chartFileName chartName:chartName];
}

- (void) selectChart:(NSString*)chartFileName chartName:(NSString*)chartName
{
    NSURL* url = [[NSURL alloc] initWithString:[NSString stringWithFormat:@"%@/%@", chartsServer, chartFileName]];
    WWRetriever* retriever = [[WWRetriever alloc] initWithUrl:url timeout:5
                                                finishedBlock:^(WWRetriever* myRetriever)
                                                {
                                                    [self loadChart:myRetriever];
                                                }];
    [retriever setUserData:chartName];
    [retriever performRetrieval];
}

- (void) loadChart:(WWRetriever*)retriever
{
    NSString* chartFileName = [[retriever url] lastPathComponent];
    NSString* chartPath = [airportsCachePath stringByAppendingPathComponent:chartFileName];

    // If the retrieval was successful, cache the retrieved chart.
    if ([[retriever status] isEqualToString:WW_SUCCEEDED] && [[retriever retrievedData] length] > 0)
    {
        [[retriever retrievedData] writeToFile:chartPath atomically:YES];
    }

    [parentController loadChart:chartPath chartName:[retriever userData]];

//
//    for (NSUInteger i = 0; i < [airportCharts count]; i++)
//    {
//        if ([[airportCharts objectAtIndex:i] hasPrefix:chartFileName])
//        {
//            NSIndexPath* indexPath = [NSIndexPath indexPathForRow:i inSection:0];
//            [[self tableView] selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
//            break;
//        }
//    }
}

@end