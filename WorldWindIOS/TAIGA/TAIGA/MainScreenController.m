/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import "MainScreenController.h"
#import "MovingMapViewController.h"
#import "AppConstants.h"
#import "WeatherScreenController.h"
#import "ChartsScreenController.h"
#import "SettingsScreenController.h"
#import "ButtonWithImageAndText.h"
#import "TAIGA.h"
#import "AppUpdateController.h"
#import "ZKFileArchive.h"
#import "ZKCDHeader.h"
#import "Settings.h"
#import "WWLog.h"

#define VIEW_TAG (100)

@implementation MainScreenController
{
    UIToolbar* modeBar;
    UIBarButtonItem* movingMapButton;
    UIBarButtonItem* weatherButton;
    UIBarButtonItem* chartsButton;
    UIBarButtonItem* settingsButton;

    MovingMapViewController* movingMapScreenController;
    WeatherScreenController* weatherScreenController;
    ChartsScreenController* chartsScreenController;
    SettingsScreenController* settingsScreenController;
    UIViewController* currentScreenController;

    NSTimer* dataInstallationCheckTimer;
    BOOL dataInstallationInProgress;
}

- (id) init
{
    self = [super initWithNibName:nil bundle:nil];

    return self;
}

- (void) loadView
{
    self.view = [[UIView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.view.autoresizesSubviews = YES;

    [self createModeBar];

    CGRect frame = [self.view frame];
    frame.origin.x = 0;
    frame.origin.y = 20;
    frame.size.height -= TAIGA_TOOLBAR_HEIGHT + 20;

    movingMapScreenController = [[MovingMapViewController alloc] initWithFrame:frame];
    [[movingMapScreenController view] setTag:VIEW_TAG];

    weatherScreenController = [[WeatherScreenController alloc] initWithFrame:frame];
    [[weatherScreenController view] setTag:VIEW_TAG];

    chartsScreenController = [[ChartsScreenController alloc] initWithFrame:frame];
    [[chartsScreenController view] setTag:VIEW_TAG];

    settingsScreenController = [[SettingsScreenController alloc] initWithFrame:frame];
    [[settingsScreenController view] setTag:VIEW_TAG];

    [self.view addSubview:[movingMapScreenController view]];
    [((ButtonWithImageAndText*) [movingMapButton customView]) highlight:YES];
}

- (void) viewDidLoad
{
    [super viewDidLoad];

    [self setNeedsStatusBarAppearanceUpdate];

    [[TAIGA appUpdateController] checkForUpdate:YES];

    [self setupInstalledDataTimer];
}

- (void) didReceiveMemoryWarning
{
    DDLogWarn(@"RECEIVED MEMORY WARNING");
}

- (UIStatusBarStyle) preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}

- (void) createModeBar
{
    modeBar = [[UIToolbar alloc] init];
    modeBar.frame = CGRectMake(0, self.view.frame.size.height - TAIGA_TOOLBAR_HEIGHT, self.view.frame.size.width, TAIGA_TOOLBAR_HEIGHT);
    [modeBar setAutoresizingMask:UIViewAutoresizingFlexibleWidth];
    [modeBar setBarStyle:UIBarStyleBlack];
    [modeBar setTranslucent:NO];

    CGSize size = CGSizeMake(130, TAIGA_TOOLBAR_HEIGHT);

    movingMapButton = [[UIBarButtonItem alloc] initWithCustomView:[[ButtonWithImageAndText alloc]
            initWithImageName:@"401-globe" text:@"Map" size:size target:self action:@selector
            (handleMovingMap)]];
    UIColor* color = [[UIColor alloc] initWithRed:1.0 green:242. / 255. blue:183. / 255. alpha:1.0];
    [((ButtonWithImageAndText*) [movingMapButton customView]) setTextColor:color];

    weatherButton = [[UIBarButtonItem alloc] initWithCustomView:[[ButtonWithImageAndText alloc]
            initWithImageName:@"25-weather" text:@"Weather" size:size target:self action:@selector
            (handleWeather)]];
    color = [[UIColor alloc] initWithRed:1.0 green:208. / 255. blue:237. / 255. alpha:1.0];
    [((ButtonWithImageAndText*) [weatherButton customView]) setTextColor:color];

    chartsButton = [[UIBarButtonItem alloc] initWithCustomView:[[ButtonWithImageAndText alloc]
            initWithImageName:@"361-1up" text:@"Charts" size:size target:self action:@selector
            (handleCharts)]];
    color = [[UIColor alloc] initWithRed:182. / 255. green:255. / 255. blue:190. / 255. alpha:1.0];
    [((ButtonWithImageAndText*) [chartsButton customView]) setTextColor:color];

    settingsButton = [[UIBarButtonItem alloc] initWithCustomView:[[ButtonWithImageAndText alloc]
            initWithImageName:@"19-gear" text:@"Settings" size:size target:self action:@selector
            (handleSettings)]];

    UIBarButtonItem* flexibleSpace = [[UIBarButtonItem alloc]
            initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];

    [modeBar setItems:[NSArray arrayWithObjects:
            flexibleSpace,
            movingMapButton,
            flexibleSpace,
            weatherButton,
            flexibleSpace,
            chartsButton,
            flexibleSpace,
            settingsButton,
            flexibleSpace,
                    nil]];

    [modeBar setAutoresizingMask:UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin];
    [self.view addSubview:modeBar];
}

- (void) handleMovingMap
{
    [self swapScreenController:movingMapScreenController button:movingMapButton];
}

- (void) handleWeather
{
    if (currentScreenController == weatherScreenController)
        [self handleMovingMap];
    else
        [self swapScreenController:weatherScreenController button:weatherButton];
}

- (void) handleCharts
{
    if (currentScreenController == chartsScreenController)
        [self handleMovingMap];
    else
        [self swapScreenController:chartsScreenController button:chartsButton];
}

- (void) handleSettings
{
    if (currentScreenController == settingsScreenController)
        [self handleMovingMap];
    else
    [self swapScreenController:settingsScreenController button:settingsButton];
}

- (void) swapScreenController:(UIViewController*)screenController button:(UIBarButtonItem*)button
{
    CGRect frame = [[screenController view] frame];

    for (UIView* subview in self.view.subviews)
    {
        if (subview.tag == VIEW_TAG)
        {
            frame = subview.frame;
            [subview removeFromSuperview];
            break;
        }
    }

    [[screenController view] setFrame:frame];
    [self.view addSubview:[screenController view]];

    [((ButtonWithImageAndText*) [movingMapButton customView]) highlight:NO];
    [((ButtonWithImageAndText*) [weatherButton customView]) highlight:NO];
    [((ButtonWithImageAndText*) [chartsButton customView]) highlight:NO];
    [((ButtonWithImageAndText*) [settingsButton customView]) highlight:NO];

    [((ButtonWithImageAndText*) [button customView]) highlight:YES];

    currentScreenController = screenController;
}

- (void) setupInstalledDataTimer
{
    // Check for a data file once a minute.
    dataInstallationCheckTimer = [NSTimer scheduledTimerWithTimeInterval:60
                                                                  target:self selector:@selector(installPreparedData)
                                                                userInfo:nil repeats:YES];
    [dataInstallationCheckTimer setTolerance:10];
}

- (void) installPreparedData
{
    @synchronized (self)
    {
        if (dataInstallationInProgress)
            return;

        dataInstallationInProgress = YES;
    }

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        @try
        {
            NSString* zipPath = [self determineDataFile];
            if (zipPath == nil)
                return;

            NSFileCoordinator* fileCoordinator = [[NSFileCoordinator alloc] initWithFilePresenter:nil];
            NSURL* fileURL = [[NSURL alloc] initFileURLWithPath:zipPath];
            NSError* error = nil;
            [fileCoordinator coordinateReadingItemAtURL:fileURL options:0
                                                  error:&error byAccessor:^void(NSURL* url) {
                        [self doInstallPreparedData:[url path]];
                    }];

            if (error != nil)
            {
                WWLog("@Error occurred waiting for preinstallation data file: %@", [error description]);
            }
        }
        @catch (NSException* exception)
        {
            NSLog(@"Exception occurred installing data: %@, %@", exception, [exception userInfo]);
        }
        @finally
        {
            @synchronized (self)
            {
                dataInstallationInProgress = NO;
            }
        }
    });
}

