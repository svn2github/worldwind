/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.

@version $Id$
 */

#import "BulkRetrieverController.h"
#import "WorldWind/Geometry/WWSector.h"
#import "WorldWind/Layer/WWLayer.h"
#import "WorldWind/Layer/WWLayerList.h"
#import "WorldWind/Render/WWSceneController.h"
#import "WorldWind/Terrain/WWElevationModel.h"
#import "WorldWind/Terrain/WWGlobe.h"
#import "WorldWind/Util/WWBulkRetriever.h"
#import "WorldWind/Util/WWBulkRetrieverDataSource.h"
#import "WorldWind/WorldWindView.h"
#import "WorldWind/WWLog.h"

#define SECTION_LAYERS 0
#define SECTION_ELEVATIONS 1

//--------------------------------------------------------------------------------------------------------------------//
//-- BulkRetrieverCell --//
//--------------------------------------------------------------------------------------------------------------------//

@implementation BulkRetrieverCell

- (BulkRetrieverCell*) initWithDataSource:(id)dataSource sectors:(NSArray*)sectors operationQueue:(NSOperationQueue*)
        queue
{
    self = [super initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:nil];

    [[self textLabel] setText:[dataSource displayName]];
    dataSize = [dataSource dataSizeForSectors:sectors targetResolution:0];
    [[self detailTextLabel] setText:[[NSString alloc] initWithFormat:@"%d MB", (int) dataSize]];

    startAccessory = [self createStartAccessory];
    stopAccessory = [self createStopAccessory];
    [self setAccessoryView:startAccessory];

    _dataSource = dataSource;
    _sectors = sectors;
    _operationQueue = queue;

    return self;
}

- (UIView*) createStartAccessory
{
    CGFloat height = CGRectGetHeight([self frame]);
    CGFloat width = height;

    UIButton* button = [UIButton buttonWithType:UIButtonTypeCustom];
    [button setFrame:CGRectMake(0, 0, width, height)];
    [button setImage:[UIImage imageNamed:@"265-download"] forState:UIControlStateNormal];
    [button addTarget:self action:@selector(startRetrieving) forControlEvents:UIControlEventTouchDown];

    return button;
}

- (UIView*) createStopAccessory
{
    CGFloat height = CGRectGetHeight([self frame]);
    CGFloat width = 3 * height;
    UIView* view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, width, height)];

    CGFloat btnWidth = height;
    GLfloat btnHeight = height;
    UIButton* button = [UIButton buttonWithType:UIButtonTypeCustom];
    [button setFrame:CGRectMake(width - btnWidth, 0, btnWidth, btnHeight)];
    [button setImage:[UIImage imageNamed:@"433-x-gray"] forState:UIControlStateNormal];
    [button addTarget:self action:@selector(stopRetrieving) forControlEvents:UIControlEventTouchDown];
    [view addSubview:button];

    progress = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleBar];
    CGFloat prgHeight = CGRectGetHeight([progress frame]);
    CGFloat prgWidth = width - btnWidth;
    [progress setFrame:CGRectMake(0, height / 2 - prgHeight / 2, prgWidth, prgHeight)];
    [view addSubview:progress];

    return view;
}

- (void) startRetrieving
{
    if (retriever == nil) // Start retrieval once until the operation finishes or is cancelled.
    {
        // Define a completion block for the retriever that executes retrieverDidFinish.
        void (^completionBlock)(void) = ^
        {
            [self performSelectorOnMainThread:@selector(retrieverDidFinish) withObject:nil waitUntilDone:NO];
        };

        // Create the retriever and add it to the operation queue for execution. Add a key-value observer for the
        // progress property, which updates the progress view when this property changes.
        retriever = [[WWBulkRetriever alloc] initWithDataSource:_dataSource sectors:_sectors];
        [retriever addObserver:self forKeyPath:@"progress" options:NSKeyValueObservingOptionNew context:NULL];
        [retriever setCompletionBlock:completionBlock];
        [_operationQueue addOperation:retriever];

        // Display the retriever's initial progress then show the stop accessory, which includes a progress view.
        [progress setProgress:[retriever progress]];
        [self setAccessoryView:stopAccessory];
    }
}

