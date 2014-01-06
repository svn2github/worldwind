/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import "ViewSelectionController.h"
#import "WorldWindView.h"
#import "AppConstants.h"

@implementation ViewSelectionController
{
    NSString* navigationMode;
    BOOL terrainProfileVisible;
}

- (ViewSelectionController*) initWithWorldWindView:(WorldWindView*)wwv
{
    self = [super initWithStyle:UITableViewStyleGrouped];

    _wwv = wwv;

    navigationMode = [[NSUserDefaults standardUserDefaults] objectForKey:TAIGA_NAVIGATION_MODE];
    if (navigationMode == nil)
    {
        navigationMode = TAIGA_NAVIGATION_MODE_TRACK_UP;
        [self postNavigationMode];
    }

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
        NSString* newNavigationMode = navigationMode;
        if ([indexPath row] == 0)
        {
            newNavigationMode = TAIGA_NAVIGATION_MODE_TRACK_UP;
        }
        else if ([indexPath row] == 1)
        {
            newNavigationMode = TAIGA_NAVIGATION_MODE_NORTH_UP;
        }

        if (![navigationMode isEqualToString:newNavigationMode])
        {
            navigationMode = newNavigationMode;
            [self postNavigationMode];
        }

        [tableView reloadSections:[NSIndexSet indexSetWithIndex:0]
                 withRowAnimation:UITableViewRowAnimationAutomatic];
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
            [[cell imageView] setHidden:![navigationMode isEqual:TAIGA_NAVIGATION_MODE_TRACK_UP]];
        }
        else if ([indexPath row] == 1)
        {
            [[cell textLabel] setText:@"North Up"];
            [[cell imageView] setHidden:![navigationMode isEqual:TAIGA_NAVIGATION_MODE_NORTH_UP]];
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

- (void) postNavigationMode
{
    [[NSUserDefaults standardUserDefaults] setObject:navigationMode forKey:TAIGA_NAVIGATION_MODE];
    [[NSNotificationCenter defaultCenter] postNotificationName:TAIGA_NAVIGATION_MODE object:navigationMode];
}

@end