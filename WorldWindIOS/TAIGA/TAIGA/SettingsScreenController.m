/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import "SettingsScreenController.h"
#import "AppConstants.h"
#import "GPSController.h"
#import "Settings.h"
#import "LocationServicesController.h"
#import "WorldWind.h"
#import "GDBMessageController.h"

#define ABOUT_SECTION (0)
#define GPS_CONTROLLER_SECTION (1)
#define GDB_MESSAGE_SECTION (2)
#define DATA_INSTALLATION_SECTION (3)
#define REFRESH_SECTION (4)

#define GPS_DEVICE_ROW (1)
#define LOCATION_SERVICES_DEVICE_ROW (0)
#define GDB_URL_ROW (0)
#define GDB_FREQUENCY_ROW (1)

#define GPS_SOURCE_NONE (0)
#define GPS_SOURCE_DEVICE (1)
#define GPS_SOURCE_LOCATION_SERVICES (2)

#define TABLE_VIEW_TAG (0)
#define GPS_ADDRESS_VIEW_TAG (1)
#define GDB_URL_VIEW_TAG (2)

@implementation SettingsScreenController
{
    CGRect myFrame;
    int gpsSource;

    GPSController* gpsController;
    LocationServicesController* locationServicesController;
    GDBMessageController* gdbMessageController;

    UITextField* gpsSourceTextField;
    UITextField* gdbURLTextField;
    UITextField* fieldBeingEdited;
    UISegmentedControl* gdbFrequencySelector;
}

- (SettingsScreenController*) initWithFrame:(CGRect)frame
{
    self = [super initWithNibName:nil bundle:nil];

    myFrame = frame;

    gpsSource = [Settings getIntForName:TAIGA_GPS_SOURCE defaultValue:GPS_SOURCE_LOCATION_SERVICES];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateTable:)
                                                 name:TAIGA_DATA_FILE_INSTALLATION_PROGRESS object:nil];
    [self startGPS];

    gdbMessageController = [[GDBMessageController alloc] init];

    return self;
}

- (void) loadView
{
    self.view = [[UIView alloc] initWithFrame:myFrame];
    self.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.view.autoresizesSubviews = YES;

    CGRect tableFrame = CGRectMake(0, 0, myFrame.size.width, myFrame.size.height);
    UITableView* tableView = [[UITableView alloc] initWithFrame:tableFrame style:UITableViewStyleGrouped];
    tableView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    tableView.delegate = self;
    tableView.dataSource = self;
    tableView.tag = TABLE_VIEW_TAG;
    [tableView reloadData];

    [self.view addSubview:tableView];
}

- (UITableView*) myTableView
{
    return (UITableView*) [self.view viewWithTag:TABLE_VIEW_TAG];
}

- (void) updateTable:(NSNotification*)notification
{
    if (![NSThread isMainThread])
    {
        [self performSelectorOnMainThread:@selector(updateTable:) withObject:notification waitUntilDone:NO];
    }
    else
    {
        [(UITableView*) [self.view subviews][0] reloadData];
    }
}

- (void) startGPS
{
    if (gpsSource != GPS_SOURCE_NONE)
        [self enableCurrentGPSSource];
    else // Notify that there is no GPS device active
        [[NSNotificationCenter defaultCenter] postNotificationName:TAIGA_GPS_QUALITY object:nil];
}

- (void) enableCurrentGPSSource
{
    if (gpsSource == GPS_SOURCE_DEVICE)
    {
        if (gpsController == nil)
            gpsController = [[GPSController alloc] init];
    }
    else if (gpsSource == GPS_SOURCE_LOCATION_SERVICES)
    {
        if (locationServicesController == nil)
            locationServicesController = [[LocationServicesController alloc] init];

        [locationServicesController setMode:LocationServicesControllerModeAllChanges];
    }
}

