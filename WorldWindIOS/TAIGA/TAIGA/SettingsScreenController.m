/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import "SettingsScreenController.h"
#import "Settings.h"
#import "AppConstants.h"

@implementation SettingsScreenController
{
    CGRect myFrame;
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
    self.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.view.autoresizesSubviews = YES;

    UITableView* tableView = [[UITableView alloc] initWithFrame:myFrame style:UITableViewStyleGrouped];
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
    return 1;
}

- (NSInteger) tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section
{
    return 0;
}

- (NSString*) tableView:(UITableView*)tableView titleForHeaderInSection:(NSInteger)section
{
    return nil;
}

- (UITableViewCell*) tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
    return nil;
}

- (UITableViewCell*)cellForElevationThresholdSection:(UITableView*)tableView indexPath:(NSIndexPath*)indexPath
{
    return nil;

//    static NSString* cellID = @"ElevationShadingThresholdCell";
//
//    UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:cellID];
//    if (cell == nil)
//    {
//        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:cellID];
//        [cell setAccessoryType:UITableViewCellAccessoryDisclosureIndicator];
//    }
//
//    if ([indexPath row] == 0)
//    {
//        [[cell textLabel] setText:@"Yellow"];
//        float value = [Settings getFloat:TAIGA_SHADED_ELEVATION_THRESHOLD_YELLOW defaultValue:2000];
//        [[cell detailTextLabel] setText:[NSString stringWithFormat:@"%d meters", (int) value]];
//    }
//    else if ([indexPath row] == 1)
//    {
//        [[cell textLabel] setText:@"Red"];
//        float value = [Settings getFloat:TAIGA_SHADED_ELEVATION_THRESHOLD_RED defaultValue:3000];
//        [[cell detailTextLabel] setText:[NSString stringWithFormat:@"%d meters", (int) value]];
//    }
//
//    return cell;
}

- (void) tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath
{
}
@end