- (NSString*) determineDataFile
{
    NSString* docsDir = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];

    NSDirectoryEnumerator* files = [[NSFileManager defaultManager] enumeratorAtPath:docsDir];
    for (NSString* fileName = files.nextObject; fileName != nil; fileName = files.nextObject)
    {
        if ([fileName hasSuffix:@"zip"])
        {
            return [docsDir stringByAppendingPathComponent:fileName];
        }
    }

    return nil;
}

- (void) doInstallPreparedData:(NSString*)zipPath
{
    NSString* cacheDir = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0];

    // Determine whether the archive has been partially read in a previous session, and if so, how many entries
    // were previously read.

    NSDictionary* fileAttrs = [[NSFileManager defaultManager] attributesOfItemAtPath:zipPath error:nil];
    NSDate* fileDate = [fileAttrs objectForKey:NSFileModificationDate];
    NSTimeInterval currentDataFileID = fileDate.timeIntervalSince1970; // use the file date as the archive ID

    NSUInteger numEntriesExtracted = 0; // assume that no entries were previously extracted.

    // Determine whether partial extraction occurred previously from this archive.
    double previousDataFileID = [Settings getDoubleForName:TAIGA_DATA_FILE_ID];
    if (currentDataFileID == previousDataFileID) // these will match if the archive is the one read previously
    {
        // We've extracted from this archive before. Determine how many entries were extracted.
        numEntriesExtracted = (NSUInteger) [Settings getIntForName:TAIGA_DATA_FILE_NUM_FILES_EXTRACTED];
    }

    NSDate* start = [[NSDate alloc] init]; // to keep track of how long the extraction takes

    // Open the archive and get its central directory -- its list of files.
    ZKFileArchive* archive = [ZKFileArchive archiveWithArchivePath:zipPath];
    if (archive == nil)
        return;

    NSArray* centralDirectory = [archive centralDirectory];

    [self performSelectorOnMainThread:@selector(performAlert:)
                           withObject:(numEntriesExtracted == 0 ? @"start" : @"resume")
                        waitUntilDone:NO];

    // Mark that we've extracted files from this archive.
    [Settings setDouble:currentDataFileID forName:TAIGA_DATA_FILE_ID];

    // Iterate over the central directory and extract each entry.
    NSUInteger numEntries = [centralDirectory count];
    [Settings setFloat:100.0 * ((float) numEntriesExtracted / numEntries) forName:TAIGA_DATA_FILE_INSTALLATION_PROGRESS];
    [[NSNotificationCenter defaultCenter] postNotificationName:TAIGA_DATA_FILE_INSTALLATION_PROGRESS object:nil];

    for (NSUInteger i = numEntriesExtracted; i < numEntries; i++)
    {
        ZKCDHeader* entry = [centralDirectory objectAtIndex:i];
        [archive inflateFile:entry toDirectory:cacheDir];

        // Mark the number of entries read. Since doing so causes the user preferences cache to synch, mark only
        // every 100th extraction.
        if (i % 100 == 0)
        {
            [Settings setInt:i + 1 forName:TAIGA_DATA_FILE_NUM_FILES_EXTRACTED];
            [Settings setFloat:100.0 * ((float) (i + 1) / numEntries) forName:TAIGA_DATA_FILE_INSTALLATION_PROGRESS];
            [[NSNotificationCenter defaultCenter] postNotificationName:TAIGA_DATA_FILE_INSTALLATION_PROGRESS object:nil];
        }
    }

    // Reset the number of extracted entries to 0. This causes the archive to be re-extracted if it is ever
    // again transferred to the device. An alternative policy would be to avoid re-extracting when the same
    // archive is transferred again. To do that simply save "numEntries" here. But that policy would make it
    // difficult to repeat the transfer/extract process in case errors occur during extraction.
    [Settings setInt:0 forName:TAIGA_DATA_FILE_NUM_FILES_EXTRACTED];

    // Mark that data installation is complete so that the Settings screen can reflect that.
    [Settings setFloat:100.0 forName:TAIGA_DATA_FILE_INSTALLATION_PROGRESS];
    [[NSNotificationCenter defaultCenter] postNotificationName:TAIGA_DATA_FILE_INSTALLATION_PROGRESS object:nil];

    // Remove the archive now that its contents have been fully extracted.
    [[NSFileManager defaultManager] removeItemAtPath:zipPath error:nil];

    // Report how long the extraction took.
    NSDate* end = [[NSDate alloc] init];
    NSTimeInterval delta = [end timeIntervalSinceDate:start];
    NSLog(@"Extracted %d data files in %f minutes (%f seconds per file)",
            numEntries, delta / 60.0, delta / numEntries);

    [self performSelectorOnMainThread:@selector(performAlert:) withObject:@"end" waitUntilDone:NO];

    return;
}

- (void) performAlert:(NSString*)state
{
    NSString* title;

    if ([state isEqualToString:@"start"])
    {
        title = @"Data Installation has started. You may dismiss this message and continue working";
    }
    else if ([state isEqualToString:@"resume"])
    {
        title = @"Data Installation has resumed. You may dismiss this message and continue working";
    }
    else
    {
        title = @"Data Installation Is Complete";
    }

    UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:title
                                                        message:nil
                                                       delegate:self
                                              cancelButtonTitle:@"Dismiss"
                                              otherButtonTitles:nil];

    [alertView show];
}
@end