- (void) disableCurrentGPSSource
{
    if (gpsSource == GPS_SOURCE_DEVICE)
    {
        [gpsController dispose];
        gpsController = nil;
    }
    else if (gpsSource == GPS_SOURCE_LOCATION_SERVICES)
    {
        if (locationServicesController != nil)
            [locationServicesController setMode:LocationServicesControllerModeDisabled];
    }
}

- (void) viewDidLoad
{
    [super viewDidLoad];

    [self.view setBackgroundColor:[UIColor lightGrayColor]];
}

- (NSInteger) numberOfSectionsInTableView:(UITableView*)tableView
{
    return 5;
}

- (NSInteger) tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == ABOUT_SECTION)
        return 1;

    else if (section == GPS_CONTROLLER_SECTION)
        return 2;

    else if (section == GDB_MESSAGE_SECTION)
        return 2;

    else if (section == DATA_INSTALLATION_SECTION)
        return 1;

    else if (section == REFRESH_SECTION)
        return 1;

    return 0;
}

- (NSString*) tableView:(UITableView*)tableView titleForHeaderInSection:(NSInteger)section
{
    if (section == ABOUT_SECTION)
        return @"About";

    else if (section == GPS_CONTROLLER_SECTION)
        return @"GPS Source";

    else if (section == GDB_MESSAGE_SECTION)
        return @"GDB Messsages";

    else if (section == DATA_INSTALLATION_SECTION)
        return @"Data Installation";

    else if (section == REFRESH_SECTION)
        return @"Refresh";

    return nil;
}

- (UITableViewCell*) tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
    if ([indexPath section] == ABOUT_SECTION)
        return [self cellForAboutSection:tableView indexPath:indexPath];
    else if ([indexPath section] == GPS_CONTROLLER_SECTION)
        return [self cellForGPSControllerSection:tableView indexPath:indexPath];
    else if ([indexPath section] == GDB_MESSAGE_SECTION)
        return [self cellForGDBMessageSection:tableView indexPath:indexPath];
    else if ([indexPath section] == DATA_INSTALLATION_SECTION)
        return [self cellForDataInstallationSection:tableView inddexPath:indexPath];
    else if ([indexPath section] == REFRESH_SECTION)
        return [self cellForRefreshSection:tableView indexPath:indexPath];

    return nil;
}

- (UITableViewCell*) cellForAboutSection:(UITableView*)tableView indexPath:(NSIndexPath*)indexPath
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

