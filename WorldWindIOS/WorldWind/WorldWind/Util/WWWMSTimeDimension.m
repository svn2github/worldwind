/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import "WWWMSTimeDimension.h"
#import "WWLog.h"

#define RESOLUTION_YEAR (1)
#define RESOLUTION_MONTH (2)
#define RESOLUTION_DAY (3)
#define RESOLUTION_HOUR (4)
#define RESOLUTION_MINUTE (5)
#define RESOLUTION_SECOND (6)

// Internal class representing a time period per the WMS spec.
@interface Period : NSObject
{
    int resolution; // indicates the degree of date and time specification -- year, month, day, hour, etc.
}

@property(nonatomic, readonly) int years;
@property(nonatomic, readonly) int months;
@property(nonatomic, readonly) int days;
@property(nonatomic, readonly) int hours;
@property(nonatomic, readonly) int minutes;
@property(nonatomic, readonly) int seconds;
@end

@implementation Period

- (Period*) initWithPeriodString:(NSString*)periodString
{
    self = [super init];

    BOOL timeSpec = NO;
    NSArray* tokens = [self tokenizePeriodString:periodString];

    for (NSUInteger i = 0; i < [tokens count]; i++)
    {
        NSString* token = [tokens objectAtIndex:i];

        if ([token isEqualToString:@"T"])
        {
            timeSpec = YES; // the period contains a time element (as opposed to just date elements -- y, m, d)
            continue;
        }

        NSInteger value = [token integerValue];

        if (i < [tokens count] - 1)
        {
            NSString* delimiter = [tokens objectAtIndex:i + 1];
            switch ([delimiter characterAtIndex:0])
            {
                case 'Y':
                    _years = value;
                    resolution = 1;
                    break;
                case 'D':
                    _days = value;
                    resolution = 3;
                    break;
                case 'H':
                    if (timeSpec)
                    {
                        _hours = value;
                        resolution = 4;
                    }
                    break;
                case 'S':
                    if (timeSpec)
                    {
                        _seconds = value;
                        resolution = 6;
                    }
                    break;
                case 'M':
                {
                    if (timeSpec)
                    {
                        _minutes = value;
                        resolution = 5;
                    }
                    else
                    {
                        _months = value;
                        resolution = 2;
                    }
                    break;
                }
                default:
                    break;
            }
        }
    }

    return self;
}

- (NSArray*) tokenizePeriodString:(NSString*)periodString
{
    NSMutableArray* tokens = [[NSMutableArray alloc] init];
    NSMutableString* numericString = nil;

    for (NSUInteger i = 1; i < [periodString length]; i++)
    {
        unichar c = [periodString characterAtIndex:i];

        if ([self delimiterCharacter:c delimiters:@"YMDTHMS"])
        {
            if (numericString != nil)
            {
                [tokens addObject:numericString];
                numericString = nil;
            }
            [tokens addObject:[[NSString alloc] initWithCharacters:&c length:1]];
        }
        else
        {
            if (numericString == nil)
                numericString = [[NSMutableString alloc] init];
            [numericString appendString:[[NSString alloc] initWithCharacters:&c length:1]];
        }
    }

    if (numericString != nil)
        [tokens addObject:numericString];

    return tokens;
}

- (BOOL) delimiterCharacter:(unichar)c delimiters:(NSString*)delimiters
{
    for (NSUInteger j = 0; j < [delimiters length]; j++)
    {
        unichar d = [delimiters characterAtIndex:j];
        if (c == d)
            return YES;
    }

    return NO;
}

- (NSString*) toString
{
    NSMutableString* sb = [[NSMutableString alloc] initWithString:@"P"];

    if (resolution >= RESOLUTION_YEAR && _years != 0)
        [sb appendFormat:@"%dY", _years];

    if (resolution >= RESOLUTION_MONTH && _months != 0)
        [sb appendFormat:@"%dM", _months];

    if (resolution >= RESOLUTION_DAY && _days != 0)
        [sb appendFormat:@"%dD", _days];

    if (resolution >= RESOLUTION_HOUR)
        [sb appendFormat:@"T"];

    if (resolution >= RESOLUTION_HOUR && _hours != 0)
        [sb appendFormat:@"%dH", _hours];

    if (resolution >= RESOLUTION_MINUTE && _minutes != 0)
        [sb appendFormat:@"%dM", _minutes];

    if (resolution >= RESOLUTION_SECOND && _seconds != 0)
        [sb appendFormat:@"%dS", _seconds];

    return sb;
}
@end

