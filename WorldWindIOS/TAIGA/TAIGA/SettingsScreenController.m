/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import "SettingsScreenController.h"
#import "AppConstants.h"
#import "GPSController.h"

#define ABOUT_SECTION (0)
#define GPS_CONTROLLER_SECTION (1)

#define GPS_SOURCE_NONE (0)
#define GPS_SOURCE_DEVICE (1)
#define GPS_SOURCE_LOCATION_SERVICES (2)

@implementation SettingsScreenController
{
    CGRect myFrame;
    int gpsSource;

    GPSController* gpsController;
}

- (SettingsScreenController*) initWithFrame:(CGRect)frame
{
    self = [super initWithNibName:nil bundle:nil];

    myFrame = frame;

    return self;
}

- (void) loadView
{
    self.view = [[UIView alloc] initWithFrame:myFrame];
    self.view.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    self.view.autoresizesSubviews = YES;

    CGRect tableFrame = CGRectMake(0, 0, myFrame.size.width, myFrame.size.height);
    UITableView* tableView = [[UITableView alloc] initWithFrame:tableFrame style:UITableViewStyleGrouped];
    tableView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    tableView.delegate = self;
    tableView.dataSource = self;
    [tableView reloadData];

    [self.view addSubview:tableView];
}

- (void) viewDidLoad
{
    [super viewDidLoad];

    [self.view setBackgroundColor:[UIColor lightGrayColor]];
}

- (NSInteger) numberOfSectionsInTableView:(UITableView*)tableView
{
    return 2;
}

- (NSInteger) tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == ABOUT_SECTION)
        return 1;

    else if (section == GPS_CONTROLLER_SECTION)
        return 1; // TODO: Change this to 2 when the Location Services GPS source is implemented.

    return 0;
}

- (NSString*) tableView:(UITableView*)tableView titleForHeaderInSection:(NSInteger)section
{
    if (section == ABOUT_SECTION)
        return @"About";
    else if (section == GPS_CONTROLLER_SECTION)
        return @"GPS Source";

    return nil;
}

- (UITableViewCell*) tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
    if ([indexPath section] == ABOUT_SECTION)
        return [self cellForAboutSection:tableView inddexPath:indexPath];
    else if ([indexPath section] == GPS_CONTROLLER_SECTION)
        return [self cellForGPSControllerSection:tableView inddexPath:indexPath];

    return nil;
}

- (UITableViewCell*) cellForAboutSection:(UITableView*)tableView inddexPath:(NSIndexPath*)indexPath
{
    static NSString* cellIdentifier = @"AboutCell";

    UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (cell == nil)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue2 reuseIdentifier:cellIdentifier];
        [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
    }

    [[cell textLabel] setText:@"Version"];
    [[cell detailTextLabel] setText:[[NSString alloc] initWithFormat:@"%@, %@", TAIGA_VERSION, TAIGA_VERSION_DATE]];

    return cell;
}

- (UITableViewCell*) cellForGPSControllerSection:(UITableView*)tableView inddexPath:(NSIndexPath*)indexPath
{
    static NSString* cellIdentifier = @"GPSControllerCell";

    UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (cell == nil)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
        [[cell imageView] setImage:[UIImage imageNamed:@"431-yes.png"]];
        [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
    }

    if ([indexPath row] == 0)
    {
        [[cell textLabel] setText:@"GPS Device"];
        [[cell imageView] setHidden:gpsSource != GPS_SOURCE_DEVICE];
    }
    else if ([indexPath row] == 1)
    {
        [[cell textLabel] setText:@"Location Services"];
        [[cell imageView] setHidden:gpsSource != GPS_SOURCE_LOCATION_SERVICES];
    }

    return cell;
}

- (void) tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath
{
    if ([indexPath section] == GPS_CONTROLLER_SECTION)
    {
        if (gpsSource == GPS_SOURCE_DEVICE)
        {
            [gpsController dispose];
            gpsController = nil;
        }

        if ([indexPath row] == 0)
        {
            gpsSource = gpsSource == GPS_SOURCE_DEVICE ? GPS_SOURCE_NONE : GPS_SOURCE_DEVICE;

            if (gpsSource == GPS_SOURCE_DEVICE)
            {
                gpsController = [[GPSController alloc] init];
            }
        }
        else if ([indexPath row] == 1)
        {
            gpsSource = gpsSource == GPS_SOURCE_LOCATION_SERVICES ? GPS_SOURCE_NONE : GPS_SOURCE_LOCATION_SERVICES;
        }

        [tableView reloadSections:[NSIndexSet indexSetWithIndex:GPS_CONTROLLER_SECTION]
                 withRowAnimation:UITableViewRowAnimationAutomatic];
    }
}

@end