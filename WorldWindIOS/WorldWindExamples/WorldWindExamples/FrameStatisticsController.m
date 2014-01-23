/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import "FrameStatisticsController.h"
#import "WorldWind/Util/WWFrameStatistics.h"
#import "WorldWind/WorldWindView.h"

#define SETTINGS_SECTION (0)
#define FRAME_SECTION (1)
#define TILES_SECTION (2)

@implementation FrameStatisticsController

- (FrameStatisticsController*) initWithView:(WorldWindView*)wwv
{
    self = [super initWithStyle:UITableViewStyleGrouped];

    _wwv = wwv;

    timer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(handleTimer) userInfo:nil
                                            repeats:YES];

    return self;
}

- (void) dealloc
{
    if (drawContinuously)
    {
        drawContinuously = NO;
        [WorldWindView stopRedrawing];
    }
}

- (NSInteger) numberOfSectionsInTableView:(UITableView*)tableView
{
    return 3;
}

- (NSInteger) tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == SETTINGS_SECTION)
        return 1;
    if (section == FRAME_SECTION)
        return 2;
    else if (section == TILES_SECTION)
        return 3;
    else
        return 0;
}

- (NSString*) tableView:(UITableView*)tableView titleForHeaderInSection:(NSInteger)section
{
    if (section == SETTINGS_SECTION)
        return @"Settings";
    if (section == FRAME_SECTION)
        return @"Frame";
    else if (section == TILES_SECTION)
        return @"Tiles";
    else
        return nil;
}

- (UITableViewCell*) tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
    static NSString* cellID = @"cellForItemDisplay";

    UITableViewCell* cell = nil;

    if ([indexPath section] == SETTINGS_SECTION)
    {
        static NSString* switchCell = @"switchCellForRunContinuously";

        cell = [tableView dequeueReusableCellWithIdentifier:switchCell];
        if (cell == nil)
        {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:switchCell];

            UISwitch* enableSwitch = [[UISwitch alloc] init];
            [enableSwitch addTarget:self action:@selector(handleDrawContinuouslySwitch:)
                   forControlEvents:UIControlEventValueChanged];
            [cell setAccessoryView:enableSwitch];
            [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
            [[cell textLabel] setText:@"Draw Continuously"];
            [[cell textLabel] setFont:[UIFont systemFontOfSize:[UIFont smallSystemFontSize]]];
        }
    }
    else if ([indexPath section] == FRAME_SECTION)
    {
        cell = [tableView dequeueReusableCellWithIdentifier:cellID];
        if (cell == nil)
        {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue2 reuseIdentifier:cellID];
        }

        WWFrameStatistics* frameStats = [_wwv frameStatistics];
        NSString* name = nil;
        NSString* value = nil;

        switch ([indexPath row])
        {
            case 0:
                name = @"Avg Time";
                value = [[NSString alloc] initWithFormat:@"%d ms", (int) round(1000 * [frameStats frameTimeAverage])];
                break;

            case 1:
                name = @"Rate";
                value = [[NSString alloc] initWithFormat:@"%d Hz", (int) round([frameStats frameRateAverage])];
                break;

            default:
                break;
        }

        [[cell textLabel] setText:name];
        [[cell detailTextLabel] setText:value];

    }
    else if ([indexPath section] == TILES_SECTION)
    {
        cell = [tableView dequeueReusableCellWithIdentifier:cellID];
        if (cell == nil)
        {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue2 reuseIdentifier:cellID];
        }

        WWFrameStatistics* frameStats = [_wwv frameStatistics];
        NSString* name = nil;
        NSString* value = nil;

        switch ([indexPath row])
        {
            case 0:
                name = @"Image";
                value = [[NSString alloc] initWithFormat:@"%d", [frameStats imageTileCount]];
                break;

            case 1:
                name = @"Terrain";
                value = [[NSString alloc] initWithFormat:@"%d", [frameStats terrainTileCount]];
                break;

            case 2:
                name = @"Rendered";
                value = [[NSString alloc] initWithFormat:@"%d", [frameStats renderedTileCount]];
                break;

            default:
                break;
        }

        [[cell textLabel] setText:name];
        [[cell detailTextLabel] setText:value];

    }

    return cell;
}

- (void) handleTimer
{
    [[self tableView] reloadData];
}

- (void) handleDrawContinuouslySwitch:(UISwitch*)enableSwitch
{
    drawContinuously = [enableSwitch isOn];
    if (drawContinuously)
    {
        [WorldWindView startRedrawing];
    }
    else
    {
        [WorldWindView stopRedrawing];
    }
}

@end