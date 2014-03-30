/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.

 @version $Id$
 */

#import "WaypointDatabase.h"
#import "Waypoint.h"
#import "WorldWind/Util/WWRetriever.h"
#import "WorldWind/WorldWindConstants.h"
#import "WorldWind/WWLog.h"

@implementation WaypointDatabase

- (id) init
{
    self = [super init];

    NSUserDefaults* userState = [NSUserDefaults standardUserDefaults];
    waypoints = [[NSMutableDictionary alloc] init];
    waypointStateKeys = [[NSMutableSet alloc] initWithArray:[userState objectForKey:@"gov.nasa.worldwind.taiga.waypointKeys"]];

    for (NSString* stateKey in waypointStateKeys)
    {
        NSDictionary* stateValues = [userState objectForKey:stateKey];
        Waypoint* waypoint = [[Waypoint alloc] initWithPropertyList:stateValues];
        [waypoints setObject:waypoint forKey:[waypoint key]];
    }

    return self;
}

- (void) addWaypoint:(Waypoint*)waypoint
{
    if (waypoint == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Waypoint is nil")
    }

    NSString* stateKey = [NSString stringWithFormat:@"gov.nasa.worldwind.taiga.waypoint.%@", [waypoint key]];
    NSDictionary* stateValues = [waypoint propertyList];

    [waypoints setObject:waypoint forKey:[waypoint key]];
    [waypointStateKeys addObject:stateKey];

    NSUserDefaults* userState = [NSUserDefaults standardUserDefaults];
    [userState setObject:stateValues forKey:stateKey];
    [userState setObject:[waypointStateKeys allObjects] forKey:@"gov.nasa.worldwind.taiga.waypointKeys"];
    [userState synchronize];
}

- (void) addWaypointsFromTable:(NSString*)urlString completionBlock:(void(^)(void))completionBlock
{
    if (urlString == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"URL string is nil")
    }

    NSURL* url = [NSURL URLWithString:urlString];
    WWRetriever* tableRetriever = [[WWRetriever alloc] initWithUrl:url timeout:5.0 finishedBlock:^(WWRetriever* retriever)
    {
        [self addWaypointsFromTableRetriever:retriever];

        if (completionBlock != nil)
        {
            completionBlock();
        }
    }];

    [tableRetriever performRetrieval];
}

- (void) addWaypointsFromTableRetriever:(WWRetriever*)retriever
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

        [self addWaypointsFromTableData:[retriever retrievedData]];
    }
    else
    {
        WWLog(@"Unable to retrieve waypoint table %@, falling back to local cache.", location);

        // Otherwise, attempt to use a previously cached version.
        NSData* data = [NSData dataWithContentsOfFile:cachePath];
        if (data != nil)
        {
            [self addWaypointsFromTableData:data];
        }
        else
        {
            WWLog(@"Unable to read local cache of waypoint table %@", location);
        }
    }
}

- (void) addWaypointsFromTableData:(NSData*)data
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

    for (NSDictionary* row in tableRows)
    {
        Waypoint* waypoint = [[Waypoint alloc] initWithWaypointTableRow:row];
        [waypoints setObject:waypoint forKey:[waypoint key]];
    }
}

- (NSArray*) waypoints
{
    return [waypoints allValues];
}

- (Waypoint*) waypointForKey:(NSString*)key
{
    if (key == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Key is nil")
    }

    return [waypoints objectForKey:key];
}

@end