/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import "METARDataViewController.h"
#import "WWLog.h"
#import "BRScrollBarController.h"

static NSArray* TAIGA_METAR_DISPLAY_FIELDS;

@implementation METARDataViewController
{
    NSMutableArray* names;
    NSMutableArray* values;
}

+ (void) initialize
{
// See http://weather.aero/tools/dataservices/textdataserver/dataproducts/view/product/metars/section/fields for
// METAR field descriptions.
    TAIGA_METAR_DISPLAY_FIELDS = [NSArray arrayWithObjects:
            @"station_id",
            @"observation_time",
            @"flight_category",
            @"temp_c",
            @"dewpoint_c",
            @"wind_dir_degrees",
            @"wind_speed_kt",
            @"wind_gust_kt",
            @"visibility_statute_mi",
            @"vert_vis_ft",
            @"wx_string",
            @"maxT_c",
            @"minT_c",
            @"maxT24hr_c",
            @"minT24hr_c",
            @"precip_in",
            @"pcp3hr_in",
            @"pcp6hr_in",
            @"pcp24hr_in",
            @"snow_in",
            @"three_hr_pressure_tendency_mb",
            @"latitude",
            @"longitude",
            @"altim_in_hg",
            @"altitude_ft_msl",
            @"metar_type",
            @"elevation_m",
            nil
    ];
}

- (METARDataViewController*) init
{
    self = [super initWithStyle:UITableViewStyleGrouped];

    CGSize size = CGSizeMake(320, 320);
    [self setPreferredContentSize:size];

    [[self tableView] setSeparatorStyle:UITableViewCellSeparatorStyleNone];
    self.tableView.contentInset = UIEdgeInsetsMake(-26, 0, 0, 0); // eliminate empty space at top of table

    names = [[NSMutableArray alloc] init];
    values = [[NSMutableArray alloc] init];

    return self;
}

- (void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    [self flashScrollIndicator];
}

- (void) setEntries:(NSDictionary*)entries
{
    _entries = entries;
    [self initializeNamesAndValues];
    [[self tableView] reloadData];
}

- (void) flashScrollIndicator
{
    [[self tableView] performSelector:@selector(flashScrollIndicators) withObject:nil afterDelay:0];
}

- (NSInteger) numberOfSectionsInTableView:(UITableView*)tableView
{
    return [_entries objectForKey:@"sky_conditions"] != nil ? 2 : 1;
}

- (NSInteger) tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == 0)
    {
        return [names count];
    }
    else
    {
        NSArray* skyConditions = [_entries objectForKey:@"sky_conditions"];
        return skyConditions != nil && [skyConditions count] > 0 ? [skyConditions count] : 0;
    }
}

- (NSString*) tableView:(UITableView*)tableView titleForHeaderInSection:(NSInteger)section
{
    if (section == 0)
        return [[_entries objectForKey:@"raw_text"] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    else
        return @"Sky Conditions";
}

- (CGFloat) tableView:(UITableView*)tableView heightForRowAtIndexPath:(NSIndexPath*)indexPath
{
    return 28;
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

        if ([indexPath section] == 1)
        {
            NSArray* skyConditions = [_entries objectForKey:@"sky_conditions"];
            if (skyConditions != nil && [skyConditions count] > 0)
            {
                NSDictionary* conditionDict = [skyConditions objectAtIndex:(NSUInteger) [indexPath row]];
                NSMutableString* cover = [[NSMutableString alloc] initWithString:[conditionDict objectForKey:@"sky_cover"]];
                NSString* cloud_bases = [conditionDict objectForKey:@"cloud_base_ft_agl"];
                if (cloud_bases != nil)
                    [cover appendFormat:@" @ %@ ft AGL", cloud_bases];
                [[cell textLabel] setText:nil];
                [[cell detailTextLabel] setText:cover];
                return cell;
            }
            else
            {
                return nil;
            }
        }
        else
        {
            [[cell textLabel] setText:[names objectAtIndex:(NSUInteger) [indexPath row]]];
            [[cell detailTextLabel] setText:[values objectAtIndex:(NSUInteger) [indexPath row]]];
            return cell;
        }
    }
    @catch (NSException* exception)
    {
        WWLogE(@"Forming METAR data display", exception);
        return nil;
    }
}