- (void) stopRetrieving
{
    [retriever cancel]; // Causes the retriever to stop as soon as possible, then execute retrieverDidFinish.
}

- (void) retrieverDidFinish
{
    // Hide the accessory view if retrieval completed, otherwise show the start accessory to enable restart.
    UIView* accessoryView = ([retriever progress] == 1.0 ? nil : startAccessory);
    [self setAccessoryView:accessoryView];

    // Release the retriever and this cell's key-value observer for the progress property.
    [retriever removeObserver:self forKeyPath:@"progress"];
    retriever = nil;
}

- (void) observeValueForKeyPath:(NSString*)keyPath ofObject:(id)object change:(NSDictionary*)change context:(void*)context
{
    [progress setProgress:[object progress] animated:YES];
    [[self detailTextLabel] setText:[[NSString alloc] initWithFormat:@"%.0f MB,  %.0f MB remaining",
                    dataSize, ((1.0 - [object progress]) * dataSize)]];
}

@end

//--------------------------------------------------------------------------------------------------------------------//
//-- BulkRetrieverController --//
//--------------------------------------------------------------------------------------------------------------------//

@implementation BulkRetrieverController

- (BulkRetrieverController*) initWithWorldWindView:(WorldWindView*)wwv
{
    if (wwv == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"World Wind View is nil.")
    }

    self = [super initWithStyle:UITableViewStyleGrouped];

    _wwv = wwv;
    _operationQueue = [[NSOperationQueue alloc] init];

    layerCells = [[NSMutableArray alloc] initWithCapacity:10];
    elevationCells = [[NSMutableArray alloc] initWithCapacity:10];

    return self;
}

- (void) loadView
{
    [super loadView];

    [[self navigationItem] setTitle:@"Download for Offline Use"];
}

- (void) setSectors:(NSArray*)sectors
{
    _sectors = sectors;

    [_operationQueue cancelAllOperations];
    [self assembleTableCells];
    [[self tableView] reloadData];
}

- (NSInteger) numberOfSectionsInTableView:(UITableView*)tableView
{
    return 2;
}

- (NSInteger) tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section
{
    switch (section)
    {
        case SECTION_LAYERS:
            return [layerCells count];
        case SECTION_ELEVATIONS:
            return [elevationCells count];
        default:
            return 0;
    }
}

- (NSString*) tableView:(UITableView*)tableView titleForHeaderInSection:(NSInteger)section
{
    switch (section)
    {
        case SECTION_LAYERS:
            return @"Layers";
        case SECTION_ELEVATIONS:
            return @"Elevations";
        default:
            return nil;
    }
}

- (UITableViewCell*) tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
    switch ([indexPath section])
    {
        case SECTION_LAYERS:
            return [layerCells objectAtIndex:(NSUInteger) [indexPath row]];
        case SECTION_ELEVATIONS:
            return [elevationCells objectAtIndex:(NSUInteger) [indexPath row]];
        default:
            return nil;
    }
}

- (void) assembleTableCells
{
    [layerCells removeAllObjects];
    for (id layer in [[[_wwv sceneController] layers] allLayers])
    {
        [self addCellForDataSource:layer toArray:layerCells];
    }

    [elevationCells removeAllObjects];
    id model = [[[_wwv sceneController] globe] elevationModel];
    [self addCellForDataSource:model toArray:elevationCells];
}

- (void) addCellForDataSource:(id)dataSource toArray:(NSMutableArray*)array
{
    if ([dataSource conformsToProtocol:@protocol(WWBulkRetrieverDataSource)])
    {
        [array addObject:[[BulkRetrieverCell alloc] initWithDataSource:dataSource sectors:_sectors
                                                        operationQueue:_operationQueue]];
    }
}

@end