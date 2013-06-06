/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import "METARDataViewController.h"


@implementation METARDataViewController

- (METARDataViewController*) init
{
    self = [super init];

    CGSize size = CGSizeMake(320, 320);
    [self setContentSizeForViewInPopover:size];

    return self;
}

- (NSInteger) numberOfSectionsInTableView:(UITableView*)tableView
{
    return [_entries objectForKey:@"sky_conditions"] != nil ? 2 : 1;
}

- (NSInteger) tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section
{
    return section == 0 ? 11 : [[_entries objectForKey:@"sky_conditions"] count];
}

- (NSString*) tableView:(UITableView*)tableView titleForHeaderInSection:(NSInteger)section
{
    return section == 0 ? @"" : @"Sky Conditions";
}

- (UITableViewCell*) tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath
{

    static NSString* cellIdentifier = @"cell";

    UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (cell == nil)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue2 reuseIdentifier:cellIdentifier];
    }

    if ([indexPath section] == 1)
    {
        NSArray* skyConditions = [_entries objectForKey:@"sky_conditions"];
        [[cell textLabel] setText:nil];
        [[cell detailTextLabel] setText:[skyConditions objectAtIndex:(NSUInteger)[indexPath row]]];
        return cell;
    }

    switch ([indexPath row])
    {
        case 0:
            [[cell textLabel] setText:@"Observed at"];
            [[cell detailTextLabel] setText:[_entries objectForKey:@"observation_time"]];
            break;

        case 1:
            [[cell textLabel] setText:@"Station"];
            [[cell detailTextLabel] setText:[_entries objectForKey:@"station_id"]];
            break;

        case 2:
        {
            [[cell textLabel] setText:@"Temperature"];
            NSMutableString* detail = [[NSMutableString alloc] initWithString:[_entries objectForKey:@"temp_c"]];
            [detail appendString:@" C"];
            [[cell detailTextLabel] setText:detail];
            break;
        }

        case 3:
        {
            [[cell textLabel] setText:@"Dewpoint"];
            NSMutableString* detail = [[NSMutableString alloc] initWithString:[_entries objectForKey:@"dewpoint_c"]];
            [detail appendString:@" C"];
            [[cell detailTextLabel] setText:detail];
            break;
        }

        case 4:
        {
            [[cell textLabel] setText:@"Visibility"];
            NSMutableString* detail = [[NSMutableString alloc] initWithString:[_entries
                    objectForKey:@"visibility_statute_mi"]];
            [detail appendString:@" st mi"];
            [[cell detailTextLabel] setText:detail];
            break;
        }

        case 5:
        {
            [[cell textLabel] setText:@"Altimeter"];
            NSMutableString* detail = [[NSMutableString alloc] initWithString:[_entries objectForKey:@"altim_in_hg"]];
            [detail appendString:@" Hg"];
            [[cell detailTextLabel] setText:detail];
            break;
        }

        case 6:
        {
            [[cell textLabel] setText:@"Elevation"];
            NSMutableString* detail = [[NSMutableString alloc] initWithString:[_entries objectForKey:@"elevation_m"]];
            [detail appendString:@" meters"];
            [[cell detailTextLabel] setText:detail];
            break;
        }

        case 7:
            [[cell textLabel] setText:@"Latitude"];
            [[cell detailTextLabel] setText:[_entries objectForKey:@"latitude"]];
            break;

        case 8:
            [[cell textLabel] setText:@"Longitude"];
            [[cell detailTextLabel] setText:[_entries objectForKey:@"longitude"]];
            break;

        case 9:
            [[cell textLabel] setText:@"Category"];
            [[cell detailTextLabel] setText:[_entries objectForKey:@"flight_category"]];
            break;

        case 10:
            [[cell textLabel] setText:@"Type"];
            [[cell detailTextLabel] setText:[_entries objectForKey:@"metar_type"]];
            break;

        default:
            [[cell textLabel] setText:@""];
            [[cell detailTextLabel] setText:@""];
            break;
    }

    return cell;
}

@end