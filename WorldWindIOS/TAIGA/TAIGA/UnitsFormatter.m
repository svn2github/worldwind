/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.

 @version $Id$
 */

#import "UnitsFormatter.h"
#import "AppConstants.h"

@implementation UnitsFormatter

- (id) init
{
    self = [super init];

    angleFormatter = [[NSNumberFormatter alloc] init];
    [angleFormatter setNumberStyle:NSNumberFormatterDecimalStyle];
    [angleFormatter setMinimumFractionDigits:2];
    [angleFormatter setMaximumFractionDigits:2];
    [angleFormatter setPositiveSuffix:@"\u00B0"];
    [angleFormatter setNegativeSuffix:@"\u00B0"];

    latitudeFormatter = [[NSNumberFormatter alloc] init];
    [latitudeFormatter setNumberStyle:NSNumberFormatterDecimalStyle];
    [latitudeFormatter setMinimumFractionDigits:2];
    [latitudeFormatter setMaximumFractionDigits:2];
    [latitudeFormatter setPositiveSuffix:@"\u00B0N"];
    [latitudeFormatter setNegativeSuffix:@"\u00B0S"];
    [latitudeFormatter setNegativePrefix:@""];

    longitudeFormatter = [[NSNumberFormatter alloc] init];
    [longitudeFormatter setNumberStyle:NSNumberFormatterDecimalStyle];
    [longitudeFormatter setMinimumFractionDigits:2];
    [longitudeFormatter setMaximumFractionDigits:2];
    [longitudeFormatter setPositiveSuffix:@"\u00B0E"];
    [longitudeFormatter setNegativeSuffix:@"\u00B0W"];
    [longitudeFormatter setNegativePrefix:@""];

    altitudeFormatter = [[NSNumberFormatter alloc] init];
    [altitudeFormatter setNumberStyle:NSNumberFormatterDecimalStyle];
    [altitudeFormatter setMaximumFractionDigits:0];
    [altitudeFormatter setPositiveSuffix:@"\u2032"];
    [altitudeFormatter setNegativeSuffix:@"\u2032"];

    speedFormatter = [[NSNumberFormatter alloc] init];
    [speedFormatter setNumberStyle:NSNumberFormatterDecimalStyle];
    [speedFormatter setMaximumFractionDigits:0];
    [speedFormatter setPositiveSuffix:@" kts"];
    [speedFormatter setNegativeSuffix:@" kts"];

    distanceFormatterFeet = [[NSNumberFormatter alloc] init];
    [distanceFormatterFeet setNumberStyle:NSNumberFormatterDecimalStyle];
    [distanceFormatterFeet setMaximumFractionDigits:0];
    [distanceFormatterFeet setPositiveSuffix:@"\u2032"];
    [distanceFormatterFeet setNegativeSuffix:@"\u2032"];

    distanceFormatterMiles = [[NSNumberFormatter alloc] init];
    [distanceFormatterMiles setNumberStyle:NSNumberFormatterDecimalStyle];
    [distanceFormatterMiles setMaximumFractionDigits:0];
    [distanceFormatterMiles setPositiveSuffix:@" nm"];
    [distanceFormatterMiles setNegativeSuffix:@" nm"];

    return self;
}

- (NSString*) formatAngle:(double)angle
{
    return [angleFormatter stringFromNumber:[NSNumber numberWithDouble:angle]];
}

- (NSString*) formatAngle2:(double)angle
{
    return [NSString stringWithFormat:@"%03d\u00B0", (int) round(angle)];
}

- (NSString*) formatDegreesLatitude:(double)latitude
{
    return [latitudeFormatter stringFromNumber:[NSNumber numberWithDouble:latitude]];
}

- (NSString*) formatDegreesLongitude:(double)longitude
{
    return [longitudeFormatter stringFromNumber:[NSNumber numberWithDouble:longitude]];
}

- (NSString*) formatDegreesLatitude:(double)latitude longitude:(double)longitude
{
    NSMutableString* ms = [[NSMutableString alloc] init];
    [ms appendString:[latitudeFormatter stringFromNumber:[NSNumber numberWithDouble:latitude]]];
    [ms appendString:@"  "];
    [ms appendString:[longitudeFormatter stringFromNumber:[NSNumber numberWithDouble:longitude]]];

    return ms;
}

- (NSString*) formatDegreesLatitude:(double)latitude longitude:(double)longitude metersAltitude:(double)altitude
{
    NSMutableString* ms = [[NSMutableString alloc] init];
    [ms appendString:[latitudeFormatter stringFromNumber:[NSNumber numberWithDouble:latitude]]];
    [ms appendString:@"  "];
    [ms appendString:[longitudeFormatter stringFromNumber:[NSNumber numberWithDouble:longitude]]];
    [ms appendString:@"  "];
    [ms appendString:[altitudeFormatter stringFromNumber:[NSNumber numberWithDouble:altitude * TAIGA_METERS_TO_FEET]]];

    return ms;
}

- (NSString*) formatMetersAltitude:(double)meters
{
    return [altitudeFormatter stringFromNumber:[NSNumber numberWithDouble:meters * TAIGA_METERS_TO_FEET]];
}

- (NSString*) formatFeetAltitude:(double)meters
{
    return [altitudeFormatter stringFromNumber:[NSNumber numberWithDouble:meters]];
}

- (NSString*) formatKnotsSpeed:(double)metersPerSecond
{
    return [speedFormatter stringFromNumber:
            [NSNumber numberWithDouble:metersPerSecond * TAIGA_METERS_TO_NAUTICAL_MILES / 3600]];
}

- (NSString*) formatFeetDistance:(double)meters
{
    return [distanceFormatterFeet stringFromNumber:[NSNumber numberWithDouble:meters * TAIGA_METERS_TO_FEET]];
}

- (NSString*) formatMilesDistance:(double)meters
{
    return [distanceFormatterMiles stringFromNumber:[NSNumber numberWithDouble:meters *
            TAIGA_METERS_TO_NAUTICAL_MILES]];
}

@end