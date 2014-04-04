/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.

 @version $Id$
 */

#import "UnitsFormatter.h"
#import "AppConstants.h"

@implementation UnitsFormatter

- (id)init
{
    self = [super init];

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
    [altitudeFormatter setPositiveSuffix:@"\u2032 MSL"];
    [altitudeFormatter setNegativeSuffix:@"\u2032 MSL"];

    return self;
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
    [ms appendString:@" "];
    [ms appendString:[longitudeFormatter stringFromNumber:[NSNumber numberWithDouble:longitude]]];

    return ms;
}

- (NSString*) formatMetersAltitude:(double)altitude
{
    return [altitudeFormatter stringFromNumber:[NSNumber numberWithDouble:altitude * TAIGA_METERS_TO_FEET]];
}

- (NSString*) formatFeetAltitude:(double)altitude
{
    return [altitudeFormatter stringFromNumber:[NSNumber numberWithDouble:altitude]];
}

@end