// Internal class to provide date parsing and formatting.
@interface DateFormatter : NSObject
@end

@implementation DateFormatter

+ (NSDate*) parseDate:(NSString*)dateString
{
    int field = 0;
    int timeZoneSense = 0;
    NSDateComponents* dateComponents = [[NSDateComponents alloc] init];

    NSArray* dateTokens = [self tokenizeDateString:dateString];
    for (NSString* token in dateTokens)
    {
        if ([token isEqualToString:@"T"])
        {
            field = 3;
            continue;
        }

        if ([token isEqualToString:@"-"])
        {
            if (field < 3)
                ++field;
            else
            {
                field = 7; // timezone indicator
                timeZoneSense = -1;
            }
            continue;
        }

        if ([token isEqualToString:@":"])
        {
            ++field;
            continue;
        }

        if ([token isEqualToString:@"."])
        {
            field = 6;
            continue;
        }

        if ([token isEqualToString:@"+"])
        {
            field = 7; // timezone indicator
            timeZoneSense = 1;
            continue;
        }

        if (field >= 3 && [token isEqualToString:@"Z"])
            break; // specifies end of string and default timezone of GMT-0

        NSInteger value = [token integerValue];

        switch (field)
        {
            case 0:
                [dateComponents setYear:value];
                break;
            case 1:
                [dateComponents setMonth:value];
                break;
            case 2:
                [dateComponents setDay:value];
                break;
            case 3:
                [dateComponents setHour:value];
                break;
            case 4:
                [dateComponents setMinute:value];
                break;
            case 5:
                [dateComponents setSecond:value];
                break;
            case 6:
                // Milliseconds not supported by NSDateComponents
                break;
            case 7:
            {
                int tzHours = value / 100; // eliminate minutes from 4-digit timezone specification
                int tzMinutes = value - (tzHours * 100);
                int tzSeconds = timeZoneSense * ((tzHours * 60) + tzMinutes) * 60;
                [dateComponents setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:tzSeconds]];
                break;
            }
            default:
                break;
        }
    }

    NSCalendar* calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    [calendar setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];

    return [calendar dateFromComponents:dateComponents];
}

+ (NSArray*) tokenizeDateString:(NSString*)dateString
{
    NSMutableArray* tokens = [[NSMutableArray alloc] init];
    NSMutableString* numericString = nil;

    for (NSUInteger i = 0; i < [dateString length]; i++)
    {
        unichar c = [dateString characterAtIndex:i];

        if ([self delimiterCharacter:c delimiters:@"-T:.Z+"])
        {
            if (numericString != nil)
            {
                [tokens addObject:numericString];
                numericString = nil;
            }
            [tokens addObject:[[NSString alloc] initWithCharacters:&c length:1]];
        }
        else
        {
            if (numericString == nil)
                numericString = [[NSMutableString alloc] init];
            [numericString appendString:[[NSString alloc] initWithCharacters:&c length:1]];
        }
    }

    if (numericString != nil)
        [tokens addObject:numericString];

    return tokens;
}

