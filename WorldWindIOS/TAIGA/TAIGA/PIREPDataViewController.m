/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import "PIREPDataViewController.h"
#import "TAIGA.h"
#import "UnitsFormatter.h"

static NSArray* TAIGA_PIREP_DISPLAY_FIELDS;

@implementation PIREPDataViewController
{
    NSMutableArray* names;
    NSMutableArray* values;
    NSDateFormatter* dateFormatter;
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

    dateFormatter = [[NSDateFormatter alloc] init];
    NSLocale *enUSPOSIXLocale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
    [dateFormatter setLocale:enUSPOSIXLocale];
    [dateFormatter setDateFormat:@"yyyy'-'MM'-'dd'T'HH':'mm':'ss'Z'"];
    [dateFormatter setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];

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

- (void) tableView:(UITableView*)tableView willDisplayHeaderView:(UIView*)view forSection:(NSInteger)section
{
    UITableViewHeaderFooterView * headerView = (UITableViewHeaderFooterView *)view;

    UIColor* headerColor = [UIColor clearColor];
    UIColor* textColor = headerView.textLabel.textColor;

    for (NSUInteger i = 0; i < names.count; i++)
    {
        if ([((NSString*) [names objectAtIndex:i]) hasPrefix:@"Observed"])
        {
            NSString* dateString = [values objectAtIndex:i];
            NSDate* observationDate = [dateFormatter dateFromString:dateString];
            if (observationDate.timeIntervalSinceNow < -7200)
            {
                headerColor = [UIColor redColor];
                textColor = [UIColor whiteColor];
            }
            else if (observationDate.timeIntervalSinceNow < -3600)
            {
                headerColor = [UIColor yellowColor];
            }

            break;
        }
    }

    headerView.contentView.backgroundColor = headerColor;
    headerView.textLabel.textColor = textColor;
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
            [values addObject:[[TAIGA unitsFormatter] formatDegreesLatitude:[entry doubleValue]]];
        }
        else if ([field isEqualToString:@"longitude"])
        {
            NSString* entry = [_entries objectForKey:@"longitude"];
            if (entry == nil)
                continue;

            [names addObject:@"Longitude"];
            [values addObject:[[TAIGA unitsFormatter] formatDegreesLongitude:[entry doubleValue]]];
        }
        else if ([field isEqualToString:@"altitude_ft_msl"])
        {
            NSString* entry = [_entries objectForKey:@"altitude_ft_msl"];
            if (entry == nil)
                continue;

            [names addObject:@"Altitude"];
            [values addObject:[[TAIGA unitsFormatter] formatFeetAltitude:[entry doubleValue]]];
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
                    [values addObject:[[TAIGA unitsFormatter] formatFeetAltitude:[entry doubleValue]]];
                }

                entry = [condition objectForKey:@"cloud_top_ft_msl"];
                if (entry != nil)
                {
                    [names addObject:@"Cloud Top"];
                    [values addObject:[[TAIGA unitsFormatter] formatFeetAltitude:[entry doubleValue]]];
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
                    [values addObject:[[TAIGA unitsFormatter] formatFeetAltitude:[entry doubleValue]]];
                }

                entry = [condition objectForKey:@"turbulence_top_ft_msl"];
                if (entry != nil)
                {
                    [names addObject:@"Turb Top"];
                    [values addObject:[[TAIGA unitsFormatter] formatFeetAltitude:[entry doubleValue]]];
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
                    [values addObject:[[TAIGA unitsFormatter] formatFeetAltitude:[entry doubleValue]]];
                }

                entry = [condition objectForKey:@"icing_top_ft_msl"];
                if (entry != nil)
                {
                    [names addObject:@"Icing Top"];
                    [values addObject:[[TAIGA unitsFormatter] formatFeetAltitude:[entry doubleValue]]];
                }
            }
        }
    }
}
@end