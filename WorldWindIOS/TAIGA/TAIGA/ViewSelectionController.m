/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import "ViewSelectionController.h"
#import "AppConstants.h"
#import "Settings.h"

@implementation ViewSelectionController
{
    id locationTrackingMode;
    BOOL terrainProfileVisible;
}

- (ViewSelectionController*) init
{
    self = [super initWithStyle:UITableViewStyleGrouped];

    locationTrackingMode = [Settings getObjectForName:TAIGA_LOCATION_TRACKING_MODE
                                         defaultValue:TAIGA_DEFAULT_LOCATION_TRACKING_MODE];

    [[self navigationItem] setTitle:@"Views"];
    [self setPreferredContentSize:CGSizeMake(300, 250)];

    return self;
}

- (NSInteger) numberOfSectionsInTableView:(UITableView*)tableView
{
    return 2;
}

- (NSInteger) tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section
{
    return section == 0 ? 2 : 1;
}

- (void) tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    if ([indexPath section] == 0)
    {
        id newMode = locationTrackingMode;
        if ([indexPath row] == 0)
        {
            newMode = TAIGA_LOCATION_TRACKING_MODE_TRACK_UP;
        }
        else if ([indexPath row] == 1)
        {
            newMode = TAIGA_LOCATION_TRACKING_MODE_NORTH_UP;
        }

        if (![locationTrackingMode isEqualToString:newMode])
        {
            locationTrackingMode = newMode;
            [Settings setObject:newMode forName:TAIGA_LOCATION_TRACKING_MODE];
            [tableView reloadSections:[NSIndexSet indexSetWithIndex:0]
                     withRowAnimation:UITableViewRowAnimationAutomatic];
        }
    }
    else if ([indexPath section] == 1)
    {
        terrainProfileVisible = !terrainProfileVisible;
        NSNumber* yn = [[NSNumber alloc] initWithBool:terrainProfileVisible];
        [[NSNotificationCenter defaultCenter] postNotificationName:TAIGA_SHOW_TERRAIN_PROFILE object:yn];

        [tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:indexPath]
                         withRowAnimation:UITableViewRowAnimationAutomatic];
    }
}

- (UITableViewCell*) tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
    static NSString* cellIdentifier = @"cell";

    UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (cell == nil)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
        [[cell imageView] setImage:[UIImage imageNamed:@"431-yes.png"]];
    }

    if ([indexPath section] == 0)
    {
        if ([indexPath row] == 0)
        {
            [[cell textLabel] setText:@"Track Up"];
            [[cell imageView] setHidden:![locationTrackingMode isEqual:TAIGA_LOCATION_TRACKING_MODE_TRACK_UP]];
        }
        else if ([indexPath row] == 1)
        {
            [[cell textLabel] setText:@"North Up"];
            [[cell imageView] setHidden:![locationTrackingMode isEqual:TAIGA_LOCATION_TRACKING_MODE_NORTH_UP]];
        }
        [cell setAccessoryType:UITableViewCellAccessoryNone];
    }
    else if ([indexPath section] == 1)
    {
        [[cell textLabel] setText:@"Terrain Profile"];
        [[cell imageView] setHidden:!terrainProfileVisible];
        [cell setAccessoryType:UITableViewCellAccessoryDetailButton];
    }

    return cell;
}

@end