/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import "FlightPathsLayer.h"
#import "WWRetriever.h"
#import "WorldWindConstants.h"
#import "WWLog.h"
#import "WWLayerList.h"
#import "WWDrawContext.h"
#import "WorldWindView.h"
#import "WWSceneController.h"
#import "WWShapeAttributes.h"
#import "WWColor.h"
#import "WWPosition.h"
#import "WWPath.h"

@implementation FlightPathsLayer

- (FlightPathsLayer*) initWithPathsLocation:(NSString*)pathsLocation
{
    self = [super init];

    [self setDisplayName:@"Alaska Flight Paths"];

    NSURL* url = [[NSURL alloc] initWithString:pathsLocation];
    WWRetriever* retriever = [[WWRetriever alloc] initWithUrl:url timeout:5
                                                finishedBlock:^(WWRetriever* myRetriever)
                                                {
                                                    [self makeFlightPaths:myRetriever];
                                                }];
    [retriever performRetrieval];

    return self;
}

- (void) makeFlightPaths:(WWRetriever*)retriever
{
    if (![[retriever status] isEqualToString:WW_SUCCEEDED] || [[retriever retrievedData] length] == 0)
    {
        WWLog(@"Unable to download Alaska flight paths file %@", [[retriever url] absoluteString]);
        return;
    }

    NSData* data = [retriever retrievedData];

    NSError* error;
    NSDictionary* jData = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
    if (error != nil)
    {
        NSDictionary* userInfo = [error userInfo];
        NSString* errMsg = [[userInfo objectForKey:NSUnderlyingErrorKey] localizedDescription];
        WWLog(@"Error %@ reading flight paths file %@", errMsg, [[retriever url] absoluteString]);
        return;
    }

    // Path colors derived from http://www.colorcombos.com/color-schemes/95/ColorCombo95.html
    WWShapeAttributes* attrs = [[WWShapeAttributes alloc] init];
    [attrs setOutlineColor:[[WWColor alloc] initWithR:0.8 g:0.2 b:0.2 a:1]];
    [attrs setOutlineWidth:3];

    WWShapeAttributes* highlightAttrs = [[WWShapeAttributes alloc] init];
    [highlightAttrs setOutlineColor:[[WWColor alloc] initWithR:1.0 g:0.6 b:0 a:1]];
    [highlightAttrs setOutlineWidth:5];

    NSArray* features = [jData valueForKey:@"features"];
    for (NSUInteger i = 0; i < [features count]; i++)
    {
        // Make a Path
        NSDictionary* entry = (NSDictionary*) [features objectAtIndex:i];
        NSDictionary* geometry = [entry valueForKey:@"geometry"];

        // Make the path's positions
        NSArray* coords = [geometry valueForKey:@"coordinates"];
        NSMutableArray* pathCoords = [[NSMutableArray alloc] initWithCapacity:[coords count]];
        for (NSUInteger j = 0; j < [coords count]; j++)
        {
            NSArray* values = [coords objectAtIndex:j];
            NSNumber* lon = [values objectAtIndex:0];
            NSNumber* lat = [values objectAtIndex:1];
            NSDecimalNumber* alt = [values objectAtIndex:2];

            WWPosition* pos = [[WWPosition alloc] initWithDegreesLatitude:[lat doubleValue]
                                                                longitude:[lon doubleValue]
                                                                 altitude:([alt doubleValue] > 0 ? [alt doubleValue]
                                                                         : 4572)]; // 15,000 feet
            [pathCoords addObject:pos];
        }

        WWPath* path = [[WWPath alloc] initWithPositions:pathCoords];
        [path setDisplayName:[NSString stringWithFormat:@"Flight Path %d", i + 1]];
        [path setAltitudeMode:WW_ALTITUDE_MODE_ABSOLUTE];
        [path setAttributes:attrs];
        [path setHighlightAttributes:highlightAttrs];
        [self addRenderable:path];
    }
}

@end