- (UITableViewCell*) cellForGPSControllerSection:(UITableView*)tableView indexPath:(NSIndexPath*)indexPath
{
    UITableViewCell* cell;

    if ([indexPath row] == GPS_DEVICE_ROW)
    {
        static NSString* cellIdentifier = @"GPSControllerDeviceCell";

        cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
        if (cell == nil)
        {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
            [[cell imageView] setImage:[UIImage imageNamed:@"431-yes.png"]];
            [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
            [[cell textLabel] setText:@"GPS Device"];

            // screen.
            gpsSourceTextField = [[UITextField alloc] initWithFrame:CGRectMake(
                    170,
                    cell.textLabel.frame.origin.y + 5,
                    500, cell.contentView.bounds.size.height - 10)];
            [gpsSourceTextField setTag:GPS_ADDRESS_VIEW_TAG];
            [gpsSourceTextField setFont:cell.textLabel.font];
            [gpsSourceTextField setBorderStyle:UITextBorderStyleRoundedRect];
            [gpsSourceTextField setAutoresizingMask:UIViewAutoresizingFlexibleRightMargin];
            [gpsSourceTextField setDelegate:self];
            [gpsSourceTextField setClearButtonMode:UITextFieldViewModeWhileEditing];
            [gpsSourceTextField setBackgroundColor:[[UIColor alloc] initWithRed:0.95 green:0.95 blue:0.95 alpha:1]];
            [[cell contentView] setAutoresizesSubviews:YES];
            [cell.contentView addSubview:gpsSourceTextField];

            UIButton* defaultButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
            [defaultButton setFrame:CGRectMake(10, 0, 90, cell.bounds.size.height)];
            [defaultButton setTitle:@"Default" forState:UIControlStateNormal];
            [defaultButton setBackgroundColor:[UIColor clearColor]];
            [[defaultButton titleLabel] setFont:[[cell textLabel] font]];
            [defaultButton addTarget:self action:@selector(handleDefaultGPSAddressButton)
                    forControlEvents:UIControlEventTouchUpInside];
            [cell setAccessoryView:defaultButton];
        }

        [[cell imageView] setHidden:gpsSource != GPS_SOURCE_DEVICE];

        NSString* address = (NSString*) [Settings getObjectForName:TAIGA_GPS_DEVICE_ADDRESS];
        UITextField* addressView = (UITextField*) [[cell contentView] viewWithTag:GPS_ADDRESS_VIEW_TAG];
        [addressView setText:address != nil ? address : @""];
    }
    else if ([indexPath row] == LOCATION_SERVICES_DEVICE_ROW)
    {
        static NSString* cellIdentifier = @"GPSControllerLocationServicesCell";

        cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
        if (cell == nil)
        {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
            [[cell imageView] setImage:[UIImage imageNamed:@"431-yes.png"]];
            [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
        }

        [[cell textLabel] setText:@"iPad"];
        [[cell imageView] setHidden:gpsSource != GPS_SOURCE_LOCATION_SERVICES];
    }

    return cell;
}

- (UITableViewCell*) cellForGDBMessageSection:(UITableView*)tableView indexPath:(NSIndexPath*)indexPath
{
    UITableViewCell* cell;

    if ([indexPath row] == GDB_URL_ROW)
    {
        static NSString* cellIdentifier = @"GDBURLCell";

        cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
        if (cell == nil)
        {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
            [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
            [[cell textLabel] setText:@"GDB URL"];

            gdbURLTextField = [[UITextField alloc] initWithFrame:CGRectMake(
                    170,
                    cell.textLabel.frame.origin.y + 5,
                    500, cell.contentView.bounds.size.height - 10)];
            [gdbURLTextField setTag:GDB_URL_VIEW_TAG];
            [gdbURLTextField setFont:cell.textLabel.font];
            [gdbURLTextField setBorderStyle:UITextBorderStyleRoundedRect];
            [gdbURLTextField setAutoresizingMask:UIViewAutoresizingFlexibleRightMargin];
            [gdbURLTextField setDelegate:self];
            [gdbURLTextField setClearButtonMode:UITextFieldViewModeWhileEditing];
            [gdbURLTextField setBackgroundColor:[[UIColor alloc] initWithRed:0.95 green:0.95 blue:0.95 alpha:1]];
            [[cell contentView] setAutoresizesSubviews:YES];
            [cell.contentView addSubview:gdbURLTextField];

            UIButton* defaultButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
            [defaultButton setFrame:CGRectMake(10, 0, 90, cell.bounds.size.height)];
            [defaultButton setTitle:@"Default" forState:UIControlStateNormal];
            [defaultButton setBackgroundColor:[UIColor clearColor]];
            [[defaultButton titleLabel] setFont:[[cell textLabel] font]];
            [defaultButton addTarget:self action:@selector(handleDefaultGDBAddressButton)
                    forControlEvents:UIControlEventTouchUpInside];
            [cell setAccessoryView:defaultButton];
        }

        [[cell imageView] setHidden:YES];

        NSString* address = (NSString*) [Settings getObjectForName:TAIGA_GDB_DEVICE_ADDRESS];
        UITextField* addressView = (UITextField*) [[cell contentView] viewWithTag:GDB_URL_VIEW_TAG];
        [addressView setText:address != nil ? address : @""];
    }
    else if ([indexPath row] == GDB_FREQUENCY_ROW)
    {
        static NSString* cellIdentifier = @"GDBFrequencyCell";

        cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
        if (cell == nil)
        {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
            [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
            [[cell textLabel] setText:@"Frequency"];

            NSArray* gdbFrequencies = [NSArray arrayWithObjects:
                    @"10 seconds",
                    @"1 minute",
                    @"5 minutes",
                    @"15 minutes",
                    @"1 hour",
                    nil
            ];
            gdbFrequencySelector = [[UISegmentedControl alloc] initWithItems:gdbFrequencies];
            gdbFrequencySelector.frame = CGRectMake(170, 5, 500, cell.contentView.frame.size.height - 10);
            [gdbFrequencySelector setAutoresizingMask:UIViewAutoresizingFlexibleRightMargin];
            [gdbFrequencySelector addTarget:self action:@selector(handleGDBFrequencySelection)
                           forControlEvents:UIControlEventValueChanged];

            [[cell contentView] setAutoresizesSubviews:YES];
            [cell.contentView addSubview:gdbFrequencySelector];
        }

        int updateFrequency = [gdbMessageController getUpdateFrequency];
        NSString* unit = @"second";
        if (updateFrequency >= 3600)
        {
            unit = @"hour";
            updateFrequency /= 3600;
        }
        else if (updateFrequency >= 60)
        {
            unit = @"minute";
            updateFrequency /= 60;
        }
        NSString* frequencyString = [[NSString alloc] initWithFormat:@"%d %@", updateFrequency, unit];
        for (int i = 0; i < gdbFrequencySelector.numberOfSegments; i++)
        {
            NSString* segmentTitle = [gdbFrequencySelector titleForSegmentAtIndex:(NSUInteger) i];
            if ([segmentTitle hasPrefix:frequencyString])
            {
                gdbFrequencySelector.selectedSegmentIndex = i;
                break;
            }
        }
    }

    return cell;
}

- (void) handleGDBFrequencySelection
{
    int selectedIndex = [gdbFrequencySelector selectedSegmentIndex];
    NSString* selectedString = [gdbFrequencySelector titleForSegmentAtIndex:(NSUInteger) selectedIndex];
    NSArray* tokens = [selectedString componentsSeparatedByString:@" "];
    int updateFrequency = [((NSString*) [tokens objectAtIndex:0]) intValue];
    NSString* unit = [tokens objectAtIndex:1];
    if ([unit hasPrefix:@"minute"])
        updateFrequency *= 60;
    else if ([unit hasPrefix:@"hour"])
        updateFrequency *= 3600;

    [gdbMessageController setUpdateFrequency:updateFrequency];
}

- (UITableViewCell*) cellForRefreshSection:(UITableView*)tableView indexPath:(NSIndexPath*)indexPath
{
    UITableViewCell* cell;

    static NSString* cellIdentifier = @"RefreshInformationCell";

    cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (cell == nil)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
        [cell setSelectionStyle:UITableViewCellSelectionStyleNone];

        UIButton* refreshButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        [refreshButton setFrame:CGRectMake(15, 10, 100, 30)];
        [refreshButton setTitle:@"  Refresh all information" forState:UIControlStateNormal];
        [refreshButton setImage:[UIImage imageNamed:@"01-refresh.png"] forState:UIControlStateNormal];
        [refreshButton setBackgroundColor:[UIColor clearColor]];
        [[refreshButton titleLabel] setFont:[[cell textLabel] font]];
        [refreshButton addTarget:self action:@selector(handleRefreshButtonPressed)
                forControlEvents:UIControlEventTouchUpInside];
        [refreshButton sizeToFit];
//
//        CABasicAnimation *halfTurn;
//        halfTurn = [CABasicAnimation animationWithKeyPath:@"transform.rotation"];
//        halfTurn.fromValue = [NSNumber numberWithFloat:0];
//        halfTurn.toValue = [NSNumber numberWithFloat:(float) ((360 * M_PI) / 180)];
//        halfTurn.duration = 1.0;
//        halfTurn.repeatCount = HUGE_VALF;
//        [[refreshButton.imageView layer] addAnimation:halfTurn forKey:@"180"];

        [cell.contentView addSubview:refreshButton];
    }

    return cell;
}

- (void) handleRefreshButtonPressed
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^
    {
        if ([WorldWind isNetworkAvailable])
        {
            [[NSNotificationCenter defaultCenter] postNotificationName:TAIGA_REFRESH object:nil];
        }
        else
        {
            UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:@"Unable to Refresh"
                                                                message:@"Cannot refresh because network is unavailable"
                                                               delegate:self
                                                      cancelButtonTitle:@"Dismiss"
                                                      otherButtonTitles:nil];
            dispatch_async(dispatch_get_main_queue(), ^
            {
                [alertView show];
            });
        }
    });
}

