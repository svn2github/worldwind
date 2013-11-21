/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.

 @version $Id$
 */

#import "WaypointFile.h"
#import "Waypoint.h"
#import "WorldWind/Geometry/WWLocation.h"
#import "WorldWind/Util/WWRetriever.h"
#import "WorldWind/WorldWindConstants.h"
#import "WorldWind/WWLog.h"

@implementation WaypointFile

- (WaypointFile*) initWithWaypointLocations:(NSArray*)locationArray finishedBlock:(void (^)(WaypointFile*))finishedBlock
{
    if (locationArray == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Location array is nil")
    }

    if (finishedBlock == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Finished block is nil")
    }

    self = [super init];

    waypointArray = [[NSMutableArray alloc] initWithCapacity:8];
    waypointKeyMap = [[NSMutableDictionary alloc] initWithCapacity:8];
    finished = finishedBlock;

    const NSUInteger locationsCount = [locationArray count];
    __block NSUInteger locationsCompleted = 0;

    for (NSString* location in locationArray)
    {
        NSURL* url = [NSURL URLWithString:location];
        WWRetriever* retriever = [[WWRetriever alloc] initWithUrl:url timeout:5.0 finishedBlock:^(WWRetriever* waypointRetriever)
        {
            [self waypointRetrieverDidFinish:waypointRetriever];

            if (++locationsCompleted >= locationsCount)
            {
                [self waypointLocationsDidFinish];
            }
        }];
        [retriever performRetrieval];
    }

    return self;
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

- (void) waypointLocationsDidFinish
{
    [waypointArray sortUsingComparator:^(id obj1, id obj2)
    {
        return [[obj1 displayName] compare:[obj2 displayName]];
    }];

    finished(self);
}

- (void) waypointRetrieverDidFinish:(WWRetriever*)retriever
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
            WWLog(@"Unable to create waypoint file cache directory, %@", [error description]);
        }
        else
        {
            [[retriever retrievedData] writeToFile:cachePath options:NSDataWritingAtomic error:&error];
            if (error != nil)
            {
                WWLog(@"Unable to write waypoint file to cache, %@", [error description]);
            }
        }

        [self parseWaypointTable:[retriever retrievedData] location:location];
    }
    else
    {
        WWLog(@"Unable to retrieve waypoint file %@, falling back to local cache.", location);

        // Otherwise, attempt to use a previously cached version.
        NSData* data = [NSData dataWithContentsOfFile:cachePath];
        if (data != nil)
        {
            [self parseWaypointTable:data location:location];
        }
        else
        {
            WWLog(@"Unable to read local cache of waypoint file %@", location);
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
        [self parseDAFIFAirportTable:tableRows];
    }
    else if ([[fieldNames firstObject] isEqual:@"WPT_IDENT"])
    {
        [self parseDAFIFWaypointTable:tableRows];
    }
    else
    {
        WWLog(@"Unrecognized waypoint file %@", location);
    }
}

- (void) parseDAFIFAirportTable:(NSArray*)tableRows
{
    for (NSDictionary* row in tableRows)
    {
        NSString* key = [row objectForKey:@"ARPT_IDENT"];
        double latDegrees = [[row objectForKey:@"WGS_DLAT"] doubleValue];
        double lonDegrees = [[row objectForKey:@"WGS_DLONG"] doubleValue];
        WWLocation* location = [[WWLocation alloc] initWithDegreesLatitude:latDegrees longitude:lonDegrees];

        Waypoint* waypoint = [[Waypoint alloc] initWithKey:key location:location type:WaypointTypeAirport];
        [waypoint setProperties:row];
        [waypoint setDisplayName:[row objectForKey:@"FAA_HOST_ID"]];
        [waypoint setDisplayNameLong:[row objectForKey:@"NAME"]];
        [waypointArray addObject:waypoint];
        [waypointKeyMap setValue:waypoint forKey:key];
    }
}

- (void) parseDAFIFWaypointTable:(NSArray*)tableRows
{
    for (NSDictionary* row in tableRows)
    {
        NSString* key = [row objectForKey:@"WPT_IDENT"];
        double latDegrees = [[row objectForKey:@"WGS_DLAT"] doubleValue];
        double lonDegrees = [[row objectForKey:@"WGS_DLONG"] doubleValue];
        WWLocation* location = [[WWLocation alloc] initWithDegreesLatitude:latDegrees longitude:lonDegrees];

        Waypoint* waypoint = [[Waypoint alloc] initWithKey:key location:location type:WaypointTypeOther];
        [waypoint setProperties:row];
        [waypoint setDisplayName:[row objectForKey:@"ICAO"]];
        [waypoint setDisplayNameLong:[row objectForKey:@"DESC"]];
        [waypointArray addObject:waypoint];
        [waypointKeyMap setValue:waypoint forKey:key];
    }
}

@end