+ (BOOL) delimiterCharacter:(unichar)c delimiters:(NSString*)delimiters
{
    for (NSUInteger j = 0; j < [delimiters length]; j++)
    {
        unichar d = [delimiters characterAtIndex:j];
        if (c == d)
            return YES;
    }

    return NO;
}
+ (NSString*) toString:(NSDate*)date
{
    NSDateFormatter* formatter = [[NSDateFormatter alloc] init];
    [formatter setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
    [formatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ssZ"]; // milliseconds not supported in iOS

    return [formatter stringFromDate:date];
}
@end

@interface TimeExtent : NSObject
@property(nonatomic) NSDate* first;
@property(nonatomic) NSDate* last;
@property(nonatomic) Period* period;

- (TimeExtent*) initWithTokens:(NSString*)first last:(NSString*)last period:(NSString*)period;

@end

@implementation TimeExtent

- (TimeExtent*) initWithTokens:(NSString*)first last:(NSString*)last period:(NSString*)period
{
    self = [super init];

    if (first != nil)
        _first = [DateFormatter parseDate:first];

    if (last != nil)
        _last = [DateFormatter parseDate:last];

    if (period != nil)
        _period = [[Period alloc] initWithPeriodString:period];

    return self;
}


- (NSString*) toString
{
    NSMutableString* sb = [[NSMutableString alloc] init];

    [sb appendString:[DateFormatter toString:_first]];

    if (_last != nil)
        [sb appendFormat:@"/%@", [DateFormatter toString:_last]];

    if (_period != nil)
        [sb appendFormat:@"/%@", [_period toString]];

    return sb;
}

@end

@interface TimeExtentIterator : NSObject
{
    TimeExtent* extent;
    NSDate* lastNext;
}

- (TimeExtentIterator*) initWithTimeExtent:(TimeExtent*)timeExtent;

- (BOOL) hasNext;
- (NSDate*) next;

@end

@implementation TimeExtentIterator

- (TimeExtentIterator*) initWithTimeExtent:(TimeExtent*)timeExtent
{
    self = [super init];

    extent = timeExtent;
    lastNext = nil;

    return self;
}

- (BOOL) hasNext
{
    if (lastNext == nil)
        return [extent first] != nil;

    if ([extent period] == nil || [extent last] == nil)
        return NO;

    NSDate* nextOne = [TimeExtentIterator addPeriod:[extent period] toDate:lastNext];
    return [nextOne timeIntervalSinceReferenceDate] <= [[extent last] timeIntervalSinceReferenceDate];
}

- (NSDate*) next
{
    if (lastNext == nil)
    {
        lastNext = [extent first];
        return lastNext;
    }

    if ([extent period] == nil || [extent last] == nil)
    {
        WWLog( @"next() called for time extent beyond extent iterator's end (1).");
        return nil;
    }

    lastNext = [TimeExtentIterator addPeriod:[extent period] toDate:lastNext];
    if ([lastNext timeIntervalSinceReferenceDate] > [[extent last] timeIntervalSinceReferenceDate])
    {
        WWLog( @"next() called for time extent beyond extent iterator's end (2).");
        return nil;
    }

    return lastNext;
}

+ (NSDate*) addPeriod:(Period*)period toDate:(NSDate*)date
{
    NSCalendar* calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    [calendar setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
    NSDateComponents* dateComponents = [[NSDateComponents alloc] init];

    [dateComponents setYear:[period years]];
    [dateComponents setMonth:[period months]];
    [dateComponents setDay:[period days]];
    [dateComponents setHour:[period hours]];
    [dateComponents setMinute:[period minutes]];
    [dateComponents setSecond:[period seconds]];

    return [calendar dateByAddingComponents:dateComponents toDate:date options:0];
}
@end

/**
* An internal class used by WWWMSTimeDimension to implement WWWMSDimensionIterator.
*/
@interface TimeDimensionIterator : NSObject <WWWMSDimensionIterator>
{
    WWWMSTimeDimension* dimension;
    NSArray* extents;
    NSUInteger extentsIndex;
    TimeExtentIterator* extentIterator;
}

- (TimeDimensionIterator*) initWithTimeDimension:(WWWMSTimeDimension*)timeDimension;

- (NSString*) next;
@end

@implementation TimeDimensionIterator

- (TimeDimensionIterator*) initWithTimeDimension:(WWWMSTimeDimension*)timeDimension
{
    self = [super init];

    extents = [timeDimension extents];
    extentsIndex = 0;
    if ([extents count] > 0)
        extentIterator = [[TimeExtentIterator alloc] initWithTimeExtent:[extents objectAtIndex:extentsIndex]];
    else
        extentIterator = nil;

    return self;
}

- (BOOL) hasNext
{
    if (extentIterator == nil)
        return NO;

    if ([extentIterator hasNext])
        return YES;

    if (extentsIndex < [extents count] - 1)
        return YES;

    return NO;
}

- (NSString*) next
{
    if ([extentIterator hasNext])
        return [DateFormatter toString:[extentIterator next]];

    if (extentsIndex < [extents count] - 1)
        extentIterator = [[TimeExtentIterator alloc] initWithTimeExtent:[extents objectAtIndex:++extentsIndex]];
    else
    {
        WWLog( @"next() called for time extent beyond dimension iterator's end (1).");
        return nil;
    }

    if ([extentIterator hasNext])
        return [DateFormatter toString:[extentIterator next]];
    else
    {
        WWLog( @"next() called for time extent beyond dimension iterator's end (2).");
        return nil;
    }
}

@end


@implementation WWWMSTimeDimension

- (WWWMSTimeDimension*) initWithDimensionString:(NSString*)dimensionString
{
    if (dimensionString == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Dimension string is nil")
    }

    self = [super init];

    _extents = [[NSMutableArray alloc] init];
    values = [[NSMutableArray alloc] init];

    NSArray* extentStrings = [dimensionString componentsSeparatedByString:@","];
    for (NSString* extentString in extentStrings)
    {
        NSString* token = [extentString stringByTrimmingCharactersInSet:[NSCharacterSet
                whitespaceAndNewlineCharacterSet]];

        if (token == nil || [token length] == 0)
            continue;

        TimeExtent* timeExtent = [self createExtent:token];
        if (timeExtent != nil)
            [_extents addObject:timeExtent];
    }

    return self;
}

- (TimeExtent*) createExtent:(NSString*)dimensionString
{
    NSArray* st = [dimensionString componentsSeparatedByString:@"/"];

    return [[TimeExtent alloc] initWithTokens:[st count] > 0 ? [st objectAtIndex:0] : nil
                                         last:[st count] > 1 ? [st objectAtIndex:1] : nil
                                       period:[st count] > 2 ? [st objectAtIndex:2] : nil];

}

- (int) count
{
    if ([values count] < 1)
        [self buildValues];

    return [values count];
}

- (void) buildValues
{
    [values removeAllObjects];

    TimeDimensionIterator* timeDimensionIterator = [[TimeDimensionIterator alloc] initWithTimeDimension:self];
    while ([timeDimensionIterator hasNext])
    {
        [values addObject:[timeDimensionIterator next]];
    }
}

- (NSString*) toString
{
    NSMutableString* sb = [[NSMutableString alloc] init];

    for (NSUInteger i = 0; i < [_extents count]; i++)
    {
        if (i > 0)
            [sb appendString:@","];

        [sb appendString:[[_extents objectAtIndex:i] toString]];
    }

    return sb;
}

- (id <WWWMSDimensionIterator>) iterator
{
    return [[TimeDimensionIterator alloc] initWithTimeDimension:self];
}

- (NSString*) getMapParameterName
{
    return @"time";
}
//
//- (void) testParsing
//{
//    NSCalendar* calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
//    [calendar setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
//    NSDateComponents* dateComponents = [[NSDateComponents alloc] init];
//    [dateComponents setCalendar:calendar];
//
//    [dateComponents setYear:2000];
//    [dateComponents setMonth:3];
//    [dateComponents setDay:1];
//    NSDate* date1 = [calendar dateFromComponents:dateComponents];
//
//    [dateComponents setYear:0];
//    [dateComponents setMonth:1];
//    [dateComponents setDay:0];
//
//    NSDate* date2 = [calendar dateByAddingComponents:dateComponents toDate:date1 options:0];
//
//    NSDateFormatter* formatter = [[NSDateFormatter alloc] init];
//    [formatter setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
//    [formatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ssZ"];
//    NSString* dateString = [formatter stringFromDate:date2];
//
//    NSArray* testExtents = [[NSArray alloc] initWithObjects:
////            @"2000-03-01/2013-06-01/P1M",
////            @"2005",
////            @"2005-03-28T18:23:30.120Z",
////            @"2005-03-28T18:23:30-0200",
////            @"2005-03-31/2005-04-04/P1D",
//            @"2005-03-28,2005-03-30,2005-03-31/2005-04-30/P1D",
////            @"2005-03-28/2005-04-15/P2D",
////            @"2005-03-28/2005-04-15/P1DT3H",
////            @"2005-03-28/2005-04-15/P22M",
////            @"2005-03-28/2005-04-15/P1DT12H32S",
////            @"2005-03-28/2005-04-15/PT6H",
////            @"2005-03-28T12:15:03+02/2005-04-15T04-08/PT1H",
//            nil];
//
//    for (NSString* dimensionString in testExtents)
//    {
//        WWWMSTimeDimension* td = [[WWWMSTimeDimension alloc] initWithDimensionString:dimensionString];
//        NSLog(@"%@ --> %@", dimensionString, [td toString]);
//        NSLog(@"\tCount = %d", [td count]);
//        TimeDimensionIterator* iterator = [[TimeDimensionIterator alloc] initWithTimeDimension:td];
//        while ([iterator hasNext])
//        {
//            NSLog(@"\t%@", [iterator next]);
//        }
//    }
//}

@end