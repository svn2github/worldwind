/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import "PositionReadoutController.h"
#import "WWPosition.h"
#import "AppConstants.h"

@implementation PositionReadoutController

- (PositionReadoutController*) init
{
    self = [super initWithStyle:UITableViewStylePlain];

    [[self navigationItem] setTitle:@"Position"];
    [self setPreferredContentSize:CGSizeMake(200, 90)];
    [[self tableView] setSeparatorStyle:UITableViewCellSeparatorStyleNone];

    return self;
}

- (NSInteger) numberOfSectionsInTableView:(UITableView*)tableView
{
    return 1;
}

- (NSInteger) tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section
{
    return 3;
}

- (CGFloat) tableView:(UITableView*)tableView heightForRowAtIndexPath:(NSIndexPath*)indexPath
{
    return 28;
}

- (UITableViewCell*) tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
    static NSString* cellIdentifier = @"LatLonReadoutCell";

    UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (cell == nil)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue2 reuseIdentifier:cellIdentifier];
    }

    if ([indexPath row] == 0)
    {
        [[cell textLabel] setText:@"Latitude"];
        [[cell detailTextLabel] setText:[NSString localizedStringWithFormat:@"%.4f\u00B0", [_position latitude]]];
    }
    else if ([indexPath row] == 1)
    {
        [[cell textLabel] setText:@"Longitude"];
        [[cell detailTextLabel] setText:[NSString localizedStringWithFormat:@"%.4f\u00B0", [_position longitude]]];
    }
    else if ([indexPath row] == 2)
    {
        [[cell textLabel] setText:@"Altitude"];
        [[cell detailTextLabel] setText:[NSString localizedStringWithFormat:@"%d feet",
                                                                            (int) ([_position altitude] * TAIGA_METERS_TO_FEET)]];
    }

    [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
    [[cell textLabel] setTextAlignment:NSTextAlignmentLeft];

    return cell;
}

@end