- (void) handleDefaultGPSAddressButton
{
    [GPSController setDefaultGPSDeviceAddress];
    [[self myTableView] reloadData];
}

- (void) handleDefaultGDBAddressButton
{
    [GDBMessageController setDefaultGDBDeviceAddress];
    [[self myTableView] reloadData];
}

- (void) textFieldDidBeginEditing:(UITextField*)textField
{
    fieldBeingEdited = textField;
}

- (BOOL) textFieldShouldReturn:(UITextField*)textField
{
    [textField resignFirstResponder];

    return NO;
}

- (void) textFieldDidEndEditing:(UITextField*)textField
{
    if (fieldBeingEdited == gpsSourceTextField)
    {
        [Settings setObject:[textField text] forName:TAIGA_GPS_DEVICE_ADDRESS];
    }
    else if (fieldBeingEdited == gdbURLTextField)
    {
        [Settings setObject:[textField text] forName:TAIGA_GDB_DEVICE_ADDRESS];
    }

    fieldBeingEdited = nil;

}

- (UITableViewCell*) cellForDataInstallationSection:(UITableView*)tableView inddexPath:(NSIndexPath*)indexPath
{
    static NSString* cellIdentifier = @"DataInstallationCell";

    UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (cell == nil)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
        [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
    }

    float dataInstallationProgress = [Settings getFloatForName:TAIGA_DATA_FILE_INSTALLATION_PROGRESS];

    NSString* msg;
    if (dataInstallationProgress == 0)
        msg = @"Data installation is incomplete";
    else if (dataInstallationProgress == 100)
        msg = @"Data installation is complete";
    else
        msg = [[NSString alloc] initWithFormat:@"Data installation is %d%% complete", (int) dataInstallationProgress];

    [[cell textLabel] setText:msg];

    return cell;
}

- (void) tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath
{
    [self disableCurrentGPSSource];

    if ([indexPath section] == GPS_CONTROLLER_SECTION)
    {
        if ([indexPath row] == GPS_DEVICE_ROW)
            gpsSource = gpsSource == GPS_SOURCE_DEVICE ? GPS_SOURCE_NONE : GPS_SOURCE_DEVICE;
        else if ([indexPath row] == LOCATION_SERVICES_DEVICE_ROW)
            gpsSource = gpsSource == GPS_SOURCE_LOCATION_SERVICES ? GPS_SOURCE_NONE : GPS_SOURCE_LOCATION_SERVICES;

        [Settings setInt:gpsSource forName:TAIGA_GPS_SOURCE];

        if (gpsSource != GPS_SOURCE_NONE)
            [self enableCurrentGPSSource];

        [tableView reloadSections:[NSIndexSet indexSetWithIndex:GPS_CONTROLLER_SECTION]
                 withRowAnimation:UITableViewRowAnimationAutomatic];
    }

    if (gpsSource == GPS_SOURCE_NONE)
        [[NSNotificationCenter defaultCenter] postNotificationName:TAIGA_GPS_QUALITY object:nil];
}

@end