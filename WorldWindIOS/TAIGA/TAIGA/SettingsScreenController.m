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

#define ABOUT_SECTION (0)
#define GPS_CONTROLLER_SECTION (1)
#define DATA_INSTALLATION_SECTION (2)
#define REFRESH_SECTION (3)

#define GPS_DEVICE_ROW (1)
#define LOCATION_SERVICES_DEVICE_ROW (0)

#define GPS_SOURCE_NONE (0)
#define GPS_SOURCE_DEVICE (1)
#define GPS_SOURCE_LOCATION_SERVICES (2)

#define TABLE_VIEW_TAG (0)
#define GPS_ADDRESS_VIEW_TAG (1)

@implementation SettingsScreenController
{
    CGRect myFrame;
    int gpsSource;

    GPSController* gpsController;
    LocationServicesController* locationServicesController;
    bool locationTrackingEnabled;

    UITextField* fieldBeingEdited;
}

- (SettingsScreenController*) initWithFrame:(CGRect)frame
{
    self = [super initWithNibName:nil bundle:nil];

    myFrame = frame;

    gpsSource = [Settings getIntForName:TAIGA_GPS_SOURCE defaultValue:GPS_SOURCE_LOCATION_SERVICES];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateTable:)
                                                 name:TAIGA_DATA_FILE_INSTALLATION_PROGRESS object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(locationTrackingChanged:)
                                                 name:TAIGA_LOCATION_TRACKING_ENABLED object:nil];

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

- (void) locationTrackingChanged:(NSNotification*)notification
{
    if (locationTrackingEnabled)
        [self disableCurrentTrackingSource];

    locationTrackingEnabled = ((NSNumber*) [notification object]).boolValue;

    if (locationTrackingEnabled)
    {
        if (gpsSource != GPS_SOURCE_NONE)
            [self enableCurrentTrackingSource];
        else // Notify that there is no GPS device active
            [[NSNotificationCenter defaultCenter] postNotificationName:TAIGA_GPS_QUALITY object:nil];

    }
}

- (void) enableCurrentTrackingSource
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

- (void) disableCurrentTrackingSource
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
    return 4;
}

- (NSInteger) tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == ABOUT_SECTION)
        return 1;

    else if (section == GPS_CONTROLLER_SECTION)
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

    else if (section == DATA_INSTALLATION_SECTION)
        return @"Data Installation";

    else if (section == REFRESH_SECTION)
        return @"Refresh";

    return nil;
}

- (UITableViewCell*) tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
    if ([indexPath section] == ABOUT_SECTION)
        return [self cellForAboutSection:tableView inddexPath:indexPath];
    else if ([indexPath section] == GPS_CONTROLLER_SECTION)
        return [self cellForGPSControllerSection:tableView inddexPath:indexPath];
    else if ([indexPath section] == DATA_INSTALLATION_SECTION)
        return [self cellForDataInstallationSection:tableView inddexPath:indexPath];
    else if ([indexPath section] == REFRESH_SECTION)
        return [self cellForRefreshSection:tableView inddexPath:indexPath];

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

            // TODO: Determine how to make the address view auto resize without running off the right side of the
            // screen.
            UITextField* addressView = [[UITextField alloc] initWithFrame:CGRectMake(
                    200,
                    cell.textLabel.frame.origin.y,
                    600, cell.contentView.bounds.size.height)];
            [addressView setTag:GPS_ADDRESS_VIEW_TAG];
            [addressView setFont:cell.textLabel.font];
            [addressView setAutoresizingMask:UIViewAutoresizingFlexibleWidth]; // TODO: this seems to have no effect
            [addressView setDelegate:self];
            [addressView setClearButtonMode:UITextFieldViewModeWhileEditing];
            [cell.contentView addSubview:addressView];

            UIButton* defaultButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
            [defaultButton setFrame:CGRectMake(0, 0, 100, cell.bounds.size.height)];
            [defaultButton setTitle:@"Default URL" forState:UIControlStateNormal];
            [defaultButton setBackgroundColor:[UIColor clearColor]];
            [[defaultButton titleLabel] setFont:[[cell textLabel] font]];
            [defaultButton addTarget:self action:@selector(handleDefaultAddressButton)
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

- (UITableViewCell*) cellForRefreshSection:(UITableView*)tableView inddexPath:(NSIndexPath*)indexPath
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
        [refreshButton setTitle:@"  Refresh All Information" forState:UIControlStateNormal];
        [refreshButton setImage:[UIImage imageNamed:@"01-refresh.png"] forState:UIControlStateNormal];
        [refreshButton setBackgroundColor:[UIColor clearColor]];
        [[refreshButton titleLabel] setFont:[[cell textLabel] font]];
        [refreshButton addTarget:self action:@selector(handleDefaultAddressButton)
                forControlEvents:UIControlEventTouchUpInside];
        [refreshButton sizeToFit];
        [refreshButton addTarget:self action:@selector(handleRefreshButtonPressed) forControlEvents:UIControlEventTouchUpInside];
        [cell.contentView addSubview:refreshButton];
    }

    return cell;
}

- (void) handleRefreshButtonPressed
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
        [alertView show];
    }
}

- (void) handleDefaultAddressButton
{
    if (fieldBeingEdited != nil)
        [fieldBeingEdited resignFirstResponder];

    [GPSController setDefaultGPSDeviceAddress];
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
    fieldBeingEdited = nil;

    [Settings setObject:[textField text] forName:TAIGA_GPS_DEVICE_ADDRESS];
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
    [self disableCurrentTrackingSource];

    if ([indexPath section] == GPS_CONTROLLER_SECTION)
    {
        if ([indexPath row] == GPS_DEVICE_ROW)
            gpsSource = gpsSource == GPS_SOURCE_DEVICE ? GPS_SOURCE_NONE : GPS_SOURCE_DEVICE;
        else if ([indexPath row] == LOCATION_SERVICES_DEVICE_ROW)
            gpsSource = gpsSource == GPS_SOURCE_LOCATION_SERVICES ? GPS_SOURCE_NONE : GPS_SOURCE_LOCATION_SERVICES;

        [Settings setInt:gpsSource forName:TAIGA_GPS_SOURCE];

        [tableView reloadSections:[NSIndexSet indexSetWithIndex:GPS_CONTROLLER_SECTION]
                 withRowAnimation:UITableViewRowAnimationAutomatic];

        if (gpsSource != GPS_SOURCE_NONE && locationTrackingEnabled)
            [self enableCurrentTrackingSource];
    }

    if (gpsSource == GPS_SOURCE_NONE)
        [[NSNotificationCenter defaultCenter] postNotificationName:TAIGA_GPS_QUALITY object:nil];
}

@end