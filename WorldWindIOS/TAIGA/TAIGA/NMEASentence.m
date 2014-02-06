/*
 Copyright (C) 2014 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import "NMEASentence.h"

@implementation NMEASentence
{
    NSArray* splitSentence;
    NSMutableDictionary* fields;
}

- (NMEASentence*) initWithString:(NSString*)sentence
{
    if (sentence == nil)
        return nil;

    if (![sentence hasPrefix:@"$"])
        return nil;

    self = [super init];

    _sentence = sentence;
    splitSentence = [_sentence componentsSeparatedByCharactersInSet:
            [NSCharacterSet characterSetWithCharactersInString:@",*"]];

    if (![self checksumValid])
        return nil;

    [self parseSentence];

    return self;
}

- (id) fieldWithName:(NSString*)fieldName
{
    return fieldName != nil ? [fields objectForKey:fieldName] : nil;
}

- (void) parseSentence
{
    fields = [[NSMutableDictionary alloc] init];

    if ([[splitSentence objectAtIndex:0] hasSuffix:NMEA_SENTENCE_TYPE_GPGGA])
    {
        [self parseGPGGA];
    }
    else if ([[splitSentence objectAtIndex:0] hasSuffix:NMEA_SENTENCE_TYPE_GPGSA])
    {
        [self parseGPGSA];
    }
    else if ([[splitSentence objectAtIndex:0] hasSuffix:NMEA_SENTENCE_TYPE_GPGSV])
    {
        [self parseGPGSV];
    }
    else if ([[splitSentence objectAtIndex:0] hasSuffix:NMEA_SENTENCE_TYPE_GPRMC])
    {
        [self parseGPRMC];
    }
}

- (void) parseGPGGA
{
    [fields setObject:NMEA_SENTENCE_TYPE_GPGGA forKey:NMEA_FIELD_MESSAGE_TYPE];

    NSString* tempString;

    for (NSUInteger i = 0; i < [splitSentence count]; i++)
    {
        NSString* token = [splitSentence objectAtIndex:i];
        if (token == nil || [token length] == 0)
            continue;

        switch (i)
        {
            case 1:
                [fields setObject:token forKey:NMEA_FIELD_FIX_TIME];
                break;

            case 2:
                tempString = token; // delay parsing until we know the hemisphere
                break;

            case 3:
                // Convert tempString to latitude and determine its sign/hemisphere by this field
                [fields setObject:[self parseAngle:tempString hemisphere:token] forKey:NMEA_FIELD_LATITUDE];
                break;

            case 4:
                tempString = token; // delay parsing until we know the hemisphere
                break;

            case 5:
                // Convert tempString to longitude and determine its sign/hemisphere by this field
                [fields setObject:[self parseAngle:tempString hemisphere:token] forKey:NMEA_FIELD_LONGITUDE];
                break;

            case 6:
                [fields setObject:token forKey:NMEA_FIELD_FIX_QUALITY];
                break;

            case 7:
                [fields setObject:token forKey:NMEA_FIELD_NUM_SATELLITES_TRACKED];
                break;

            case 8:
                [fields setObject:token forKey:NMEA_FIELD_HORIZONTAL_DILUTION_OF_PRECISION];
                break;

            case 9:
                [fields setObject:token forKey:NMEA_FIELD_ALTITUDE];
                break;

            case 10:
                // Skip it since it should just be the letter "M" for meters altitude
                break;

            case 11:
                [fields setObject:token forKey:NMEA_FIELD_GEOID_HEIGHT];
                break;

            case 12:
                // Skip it since it should just be the letter "M" for meters geoid height
                break;

            case 13:
                [fields setObject:token forKey:NMEA_FIELD_DGPS_UPDATE_TIME];
                break;

            case 14:
                [fields setObject:token forKey:NMEA_FIELD_DGPS_STATION_ID];
                break;

            default:
                continue;
        }
    }
}

- (void) parseGPGSA
{
    [fields setObject:NMEA_SENTENCE_TYPE_GPGSA forKey:NMEA_FIELD_MESSAGE_TYPE];

    NSMutableArray* satellitePRNs = [[NSMutableArray alloc] initWithCapacity:5];

    for (NSUInteger i = 0; i < [splitSentence count]; i++)
    {
        NSString* token = [splitSentence objectAtIndex:i];
        if (token == nil || [token length] == 0)
            continue;

        switch (i)
        {
            case 1:
                [fields setObject:token forKey:NMEA_FIELD_AUTO_SELECTION];
                break;

            case 2:
                [fields setObject:token forKey:NMEA_FIELD_3D_FIX];
                break;

            case 3:
            case 4:
            case 5:
            case 6:
            case 7:
            case 8:
            case 9:
            case 10:
            case 11:
            case 12:
            case 13:
            case 14:
                [satellitePRNs addObject:token];
                break;

            case 15:
                [fields setObject:token forKey:NMEA_FIELD_DILUTION_OF_PRECISION];
                break;

            case 16:
                [fields setObject:token forKey:NMEA_FIELD_HORIZONTAL_DILUTION_OF_PRECISION];
                break;

            case 17:
                [fields setObject:token forKey:NMEA_FIELD_VERTICAL_DILUTION_OF_PRECISION];
                break;

            default:
                continue;
        }
    }

    if ([satellitePRNs count] > 0)
    {
        [fields setObject:satellitePRNs forKey:NMEA_FIELD_TRACKED_SATELLITE_PRNS];
    }
}

- (void) parseGPGSV
{
    [fields setObject:NMEA_SENTENCE_TYPE_GPGSV forKey:NMEA_FIELD_MESSAGE_TYPE];

    NSMutableArray* satelliteInfos = [[NSMutableArray alloc] initWithCapacity:4];
    NSMutableDictionary* currentSatelliteInfo;

    for (NSUInteger i = 0; i < [splitSentence count]; i++)
    {
        NSString* token = [splitSentence objectAtIndex:i];
        if (token == nil || [token length] == 0)
            continue;

        switch (i)
        {
            case 1:
                [fields setObject:token forKey:NMEA_FIELD_NUMBER_OF_SENTENCES];
                break;

            case 2:
                [fields setObject:token forKey:NMEA_FIELD_SENTENCE_NUMBER];
                break;

            case 3:
                [fields setObject:token forKey:NMEA_FIELD_NUMBER_OF_SATELLITES_IN_VIEW];
                break;

            case 4:
            case 8:
            case 12:
            case 16:
                currentSatelliteInfo = [[NSMutableDictionary alloc] initWithCapacity:4];
                [satelliteInfos addObject:currentSatelliteInfo];
                [currentSatelliteInfo setObject:token forKey:NMEA_FIELD_SATELLITE_PRN];
                break;

            case 5:
            case 9:
            case 13:
            case 17:
                [currentSatelliteInfo setObject:token forKey:NMEA_FIELD_SATELLITE_ELEVATION];
                break;

            case 6:
            case 10:
            case 14:
            case 18:
                [currentSatelliteInfo setObject:token forKey:NMEA_FIELD_SATELLITE_AZIMUTH];
                break;

            case 7:
            case 11:
            case 15:
            case 19:
                [currentSatelliteInfo setObject:token forKey:NMEA_FIELD_SATELLITE_SIGNAL_TO_NOISE_RATIO];
                break;

            default:
                continue;
        }
    }

    if ([satelliteInfos count] > 0)
    {
        [fields setObject:satelliteInfos forKey:NMEA_FIELD_SATELLITE_INFO];
    }
}

- (void) parseGPRMC
{
    [fields setObject:NMEA_SENTENCE_TYPE_GPRMC forKey:NMEA_FIELD_MESSAGE_TYPE];

    NSString* tempString;

    for (NSUInteger i = 0; i < [splitSentence count]; i++)
    {
        NSString* token = [splitSentence objectAtIndex:i];
        if (token == nil || [token length] == 0)
            continue;

        switch (i)
        {
            case 1:
                [fields setObject:token forKey:NMEA_FIELD_FIX_TIME];
                break;

            case 2:
                [fields setObject:token forKey:NMEA_FIELD_STATUS];
                break;

            case 3:
                tempString = token; // delay parsing until we know the hemisphere
                break;

            case 4:
                // Convert tempString to latitude and determine its sign/hemisphere by this field
                [fields setObject:[self parseAngle:tempString hemisphere:token] forKey:NMEA_FIELD_LATITUDE];
                break;

            case 5:
                tempString = token; // delay parsing until we know the hemisphere
                break;

            case 6:
                // Convert tempString to longitude and determine its sign/hemisphere by this field
                [fields setObject:[self parseAngle:tempString hemisphere:token] forKey:NMEA_FIELD_LONGITUDE];
                break;

            case 7:
                [fields setObject:token forKey:NMEA_FIELD_SPEED_OVER_GROUND];
                break;

            case 8:
                [fields setObject:token forKey:NMEA_FIELD_TRACK_ANGLE];
                break;

            case 9:
                [fields setObject:token forKey:NMEA_FIELD_DATE];
                break;

            case 10:
                [fields setObject:token forKey:NMEA_FIELD_MAGNETIC_VARIATION_VALUE];
                break;

            case 11:
                [fields setObject:token forKey:NMEA_FIELD_MAGNETIC_VARIATION_DIRECTION];
                break;

            case 12:
                [fields setObject:token forKey:NMEA_FIELD_FIX_TYPE];
                break;

            default:
                continue;
        }
    }
}

- (NSNumber*) parseAngle:(NSString*)angleString hemisphere:(NSString* )hemisphere
{
    NSUInteger angleDividerIndex;
    NSInteger multiplier;

    if ([hemisphere hasPrefix:@"N"])
    {
        angleDividerIndex = 2;
        multiplier = 1;
    }
    else if ([hemisphere hasPrefix:@"S"])
    {
        angleDividerIndex = 2;
        multiplier = -1;
    }
    else if ([hemisphere hasPrefix:@"E"])
    {
        angleDividerIndex = 3;
        multiplier = 1;
    }
    else if ([hemisphere hasPrefix:@"W"])
    {
        angleDividerIndex = 3;
        multiplier = -1;
    }
    else
    {
        return nil;
    }

    NSString* degrees = [angleString substringToIndex:angleDividerIndex];
    NSString* minutes = [angleString substringFromIndex:angleDividerIndex];
    NSNumber* angle = [[NSNumber alloc] initWithFloat:multiplier * ([degrees intValue] + [minutes floatValue] / 60)];

    return angle;
}

- (BOOL) checksumValid
{
    unsigned checksum;

    if ([_sentence rangeOfString:@"*"].location == NSNotFound)
        return YES; // no checksum, so assume validity

    NSScanner* scanner = [NSScanner scannerWithString:[splitSentence objectAtIndex:[splitSentence count] - 1]];
    [scanner scanHexInt:&checksum];

    unsigned sum = 0;

    for (NSUInteger i = 0; i < [_sentence length]; i++)
    {
        unsigned asciiCode = [_sentence characterAtIndex:i];

        if (asciiCode == '$')
            continue;

        if (asciiCode == '*')
            break;

        sum ^= [_sentence characterAtIndex:i];
    }

    return sum == checksum;
}

@end