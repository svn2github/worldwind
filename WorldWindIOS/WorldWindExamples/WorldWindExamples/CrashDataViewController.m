/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import "CrashDataViewController.h"

@implementation CrashDataViewController

- (CrashDataViewController*) init
{
    self = [super init];

    CGSize size = CGSizeMake(320, 320);
    [self setContentSizeForViewInPopover:size];

    return self;
}

- (NSInteger) numberOfSectionsInTableView:(UITableView*)tableView
{
    return 1;
}

- (NSInteger) tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section
{
    return 11;
}

- (UITableViewCell*) tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath
{

    static NSString* cellIdentifier = @"cell";

    UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (cell == nil)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue2 reuseIdentifier:cellIdentifier];
    }

    switch ([indexPath row])
    {
        case 0:
            [[cell textLabel] setText:@"Crash Date"];
            [[cell detailTextLabel] setText:[_entries objectForKey:@"Crashdate"]];
            break;

        case 1:
            [[cell textLabel] setText:@"Aircraft Tail"];
            [[cell detailTextLabel] setText:[_entries objectForKey:@"AIRCRAFT_TAIL__"]];
            break;

        case 2:
            [[cell textLabel] setText:@"Aircraft Name"];
            [[cell detailTextLabel] setText:[_entries objectForKey:@"AcftName"]];
            break;

        case 3:
            [[cell textLabel] setText:@"Aircraft Model"];
            [[cell detailTextLabel] setText:[_entries objectForKey:@"AcftModel"]];
            break;

        case 4:
            [[cell textLabel] setText:@"Aircraft Color"];
            [[cell detailTextLabel] setText:[_entries objectForKey:@"AcftColor"]];
            break;

        case 5:
            [[cell textLabel] setText:@"Latitude"];
            [[cell detailTextLabel] setText:[_entries objectForKey:@"LATITUDE"]];
            break;

        case 6:
            [[cell textLabel] setText:@"Longitude"];
            [[cell detailTextLabel] setText:[_entries objectForKey:@"LONGITUDE"]];
            break;

        case 7:
            [[cell textLabel] setText:@"Removed Date"];
            [[cell detailTextLabel] setText:[_entries objectForKey:@"RemovedDate"]];
            break;

        case 8:
            [[cell textLabel] setText:@"Remarks"];
            [[cell detailTextLabel] setText:[_entries objectForKey:@"Remarks"]];
            break;

        case 9:
            [[cell textLabel] setText:@"Map"];
            [[cell detailTextLabel] setText:[_entries objectForKey:@"Map"]];
            break;

        case 10:
            [[cell textLabel] setText:@"Pin Number"];
            [[cell detailTextLabel] setText:[_entries objectForKey:@"PinNumber"]];
            break;

        default:
            [[cell textLabel] setText:@""];
            [[cell detailTextLabel] setText:@""];
            break;
    }

    return cell;
}

@end