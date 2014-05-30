/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.

 @version $Id$
 */

#import "SUADataViewController.h"
#import "TAIGA.h"
#import "UnitsFormatter.h"

@implementation SUADataViewController
{
    NSMutableArray* names;
    NSMutableArray* values;
    NSArray* displayFields;
}

- (SUADataViewController*) init
{
    self = [super initWithStyle:UITableViewStyleGrouped];

    CGSize size = CGSizeMake(320, 320);
    [self setPreferredContentSize:size];

    [[self tableView] setSeparatorStyle:UITableViewCellSeparatorStyleNone];
    [[self tableView] setContentInset: UIEdgeInsetsMake(-26, 0, 0, 0)]; // eliminate empty space at top of table

    names = [[NSMutableArray alloc] init];
    values = [[NSMutableArray alloc] init];
    displayFields = @[
        @"TYPE",
        @"ICAO",
        @"SUAS_IDENT",
        @"CON_ACGY",
        @"EFF_DATE",
        @"EFF_TIMES",
        @"LEVEL",
        @"WX",
        @"COMM_NAME",
        @"FREQ1",
        @"FREQ2",
        @"CYCLE_DATE"
    ];

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

- (NSInteger) tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section
{
    return [names count];
}

- (NSString*) tableView:(UITableView*)tableView titleForHeaderInSection:(NSInteger)section
{
    return [_entries objectForKey:@"NAME"];
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

    id lowerAlt = [_entries objectForKey:@"LOWER_ALT"];
    id upperAlt = [_entries objectForKey:@"UPPER_ALT"];
    if (lowerAlt != nil && upperAlt != nil)
    {
        [names addObject:@"Altitudes"];
        [values addObject:[NSString stringWithFormat:@"%@ - %@", [self formatAltitude:lowerAlt], [self formatAltitude:upperAlt]]];
    }

    for (id key in displayFields)
    {
        if ([@"CYCLE_DATE" isEqualToString:key]) // DAFIF field #059
        {
            id obj = [_entries objectForKey:key];
            if (obj != nil)
            {
                [names addObject:@"Revised On"];
                [values addObject:obj];
            }
        }
        else if ([@"COMM_NAME" isEqualToString:key]) // DAFIF field #073
        {
            id obj = [_entries objectForKey:key];
            if (obj != nil)
            {
                [names addObject:@"Comm Name"];
                [values addObject:obj];
            }
        }
        else if ([@"FREQ1" isEqualToString:key]) // DAFIF field #075
        {
            id obj = [_entries objectForKey:key];
            if (obj != nil)
            {
                [names addObject:@"Freq 1"];
                [values addObject:obj];
            }
        }
        else if ([@"FREQ2" isEqualToString:key]) // DAFIF field #075
        {
            id obj = [_entries objectForKey:key];
            if (obj != nil)
            {
                [names addObject:@"Freq 2"];
                [values addObject:obj];
            }
        }
        else if ([@"CON_AGCY" isEqualToString:key]) // DAFIF field #078
        {
            id obj = [_entries objectForKey:key];
            if (obj != nil)
            {
                [names addObject:@"Controlling Agency"];
                [values addObject:obj];
            }
        }
        else if ([@"EFF_DATE" isEqualToString:key]) // DAFIF field #104
        {
            id obj = [_entries objectForKey:key];
            if (obj != nil)
            {
                [names addObject:@"Eff Date"];
                [values addObject:obj];
            }
        }
        else if ([@"ICAO" isEqualToString:key]) // DAFIF field #146
        {
            id obj = [_entries objectForKey:key];
            if (obj != nil)
            {
                [names addObject:key];
                [values addObject:obj];
            }
        }
        else if ([@"LEVEL" isEqualToString:key]) // DAFIF field #164
        {
            id obj = [_entries objectForKey:key];
            if (obj != nil)
            {
                [names addObject:@"Level"];
                [values addObject:[self formatLevel:obj]];
            }
        }
        else if ([@"TYPE" isEqualToString:key]) // DAFIF field #293
        {
            id obj = [_entries objectForKey:key];
            if (obj != nil)
            {
                [names addObject:@"Type"];
                [values addObject:[self formatType:obj]];
            }
        }
        else if ([@"EFF_TIMES" isEqualToString:key]) // DAFIF field #302
        {
            id obj = [_entries objectForKey:key];
            if (obj != nil)
            {
                [names addObject:@"Eff Times"];
                [values addObject:obj];
            }
        }
        else if ([@"SUAS_IDENT" isEqualToString:key]) // DAFIF field #303
        {
            id obj = [_entries objectForKey:key];
            if (obj != nil)
            {
                [names addObject:@"Identification"];
                [values addObject:obj];
            }
        }
        else if ([@"WX" isEqualToString:key]) // DAFIF field #344
        {
            id obj = [_entries objectForKey:key];
            if (obj != nil)
            {
                [names addObject:@"Weather Uses"];
                [values addObject:obj];
            }
        }
    }
}

- (NSString*) formatAltitude:(id)altitudeString
{
    NSRange range;

    if ([altitudeString isEqualToString:@"UNLTD"])
    {
        return @"Unlimited";
    }
    else if ((range = [altitudeString rangeOfString:@"AMSL"]).location != NSNotFound) // 000AMSL
    {
        double altitude = [[altitudeString substringToIndex:range.location] doubleValue];
        return [NSString stringWithFormat:@"%@ MSL", [[TAIGA unitsFormatter] formatFeetAltitude:altitude]];
    }
    else if ((range = [altitudeString rangeOfString:@"AGL"]).location != NSNotFound) // 000AGL
    {
        double altitude = [[altitudeString substringToIndex:range.location] doubleValue];
        return [NSString stringWithFormat:@"%@ AGL", [[TAIGA unitsFormatter] formatFeetAltitude:altitude]];
    }
    else if ((range = [altitudeString rangeOfString:@"FL"]).location != NSNotFound) // FL000
    {
        return [altitudeString stringByReplacingOccurrencesOfString:@"FL" withString:@"FL "];
    }
    else if ([altitudeString isEqualToString:@"SURFACE"] || [altitudeString isEqualToString:@"GND"])
    {
        return @"Surface";
    }
    else
    {
        return altitudeString;
    }
}

- (NSString*) formatLevel:(id)levelString
{
    NSDictionary* map = @{
        @"B":@"High and Low Level",
        @"H":@"High Level",
        @"L":@"Low Level"
    };

    return [map objectForKey:levelString];
}

- (NSString*) formatType:(id)typeString
{
    NSDictionary* map = @{
        @"A":@"Alert",
        @"D":@"Danger",
        @"M":@"Military Operations Area",
        @"P":@"Prohibited",
        @"R":@"Restricted",
        @"S":@"Special Rules Airspace",
        @"T":@"Temporary Reserved Airspace",
        @"W":@"Warning"
    };

    return [map objectForKey:typeString];
}

@end