- (void) initializeNamesAndValues
{
    [names removeAllObjects];
    [values removeAllObjects];

    for (NSUInteger i = 0; i < [TAIGA_METAR_DISPLAY_FIELDS count]; i++)
    {
        NSString* field = [TAIGA_METAR_DISPLAY_FIELDS objectAtIndex:i];

        if ([field isEqualToString:@"station_id"])
        {
            NSString* entry = [_entries objectForKey:@"station_id"];
            if (entry == nil)
                continue;

            [names addObject:@"Station"];
            [values addObject:entry];
        }
        else if ([field isEqualToString:@"observation_time"])
        {
            NSString* entry = [_entries objectForKey:@"observation_time"];
            if (entry == nil)
                continue;

            [names addObject:@"Observed"];
            [values addObject:entry];
        }
        else if ([field isEqualToString:@"latitude"])
        {
            NSString* entry = [_entries objectForKey:@"latitude"];
            if (entry == nil)
                continue;

            [names addObject:@"Latitude"];
            [values addObject:entry];
        }
        else if ([field isEqualToString:@"longitude"])
        {
            NSString* entry = [_entries objectForKey:@"longitude"];
            if (entry == nil)
                continue;

            [names addObject:@"Longitude"];
            [values addObject:entry];
        }
        else if ([field isEqualToString:@"temp_c"])
        {
            NSString* entry = [_entries objectForKey:@"temp_c"];
            if (entry == nil)
                continue;

            [names addObject:@"Temperature"];
            [values addObject:[[NSString alloc] initWithFormat:@"%@ C", entry]];
        }
        else if ([field isEqualToString:@"dewpoint_c"])
        {
            NSString* entry = [_entries objectForKey:@"dewpoint_c"];
            if (entry == nil)
                continue;

            [names addObject:@"Dew Point"];
            [values addObject:[[NSString alloc] initWithFormat:@"%@ C", entry]];
        }
        else if ([field isEqualToString:@"wind_dir_degrees"])
        {
            NSString* entry = [_entries objectForKey:@"wind_dir_degrees"];
            if (entry == nil)
                continue;

            [names addObject:@"Wind Dir"];
            [values addObject:[[NSString alloc] initWithFormat:@"%@ degrees", entry]];
        }
        else if ([field isEqualToString:@"wind_speed_kt"])
        {
            NSString* entry = [_entries objectForKey:@"wind_speed_kt"];
            if (entry == nil)
                continue;

            [names addObject:@"Wind Speed"];
            [values addObject:[[NSString alloc] initWithFormat:@"%@ kt", entry]];
        }
        else if ([field isEqualToString:@"wind_gust_kt"])
        {
            NSString* entry = [_entries objectForKey:@"wind_gust_kt"];
            if (entry == nil)
                continue;

            [names addObject:@"Wind Gust"];
            [values addObject:[[NSString alloc] initWithFormat:@"%@ kt", entry]];
        }
        else if ([field isEqualToString:@"visibility_statute_mi"])
        {
            NSString* entry = [_entries objectForKey:@"visibility_statute_mi"];
            if (entry == nil)
                continue;

            [names addObject:@"Visibility"];
            [values addObject:[[NSString alloc] initWithFormat:@"%@ st mi", entry]];
        }
        else if ([field isEqualToString:@"altim_in_hg"])
        {
            NSString* entry = [_entries objectForKey:@"altim_in_hg"];
            if (entry == nil)
                continue;

            [names addObject:@"Altimeter"];
            [values addObject:[[NSString alloc] initWithFormat:@"%@ hg", entry]];
        }
        else if ([field isEqualToString:@"sea_level_pressure_mb"])
        {
            NSString* entry = [_entries objectForKey:@"sea_level_pressure_mb"];
            if (entry == nil)
                continue;

            [names addObject:@"Sea Lvl Press"];
            [values addObject:[[NSString alloc] initWithFormat:@"%@ mb", entry]];
        }
        else if ([field isEqualToString:@"wx_string"])
        {
            NSString* entry = [_entries objectForKey:@"wx_string"];
            if (entry == nil)
                continue;

            [names addObject:@"Weather"];
            [values addObject:entry];
        }
        else if ([field isEqualToString:@"flight_category"])
        {
            NSString* entry = [_entries objectForKey:@"flight_category"];
            if (entry == nil)
                continue;

            [names addObject:@"Category"];
            [values addObject:entry];
        }
        else if ([field isEqualToString:@"three_hr_pressure_tendency_mb"])
        {
            NSString* entry = [_entries objectForKey:@"three_hr_pressure_tendency_mb"];
            if (entry == nil)
                continue;

            [names addObject:@"3 hr Press Chng"];
            [values addObject:[[NSString alloc] initWithFormat:@"%@ mb", entry]];
        }
        else if ([field isEqualToString:@"maxT_c"])
        {
            NSString* entry = [_entries objectForKey:@"maxT_c"];
            if (entry == nil)
                continue;

            [names addObject:@"Max 6 hr Temp"];
            [values addObject:[[NSString alloc] initWithFormat:@"%@ C", entry]];
        }
        else if ([field isEqualToString:@"minT_c"])
        {
            NSString* entry = [_entries objectForKey:@"minT_c"];
            if (entry == nil)
                continue;

            [names addObject:@"Min 6 hr Temp"];
            [values addObject:[[NSString alloc] initWithFormat:@"%@ C", entry]];
        }
        else if ([field isEqualToString:@"maxT24hr_c"])
        {
            NSString* entry = [_entries objectForKey:@"maxT24hr_c"];
            if (entry == nil)
                continue;

            [names addObject:@"Max 24 hr Temp"];
            [values addObject:[[NSString alloc] initWithFormat:@"%@ C", entry]];
        }
        else if ([field isEqualToString:@"minT24hr_c"])
        {
            NSString* entry = [_entries objectForKey:@"minT24hr_c"];
            if (entry == nil)
                continue;

            [names addObject:@"Min 24 hr Temp"];
            [values addObject:[[NSString alloc] initWithFormat:@"%@ C", entry]];
        }
        else if ([field isEqualToString:@"precip_in"])
        {
            NSString* entry = [_entries objectForKey:@"precip_in"];
            if (entry == nil)
                continue;

            [names addObject:@"Precipitation"];
            [values addObject:[[NSString alloc] initWithFormat:@"%@ in", entry]];
        }
        else if ([field isEqualToString:@"pcp3hr_in"])
        {
            NSString* entry = [_entries objectForKey:@"pcp3hr_in"];
            if (entry == nil)
                continue;

            [names addObject:@"3 hr Precip"];
            [values addObject:[[NSString alloc] initWithFormat:@"%@ in", entry]];
        }
        else if ([field isEqualToString:@"pcp6hr_in"])
        {
            NSString* entry = [_entries objectForKey:@"pcp6hr_in"];
            if (entry == nil)
                continue;

            [names addObject:@"6 hr Precip"];
            [values addObject:[[NSString alloc] initWithFormat:@"%@ in", entry]];
        }
        else if ([field isEqualToString:@"pcp24hr_in"])
        {
            NSString* entry = [_entries objectForKey:@"pcp24hr_in"];
            if (entry == nil)
                continue;

            [names addObject:@"24 hr Precip"];
            [values addObject:[[NSString alloc] initWithFormat:@"%@ in", entry]];
        }
        else if ([field isEqualToString:@"snow_in"])
        {
            NSString* entry = [_entries objectForKey:@"snow_in"];
            if (entry == nil)
                continue;

            [names addObject:@"Snow"];
            [values addObject:[[NSString alloc] initWithFormat:@"%@ in", entry]];
        }
        else if ([field isEqualToString:@"vert_vis_ft"])
        {
            NSString* entry = [_entries objectForKey:@"vert_vis_ft"];
            if (entry == nil)
                continue;

            [names addObject:@"Vertical Vis"];
            [values addObject:[[NSString alloc] initWithFormat:@"%@ ft", entry]];
        }
        else if ([field isEqualToString:@"elevation_m"])
        {
            NSString* entry = [_entries objectForKey:@"elevation_m"];
            if (entry == nil)
                continue;

            [names addObject:@"Elevation"];
            [values addObject:[[NSString alloc] initWithFormat:@"%@ m", entry]];
        }
        else if ([field isEqualToString:@"metar_type"])
        {
            NSString* entry = [_entries objectForKey:@"metar_type"];
            if (entry == nil)
                continue;

            [names addObject:@"Metar Type"];
            [values addObject:entry];
        }
    }
}

@end