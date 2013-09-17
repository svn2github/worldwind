/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import "PIREPDataViewController.h"
#import "WWLog.h"


@implementation PIREPDataViewController

- (PIREPDataViewController*) init
{
    self = [super initWithStyle:UITableViewStyleGrouped];

    CGSize size = CGSizeMake(320, 380);
    [self setContentSizeForViewInPopover:size];

    return self;
}

- (void) setEntries:(NSDictionary*)entries
{
    _entries = entries;
    [[self tableView] reloadData];
}

- (NSInteger) numberOfSectionsInTableView:(UITableView*)tableView
{
    return 1;
}

- (NSInteger) tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section
{
    return 7;
}

- (NSString*) tableView:(UITableView*)tableView titleForHeaderInSection:(NSInteger)section
{
    return [[_entries objectForKey:@"raw_text"] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
}

- (UITableViewCell*) tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
    static NSString* cellIdentifier = @"cell";

    @try
    {
        UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
        if (cell == nil)
        {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue2 reuseIdentifier:cellIdentifier];
            [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
        }

        switch ([indexPath row])
        {
            case 0:
                [[cell textLabel] setText:@"Observed"];
                [[cell detailTextLabel] setText:[_entries objectForKey:@"observation_time"]];
                break;

            case 1:
                [[cell textLabel] setText:@"Recieved"];
                [[cell detailTextLabel] setText:[_entries objectForKey:@"receipt_time"]];
                break;

            case 2:
            {
                [[cell textLabel] setText:@"Aircraft"];
                NSString* entry = [_entries objectForKey:@"aircraft_ref"];
                [[cell detailTextLabel] setText:entry != nil ? entry : @""];
                break;
            }
//
//            case 2:
//            {
//                [[cell textLabel] setText:@"Temp"];
//                NSString* entry = [_entries objectForKey:@"temp_c"];
//                if (entry != nil)
//                    [[cell detailTextLabel] setText:[[NSString alloc] initWithFormat:@"%@ C", entry]];
//                else
//                    [[cell detailTextLabel] setText:@""];
//                break;
//            }

            case 3:
            {
                [[cell textLabel] setText:@"Altitude"];
                NSMutableString* detail = [[NSMutableString alloc] initWithString:[_entries objectForKey:@"altitude_ft_msl"]];
                [detail appendString:@" ft MSL"];
                [[cell detailTextLabel] setText:detail];
                break;
            }

            case 4:
                [[cell textLabel] setText:@"Latitude"];
                [[cell detailTextLabel] setText:[_entries objectForKey:@"latitude"]];
                break;

            case 5:
                [[cell textLabel] setText:@"Longitude"];
                [[cell detailTextLabel] setText:[_entries objectForKey:@"longitude"]];
                break;

            case 6:
                [[cell textLabel] setText:@"Type"];
                [[cell detailTextLabel] setText:[_entries objectForKey:@"report_type"]];
                break;

            default:
                [[cell textLabel] setText:@""];
                [[cell detailTextLabel] setText:@""];
                break;
        }

        return cell;
    }
    @catch (NSException* exception)
    {
        WWLogE(@"Forming PIREP data display", exception);
        return nil;
    }
}
@end