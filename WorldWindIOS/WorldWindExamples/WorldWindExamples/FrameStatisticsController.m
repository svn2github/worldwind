/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import "FrameStatisticsController.h"
#import "WorldWindView.h"
#import "WorldWindConstants.h"
#import "WWSceneController.h"

@implementation FrameStatisticsController

- (FrameStatisticsController*) initWithView:(WorldWindView*)wwv
{
    self = [super initWithStyle:UITableViewStyleGrouped];

    _wwv = wwv;

    timer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(handleTimer) userInfo:nil
                                            repeats:YES];

    return self;
}

- (void) handleTimer
{
    [[self tableView] reloadData];
}

- (NSInteger) numberOfSectionsInTableView:(UITableView*)tableView
{
    return 1;
}

- (NSInteger) tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section
{
    return 2;//section == 0 ? 1 : 2;
}

- (NSString*) tableView:(UITableView*)tableView titleForHeaderInSection:(NSInteger)section
{
    return section == 0 ? @"Frame" : nil;
}
- (UITableViewCell*) tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
    UITableViewCell* cell = nil;

    if ([indexPath section] == -1)
    {
        static NSString* switchCell = @"switchCellForRunContinuously";

        cell = [tableView dequeueReusableCellWithIdentifier:switchCell];
        if (cell == nil)
        {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:switchCell];

            UISwitch* enableSwitch = [[UISwitch alloc] init];
            [enableSwitch addTarget:self action:@selector(handleDrawContinuouslySwitch:)
                   forControlEvents:UIControlEventValueChanged];
            [cell setAccessoryView:[[UIView alloc] initWithFrame:[enableSwitch frame]]];
            [[cell accessoryView] addSubview:enableSwitch];
            [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
            [[cell textLabel] setText:@"Draw Continuously"];
        }
    }
    else if ([indexPath section] == 0)
    {
        static NSString* cellID = @"cellForItemDisplay";

        cell = [tableView dequeueReusableCellWithIdentifier:cellID];
        if (cell == nil)
        {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue2 reuseIdentifier:cellID];
        }

        WWSceneController* sc = [_wwv sceneController];
        NSString* name = nil;
        NSString* value = nil;

        switch ([indexPath row])
        {
            case 0:
                name = @"Avg Time";
                value = [[NSString alloc] initWithFormat:@"%d ms", (int) (1000 * [sc frameTimeAverage])];
                break;

            case 1:
                name = @"Rate";
                value = [[NSString alloc] initWithFormat:@"%d Hz", (int) [sc frameRateAverage]];
                break;

            default:
                break;
        }

        [[cell textLabel] setText:name];
        [[cell detailTextLabel] setText:value];

    }

    return cell;
}

- (void) handleDrawContinuouslySwitch:(UISwitch*)enableSwitch
{
    [_wwv setDrawContinuously:[enableSwitch isOn]];

    if ([enableSwitch isOn])
    {
        NSNotification* redrawNotification = [NSNotification notificationWithName:WW_REQUEST_REDRAW object:self];
        [[NSNotificationCenter defaultCenter] postNotification:redrawNotification];
    }
}

@end