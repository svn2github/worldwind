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

    [self installPreparedData];
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
    [self swapScreenController:weatherScreenController button:weatherButton];
}

- (void) handleCharts
{
    [self swapScreenController:chartsScreenController button:chartsButton];
}

- (void) handleSettings
{
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
}

- (void) installPreparedData
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^
    {
        NSString* docsDir = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
        NSString* cacheDir = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0];
        NSString* zipPath = [docsDir stringByAppendingPathComponent:@"TAIGAData.zip"];

        BOOL archiveExists = [[NSFileManager defaultManager] fileExistsAtPath:zipPath];
        if (!archiveExists)
            return; // nothing to install

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
        NSArray* centralDirectory = [archive centralDirectory];

        // Mark that we've extracted files from this archive.
        [Settings setDouble:currentDataFileID forName:TAIGA_DATA_FILE_ID];

        // Iterate over the central directory and extract each entry.
        NSUInteger numEntries = [centralDirectory count];
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

        [self performSelectorOnMainThread:@selector(performAlert) withObject:self waitUntilDone:NO];
    });
}

- (void) performAlert
{
    UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:@"Data Installation Is Complete"
                                                        message:nil
                                                       delegate:self
                                              cancelButtonTitle:@"Dismiss"
                                              otherButtonTitles:nil];
    [alertView show];
}
@end