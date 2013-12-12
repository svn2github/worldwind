/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import "PIREPDataViewController.h"
#import "BRScrollBarController.h"

static NSArray* TAIGA_PIREP_DISPLAY_FIELDS;

@implementation PIREPDataViewController
{
    NSMutableArray* names;
    NSMutableArray* values;
    BRScrollBarController* scrollBar;
}

+ (void) initialize
{
// See http://adds.rap.ucar.edu/tools/dataservices/textdataserver/dataproducts/view/product/aircraftreports/section/fields
// for AircraftReport field descriptions.

    // The order here determines the order in which the fields are displayed in the table.
    TAIGA_PIREP_DISPLAY_FIELDS = [NSArray arrayWithObjects:
            @"receipt_time",
            @"observation_time",
            @"aircraft_ref",
            @"latitude",
            @"longitude",
            @"altitude_ft_msl",
            @"sky_condition",
            @"turbulence_condition",
            @"icing_condition",
            @"visibility_statute_mi",
            @"wx_string",
            @"temp_c",
            @"wind_dir_degrees",
            @"wind_speed_kt",
            @"vert_gust_kt",
            @"report_type",
            nil
    ];
}

- (PIREPDataViewController*) init
{
    self = [super initWithStyle:UITableViewStyleGrouped];

    CGSize size = CGSizeMake(320, 380);
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

    [[self tableView] flashScrollIndicators];

    scrollBar = [[BRScrollBarController alloc] initForScrollView:[self tableView]
                                                      inPosition:kIntBRScrollBarPositionRight];
    scrollBar.scrollBar.hideScrollBar = NO;
    scrollBar.scrollBar.showLabel = NO;
}

- (void) setEntries:(NSDictionary*)entries
{
    _entries = entries;
    [self initializeNamesAndValues];
    [[self tableView] reloadData];
}

- (NSInteger) numberOfSectionsInTableView:(UITableView*)tableView
{
    return 1;
}

- (NSInteger) tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section
{
    return [names count];
}

- (NSString*) tableView:(UITableView*)tableView titleForHeaderInSection:(NSInteger)section
{
    return [[_entries objectForKey:@"raw_text"] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
}

- (CGFloat) tableView:(UITableView*)tableView heightForRowAtIndexPath:(NSIndexPath*)indexPath
{
    return 28;
}

- (UITableViewCell*) tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
    static NSString* cellIdentifier = @"cell";

    UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (cell == nil)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue2 reuseIdentifier:cellIdentifier];
        [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
        [[cell detailTextLabel] setText:@""];
    }

    [[cell textLabel] setText:[names objectAtIndex:(NSUInteger) [indexPath row]]];
    [[cell detailTextLabel] setText:[values objectAtIndex:(NSUInteger) [indexPath row]]];

    return cell;
}

