/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.

 @version $Id$
 */

#import "WaypointDatabase.h"
#import "Waypoint.h"
#import "WorldWind/Geometry/WWLocation.h"
#import "WorldWind/Util/WWRetriever.h"
#import "WorldWind/WorldWindConstants.h"
#import "WorldWind/WWLog.h"

@implementation WaypointDatabase

- (id) init
{
    self = [super init];

    waypointArray = [[NSMutableArray alloc] initWithCapacity:8];
    waypointKeyMap = [[NSMutableDictionary alloc] initWithCapacity:8];

    return self;
}

- (void) addWaypointTables:(NSArray*)urlArray finishedBlock:(void (^)(void))finishedBlock
{
    if (urlArray == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"URL array is nil")
    }

    if (finishedBlock == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Finished block is nil")
    }

    const NSUInteger tableCount = [urlArray count];
    __block NSUInteger tablesCompleted = 0;

    for (NSString* urlString in urlArray)
    {
        NSURL* url = [NSURL URLWithString:urlString];
        WWRetriever* retriever = [[WWRetriever alloc] initWithUrl:url timeout:5.0 finishedBlock:^(WWRetriever* waypointRetriever)
        {
            [self waypointTableRetrieverDidFinish:waypointRetriever];

            if (++tablesCompleted == tableCount)
            {
                [self didAddWaypointTables:finishedBlock];
            }
        }];
        [retriever performRetrieval];
    }
}

- (NSArray*) waypoints
{
    return waypointArray;
}

- (NSArray*) waypointsMatchingText:(NSString*)text
{
    if (text == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Text is nil")
    }

    NSPredicate* predicate = [NSPredicate predicateWithFormat:@"displayName LIKE[cd] %@ OR displayNameLong LIKE[cd] %@",
                    text, text];

    return [waypointArray filteredArrayUsingPredicate:predicate];
}

- (Waypoint*) waypointForKey:(NSString*)key
{
    if (key == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Key is nil")
    }

    return [waypointKeyMap objectForKey:key];
}

- (void) didAddWaypointTables:(void (^)(void))finishedBlock
{
    [waypointArray sortUsingComparator:^(id obj1, id obj2)
    {
        return [[obj1 displayName] compare:[obj2 displayName]];
    }];

    finishedBlock();
}

- (void) waypointTableRetrieverDidFinish:(WWRetriever*)retriever
{
    NSString* cacheDir = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString* cachePath = [cacheDir stringByAppendingPathComponent:[[retriever url] path]];
    NSString* location = [[retriever url] absoluteString]; // used for message logging

    if ([[retriever status] isEqualToString:WW_SUCCEEDED] && [[retriever retrievedData] length] > 0)
    {
        // If the retrieval was successful, cache the retrieved file and parse its contents directly from the retriever.
        NSError* error = nil;
        [[NSFileManager defaultManager] createDirectoryAtPath:[cachePath stringByDeletingLastPathComponent]
                                  withIntermediateDirectories:YES attributes:nil error:&error];
        if (error != nil)
        {
            WWLog(@"Unable to create waypoint table cache directory, %@", [error description]);
        }
        else
        {
            [[retriever retrievedData] writeToFile:cachePath options:NSDataWritingAtomic error:&error];
            if (error != nil)
            {
                WWLog(@"Unable to write waypoint table to cache, %@", [error description]);
            }
        }

        [self parseWaypointTable:[retriever retrievedData] location:location];
    }
    else
    {
        WWLog(@"Unable to retrieve waypoint table %@, falling back to local cache.", location);

        // Otherwise, attempt to use a previously cached version.
        NSData* data = [NSData dataWithContentsOfFile:cachePath];
        if (data != nil)
        {
            [self parseWaypointTable:data location:location];
        }
        else
        {
            WWLog(@"Unable to read local cache of waypoint table %@", location);
        }
    }
}

- (void) parseWaypointTable:(NSData*)data location:(NSString*)location
{
    NSString* string = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    NSMutableArray* fieldNames = [[NSMutableArray alloc] initWithCapacity:8];
    NSMutableArray* tableRows = [[NSMutableArray alloc] initWithCapacity:8];

    [string enumerateLinesUsingBlock:^(NSString* line, BOOL* stop)
    {
        NSArray* lineComponents = [line componentsSeparatedByString:@"\t"];

        if ([fieldNames count] == 0) // first line indicates DAFIF table field names
        {
            [fieldNames addObjectsFromArray:lineComponents];
        }
        else // subsequent lines indicate DAFIF table row values
        {
            NSMutableDictionary* rowValues = [[NSMutableDictionary alloc] init];
            for (NSUInteger i = 0; i < [lineComponents count] && i < [fieldNames count]; i++)
            {
                [rowValues setObject:[lineComponents objectAtIndex:i] forKey:[fieldNames objectAtIndex:i]];
            }

            [tableRows addObject:rowValues];
        }
    }];

    if ([[fieldNames firstObject] isEqual:@"ARPT_IDENT"])
    {
        [self parseAirportTable:tableRows];
    }
    else
    {
        WWLog(@"Unrecognized waypoint table %@", location);
    }
}

- (void) parseAirportTable:(NSArray*)tableRows
{
    for (NSDictionary* row in tableRows)
    {
        NSString* id = [row objectForKey:@"ARPT_IDENT"];
        NSNumber* latDegrees = [row objectForKey:@"WGS_DLAT"];
        NSNumber* lonDegrees = [row objectForKey:@"WGS_DLONG"];
        NSString* icao = [row objectForKey:@"ICAO"];
        NSString* name = [row objectForKey:@"NAME"];

        WWLocation* location = [[WWLocation alloc] initWithDegreesLatitude:[latDegrees doubleValue]
                                                                 longitude:[lonDegrees doubleValue]];

        NSMutableString* displayName = [[NSMutableString alloc] init];
        [displayName appendString:icao];
        [displayName appendString:@": "];
        [displayName appendString:[name capitalizedString]];

        Waypoint* waypoint = [[Waypoint alloc] initWithKey:id location:location type:WaypointTypeAirport];
        [waypoint setProperties:row];
        [waypoint setDisplayName:displayName];
        [waypointArray addObject:waypoint];
        [waypointKeyMap setValue:waypoint forKey:id];
    }
}

@end