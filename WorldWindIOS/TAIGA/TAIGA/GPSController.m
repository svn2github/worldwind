/*
 Copyright (C) 2014 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import <CoreLocation/CoreLocation.h>
#import "GPSController.h"
#import "WWRetriever.h"
#import "WorldWindConstants.h"
#import "NMEASentence.h"
#import "AppConstants.h"
#import "Settings.h"

#define DEFAULT_GPS_DEVICE_ADDRESS @"http://worldwind.arc.nasa.gov/alaska/gps/gps.txt"

@implementation GPSController
{
    NSTimer* timer;
    NSDateFormatter* dateFormatter;
}

+ (void) setDefaultGPSDeviceAddress
{
    [Settings setObject:DEFAULT_GPS_DEVICE_ADDRESS forName:TAIGA_GPS_DEVICE_ADDRESS];
}

- (GPSController*) init
{
    self = [super init];

    dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setTimeZone:[NSTimeZone timeZoneWithName:@"UTC"]];
    [dateFormatter setDateFormat:@"yyyy MM dd HH mm ss"];

    timer = [NSTimer scheduledTimerWithTimeInterval:5 target:self selector:@selector(pollDevice)
                                           userInfo:nil repeats:YES];

    return self;
}

- (void) dispose
{
    [timer invalidate];
    timer = nil;
    dateFormatter = nil;
}

- (void) pollDevice
{
    NSString* address = (NSString*) [Settings getObjectForName:TAIGA_GPS_DEVICE_ADDRESS];
    if (address == nil || address.length == 0)
        return;

    NSURL* url = [[NSURL alloc] initWithString:address];
    if (url == nil)
        return;

    WWRetriever* retriever = [[WWRetriever alloc] initWithUrl:url timeout:5
                                                finishedBlock:^(WWRetriever* myRetriever)
                                                {
                                                    [self processRetrieval:myRetriever];
                                                }];
    [retriever performRetrieval];
}

- (void) processRetrieval:(WWRetriever*)retriever
{
    if (![[retriever status] isEqualToString:WW_SUCCEEDED]
            || [[retriever retrievedData] length] == 0
            || [retriever httpStatusCode] != 200)
    {
        // Send a notification that the GPS fix is not available.
        [[NSNotificationCenter defaultCenter] postNotificationName:TAIGA_GPS_QUALITY object:nil];
        return;
    }

    NSString* allSentences = [[NSString alloc] initWithData:[retriever retrievedData] encoding:NSASCIIStringEncoding];

    NSMutableDictionary* unparsedSentences = [[NSMutableDictionary alloc] initWithCapacity:4];
    [allSentences enumerateLinesUsingBlock:^(NSString* line, BOOL* stop)
    {
        if (![line hasPrefix:@"$"])
            return;

        NSArray* splitSentence = [line componentsSeparatedByCharactersInSet:
                [NSCharacterSet characterSetWithCharactersInString:@","]];

        if ([splitSentence count] > 0)
            [unparsedSentences setObject:line forKey:[splitSentence objectAtIndex:0]];
    }];

    NSMutableDictionary* parsedSentences = [[NSMutableDictionary alloc] initWithCapacity:4];
    for (NSString* sentence in [unparsedSentences allValues])
    {
        NMEASentence* parsedSentence = [[NMEASentence alloc] initWithString:sentence];
        if (parsedSentence != nil)
        {
            NSString* sentenceType = [parsedSentence sentenceType];
            if (sentenceType != nil)
                [parsedSentences setObject:parsedSentence forKey:sentenceType];
        }
    }

    if (![self distributeCurrentPosition:parsedSentences])
    {
        // Send a notification that the GPS fix is not available.
        [[NSNotificationCenter defaultCenter] postNotificationName:TAIGA_GPS_QUALITY object:nil];
        return;
    }

    [self distributeSignalInfo:parsedSentences];
}

- (BOOL) distributeCurrentPosition:(NSDictionary*)mostRecentSentences
{
    NMEASentence* ggaSentence = [mostRecentSentences objectForKey:NMEA_SENTENCE_TYPE_GPGGA];
    NMEASentence* rmcSentence = [mostRecentSentences objectForKey:NMEA_SENTENCE_TYPE_GPRMC];
    if (ggaSentence == nil || rmcSentence == nil)
        return NO;

    NSNumber* latitude = [rmcSentence fieldWithName:NMEA_FIELD_LATITUDE];
    NSNumber* longitude = [rmcSentence fieldWithName:NMEA_FIELD_LONGITUDE];
    if (latitude == nil || longitude == nil)
        return NO;

    CLLocationCoordinate2D coordinate;
    coordinate.latitude = [latitude doubleValue];
    coordinate.longitude = [longitude doubleValue];

    CLLocationDistance altitude = 0;
    if ([ggaSentence fieldWithName:NMEA_FIELD_ALTITUDE] != nil)
        altitude = [[ggaSentence fieldWithName:NMEA_FIELD_ALTITUDE] doubleValue];

    CLLocationDirection course = 0;
    if ([rmcSentence fieldWithName:NMEA_FIELD_TRACK_ANGLE] != nil)
        course = [[ggaSentence fieldWithName:NMEA_FIELD_TRACK_ANGLE] doubleValue];

    CLLocationSpeed speed = 0;
    if ([rmcSentence fieldWithName:NMEA_FIELD_SPEED_OVER_GROUND] != nil)
        course = [[ggaSentence fieldWithName:NMEA_FIELD_SPEED_OVER_GROUND] doubleValue];
    course *= TAIGA_KNOTS_TO_METERS_PER_SECOND;

    NSDate* fixDate = [self dateFromRMCSentence:rmcSentence];
    if (fixDate == nil)
        fixDate = [NSDate date];

    CLLocation* location = [[CLLocation alloc] initWithCoordinate:coordinate altitude:altitude
                                               horizontalAccuracy:0 verticalAccuracy:0
                                                           course:course speed:speed
                                                        timestamp:fixDate];

    [[NSNotificationCenter defaultCenter] postNotificationName:TAIGA_CURRENT_AIRCRAFT_POSITION object:location];

    return YES;
}

- (void) distributeSignalInfo:(NSDictionary*)mostRecentSentences
{
    // Send the known GPS quality, or nil if the quality is not available.
    NMEASentence* ggaSentence = [mostRecentSentences objectForKey:NMEA_SENTENCE_TYPE_GPGGA];
    NSString* quality = ggaSentence != nil ? [ggaSentence fieldWithName:NMEA_FIELD_FIX_QUALITY] : nil;
    [[NSNotificationCenter defaultCenter] postNotificationName:TAIGA_GPS_QUALITY object:quality];
}

- (NSDate*)dateFromRMCSentence:(NMEASentence*)rmcSentence
{
    NSString* dateString = [rmcSentence fieldWithName:NMEA_FIELD_FIX_DATE];
    NSString* timeString = [rmcSentence fieldWithName:NMEA_FIELD_FIX_TIME];

    if (dateString == nil || timeString == nil)
        return nil;

    NSRange range;

    range.length = 2;
    range.location = 0;
    NSString* d = [dateString substringWithRange:range];

    range.location = 2;
    NSString* m = [dateString substringWithRange:range];

    range.location = 4;
    NSString* y = [dateString substringWithRange:range];

    range.location = 0;
    NSString* h = [timeString substringWithRange:range];

    range.location = 2;
    NSString* mm = [timeString substringWithRange:range];

    range.location = 4;
    NSString* s = [timeString substringWithRange:range];

    if (d == nil || m == nil || y == nil || h == nil || mm == nil || s == nil)
        return nil;

    NSString* dateTimeString = [[NSString alloc] initWithFormat:@"20%@ %@ %@ %@ %@ %@", y, m, d, h, mm, s];

    return [dateFormatter dateFromString:dateTimeString];
}

@end