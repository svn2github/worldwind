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
    BOOL trackUp;
    BOOL terrainProfileVisible;
}

- (ViewSelectionController*) initWithWorldWindView:(WorldWindView*)wwv
{
    self = [super initWithStyle:UITableViewStyleGrouped];

    _wwv = wwv;

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
    if ([indexPath section] == 0)
    {

    }
    else if ([indexPath section] == 1)
    {
        terrainProfileVisible = !terrainProfileVisible;
        NSNumber* yn = [[NSNumber alloc] initWithBool:terrainProfileVisible];
        [[NSNotificationCenter defaultCenter] postNotificationName:TAIGA_SHOW_TERRAIN_PROFILE object:yn];
    }

    [[self tableView] reloadData];
}

- (UITableViewCell*) tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
    static NSString* cellIdentifier = @"cell";

    UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (cell == nil)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
        [[cell imageView] setImage:[UIImage imageNamed:@"431-yes.png"]];
        [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
    }

    if ([indexPath section] == 0)
    {
        if ([indexPath row] == 0)
        {
            [[cell textLabel] setText:@"Track Up"];
            [[cell imageView] setHidden:!trackUp];
        }
        else if ([indexPath row] == 1)
        {
            [[cell textLabel] setText:@"North Up"];
            [[cell imageView] setHidden:trackUp];
        }
    }
    else if ([indexPath section] == 1)
    {
        [[cell textLabel] setText:@"Terrain Profile"];
        [[cell imageView] setHidden:!terrainProfileVisible];
        [cell setAccessoryType: UITableViewCellAccessoryDetailButton];
    }

    return cell;
}

@end