- (void) initializeNamesAndValues
{
    [names removeAllObjects];
    [values removeAllObjects];

    for (NSUInteger i = 0; i < [TAIGA_PIREP_DISPLAY_FIELDS count]; i++)
    {
        NSString* field = [TAIGA_PIREP_DISPLAY_FIELDS objectAtIndex:i];

        if ([field isEqualToString:@"receipt_time"])
        {
            NSString* entry = [_entries objectForKey:@"receipt_time"];
            if (entry == nil)
                continue;

            [names addObject:@"Received"];
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
        else if ([field isEqualToString:@"aircraft_ref"])
        {
            NSString* entry = [_entries objectForKey:@"aircraft_ref"];
            if (entry == nil)
                continue;

            [names addObject:@"Aircraft"];
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
        else if ([field isEqualToString:@"altitude_ft_msl"])
        {
            NSString* entry = [_entries objectForKey:@"altitude_ft_msl"];
            if (entry == nil)
                continue;

            [names addObject:@"Altitude"];
            [values addObject:[[NSString alloc] initWithFormat:@"%@ ft MSL", entry]];
        }
        else if ([field isEqualToString:@"visibility_statute_mi"])
        {
            NSString* entry = [_entries objectForKey:@"visibility_statute_mi"];
            if (entry == nil)
                continue;

            [names addObject:@"Visibility"];
            [values addObject:[[NSString alloc] initWithFormat:@"%@ st mi", entry]];
        }
        else if ([field isEqualToString:@"wx_string"])
        {
            NSString* entry = [_entries objectForKey:@"wx_string"];
            if (entry == nil)
                continue;

            [names addObject:@"WX String"];
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
        else if ([field isEqualToString:@"wind_dir_degrees"])
        {
            NSString* entry = [_entries objectForKey:@"wind_dir_degrees"];
            if (entry == nil)
                continue;

            [names addObject:@"Wind Direction"];
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
        else if ([field isEqualToString:@"vert_gust_kt"])
        {
            NSString* entry = [_entries objectForKey:@"vert_gust_kt"];
            if (entry == nil)
                continue;

            [names addObject:@"Vertical Gust"];
            [values addObject:[[NSString alloc] initWithFormat:@"%@ kt", entry]];
        }
        else if ([field isEqualToString:@"report_type"])
        {
            NSString* entry = [_entries objectForKey:@"report_type"];
            if (entry == nil)
                continue;

            [names addObject:@"Type"];
            [values addObject:entry];
        }
        else if ([field isEqualToString:@"sky_condition"])
        {
            NSArray* conditions = [_entries objectForKey:@"sky_condition"];
            if (conditions == nil)
                continue;

            for (NSDictionary* condition in conditions)
            {
                NSString* entry = [condition objectForKey:@"sky_cover"];
                if (entry != nil)
                {
                    [names addObject:@"Sky Cover"];
                    [values addObject:entry];
                }

                entry = [condition objectForKey:@"cloud_base_ft_msl"];
                if (entry != nil)
                {
                    [names addObject:@"Cloud Base"];
                    [values addObject:[[NSString alloc] initWithFormat:@"%@ ft MSL", entry]];
                }

                entry = [condition objectForKey:@"cloud_top_ft_msl"];
                if (entry != nil)
                {
                    [names addObject:@"Cloud Top"];
                    [values addObject:[[NSString alloc] initWithFormat:@"%@ ft MSL", entry]];
                }
            }
        }
        else if ([field isEqualToString:@"turbulence_condition"])
        {
            NSArray* conditions = [_entries objectForKey:@"turbulence_condition"];
            if (conditions == nil)
                continue;

            for (NSDictionary* condition in conditions)
            {
                NSString* entry = [condition objectForKey:@"turbulence_type"];
                if (entry != nil)
                {
                    [names addObject:@"Turb Type"];
                    [values addObject:entry];
                }

                entry = [condition objectForKey:@"turbulence_intensity"];
                if (entry != nil)
                {
                    [names addObject:@"Turb Intensity"];
                    [values addObject:entry];
                }

                entry = [condition objectForKey:@"turbulence_base_ft_msl"];
                if (entry != nil)
                {
                    [names addObject:@"Turb Base"];
                    [values addObject:[[NSString alloc] initWithFormat:@"%@ ft MSL", entry]];
                }

                entry = [condition objectForKey:@"turbulence_top_ft_msl"];
                if (entry != nil)
                {
                    [names addObject:@"Turb Top"];
                    [values addObject:[[NSString alloc] initWithFormat:@"%@ ft MSL", entry]];
                }

                entry = [condition objectForKey:@"turbulence_freq"];
                if (entry != nil)
                {
                    [names addObject:@"Turbulence Frequency"];
                    [values addObject:entry];
                }
            }
        }
        else if ([field isEqualToString:@"icing_condition"])
        {
            NSArray* conditions = [_entries objectForKey:@"icing_condition"];
            if (conditions == nil)
                continue;

            for (NSDictionary* condition in conditions)
            {
                NSString* entry = [condition objectForKey:@"icing_type"];
                if (entry != nil)
                {
                    [names addObject:@"Icing Type"];
                    [values addObject:entry];
                }

                entry = [condition objectForKey:@"icing_intensity"];
                if (entry != nil)
                {
                    [names addObject:@"Icing Intensity"];
                    [values addObject:entry];
                }

                entry = [condition objectForKey:@"icing_base_ft_msl"];
                if (entry != nil)
                {
                    [names addObject:@"Icing Base"];
                    [values addObject:[[NSString alloc] initWithFormat:@"%@ ft MSL", entry]];
                }

                entry = [condition objectForKey:@"icing_top_ft_msl"];
                if (entry != nil)
                {
                    [names addObject:@"Icing Top"];
                    [values addObject:[[NSString alloc] initWithFormat:@"%@ ft MSL", entry]];
                }
            }
        }
    }
}
@end