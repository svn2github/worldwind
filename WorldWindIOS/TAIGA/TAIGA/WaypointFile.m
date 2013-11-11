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

- (WaypointFile*) init
{
    self = [super init];

    waypointArray = [[NSMutableArray alloc] initWithCapacity:8];
    waypointKeyMap = [[NSMutableDictionary alloc] initWithCapacity:8];

    return self;
}

- (void) loadDAFIFAirports:(NSURL*)url finishedBlock:(void (^)(void))finishedBlock
{
    if (url == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"URL is nil")
    }

    WWRetriever* retriever = [[WWRetriever alloc] initWithUrl:url timeout:5 finishedBlock:^(WWRetriever* myRetriever)
    {
        [self finishRetrieving:myRetriever];

        if (finishedBlock != NULL)
        {
            finishedBlock();
        }
    }];

    [retriever performRetrieval];
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

- (void) finishRetrieving:(WWRetriever*)retriever
{
    NSString* cacheDir = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString* cachePath = [cacheDir stringByAppendingPathComponent:[[retriever url] path]];

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

        [self parseData:[retriever retrievedData]];
    }
    else
    {
        WWLog(@"Unable to retrieve waypoint file %@, falling back to local cache.", [[retriever url] absoluteString]);

        // Otherwise, attempt to use a previously cached version.
        NSData* data = [NSData dataWithContentsOfFile:cachePath];
        if (data != nil)
        {
            [self parseData:data];
        }
        else
        {
            WWLog(@"Unable to read local cache of waypoint file %@", [[retriever url] absoluteString]);
        }
    }
}

- (void) parseData:(NSData*)data
{
    NSString* string = [[NSString alloc] initWithData:data encoding:NSWindowsCP1252StringEncoding];
    NSMutableArray* fieldNames = [[NSMutableArray alloc] initWithCapacity:8];
    NSMutableArray* rows = [[NSMutableArray alloc] initWithCapacity:8];

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

            [rows addObject:rowValues];
        }
    }];

    [self parseDAFIFTableRows:rows];
}

- (void) parseDAFIFTableRows:(NSArray*)rows
{
    for (NSDictionary* row in rows)
    {
        NSString* key = [row objectForKey:@"ARPT_IDENT"];
        double latDegrees = [[row objectForKey:@"WGS_DLAT"] doubleValue];
        double lonDegrees = [[row objectForKey:@"WGS_DLONG"] doubleValue];
        WWLocation* location = [[WWLocation alloc] initWithDegreesLatitude:latDegrees longitude:lonDegrees];

        Waypoint* waypoint = [[Waypoint alloc] initWithKey:key location:location];
        [waypoint setProperties:row];
        [waypoint setDisplayName:[row objectForKey:@"FAA_HOST_ID"]];
        [waypoint setDisplayNameLong:[row objectForKey:@"NAME"]];
        [waypointArray addObject:waypoint];
        [waypointKeyMap setValue:waypoint forKey:key];
    }

    [waypointArray sortUsingComparator:^(id obj1, id obj2)
    {
        return [[obj1 displayName] compare:[obj2 displayName]];
    }];
}

@end