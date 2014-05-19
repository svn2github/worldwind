/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.

 @version $Id$
 */

#import "WaypointLayer.h"
#import "Waypoint.h"
#import "AppConstants.h"
#import "TAIGA.h"
#import "WorldWind/Geometry/WWPosition.h"
#import "WorldWind/Geometry/WWVec4.h"
#import "WorldWind/Navigate/WWNavigatorState.h"
#import "WorldWind/Render/WWDrawContext.h"
#import "WorldWind/Shapes/WWPointPlacemark.h"
#import "WorldWind/Shapes/WWPointPlacemarkAttributes.h"
#import "WorldWind/Terrain/WWGlobe.h"
#import "WorldWind/Util/WWMath.h"
#import "WorldWind/Util/WWOffset.h"
#import "WorldWind/Util/WWRetriever.h"
#import "WorldWind/WorldWind.h"
#import "WorldWind/WorldWindView.h"

#define HIGHLIGHT_NEAR_DIST (450e3)
#define HIGHLIGHT_FAR_DIST (550e3)
#define HIGHLIGHT_NEAR_SCALE (1.0)
#define HIGHLIGHT_FAR_SCALE (0.25)

@implementation WaypointLayer

- (WaypointLayer*) init
{
    self = [super init];

    [self setDisplayName:@"Airports"];
    [self refreshWaypoints];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleRefreshNotification:)
                                                 name:TAIGA_REFRESH object:nil];

    return self;
}

- (void) doRender:(WWDrawContext*)dc
{
    WWVec4* eyePoint = [[dc navigatorState] eyePoint];
    WWVec4* placemarkPoint = [[WWVec4 alloc] init];
    WWGlobe* globe = [dc globe];

    for (WWPointPlacemark* placemark in [self renderables])
    {
        WWPosition* pos = [placemark position];
        WWPointPlacemarkAttributes* highlightAttrs = [placemark highlightAttributes];

        [globe computePointFromPosition:[pos latitude] longitude:[pos longitude] altitude:[pos altitude] outputPoint:placemarkPoint];
        double d = [placemarkPoint distanceTo3:eyePoint];

        BOOL highlight = d < HIGHLIGHT_FAR_DIST && highlightAttrs != nil;
        [placemark setHighlighted:highlight];

        if (highlight)
        {
            double dnorm = [WWMath smoothStepValue:d min:HIGHLIGHT_NEAR_DIST max:HIGHLIGHT_FAR_DIST];
            double scale = [WWMath interpolateValue1:HIGHLIGHT_NEAR_SCALE value2:HIGHLIGHT_FAR_SCALE amount:dnorm];
            [highlightAttrs setImageScale:scale];
        }

        [placemark render:dc];
    }
}

- (void) handleRefreshNotification:(NSNotification*)notification
{
    if ([[notification name] isEqualToString:TAIGA_REFRESH]
            && ([notification object] == nil || [notification object] == self))
    {
        [self refreshWaypoints];
    }
}

- (void) refreshWaypoints
{
    if (refreshInProgress)
    {
        return;
    }

    refreshInProgress = YES;

    // Initiate the waypoint retrieval and parsing on a separate thread managed by the World Wind load queue. Though the
    // retrieval is performed on a thread separate from the load queue thread, this pattern enables TAIGA to throttle
    // the number of simultaneous loads, and performs waypoint parsing on a separate thread.
    [[WorldWind loadQueue] addOperationWithBlock:^
    {
        [self retrieveWaypoints];
    }];
}

- (void) retrieveWaypoints
{
    NSURL* url = [NSURL URLWithString:@"http://worldwindserver.net/taiga/dafif/ARPT2_ALASKA.TXT"];
    WWRetriever* waypointRetriever = [[WWRetriever alloc] initWithUrl:url timeout:10
                                                        finishedBlock:^(WWRetriever* retriever)
                                                        {
                                                            [self parseWaypoints:retriever];
                                                        }];
    [waypointRetriever performRetrieval];
}

- (void) parseWaypoints:(WWRetriever*)retriever
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

        [self parseWaypointsWithData:[retriever retrievedData]];
    }
    else
    {
        WWLog(@"Unable to retrieve waypoint table %@, falling back to local cache.", location);

        // Otherwise, attempt to use a previously cached version.
        NSData* data = [NSData dataWithContentsOfFile:cachePath];
        if (data != nil)
        {
            [self parseWaypointsWithData:data];
        }
        else
        {
            WWLog(@"Unable to read local cache of waypoint table %@", location);
        }
    }
}

- (void) parseWaypointsWithData:(NSData*)data
{
    NSMutableArray* waypoints = [[NSMutableArray alloc] init];
    NSMutableArray* placemarks = [[NSMutableArray alloc] init];

    WWPointPlacemarkAttributes* attrs = [[WWPointPlacemarkAttributes alloc] init];
    [attrs setImagePath:[[NSBundle mainBundle] pathForResource:@"airport@small" ofType:@"png"]];
    [attrs setImageOffset:[[WWOffset alloc] initWithFractionX:0.5 y:0.5]];

    [self enumerateTableRowsWithData:data block:^(NSDictionary* rowValues)
    {
        Waypoint* waypoint = [[Waypoint alloc] initWithWaypointTableRow:rowValues];
        [waypoints addObject:waypoint];

        WWPosition* pos = [[WWPosition alloc] initWithDegreesLatitude:[waypoint latitude] longitude:[waypoint longitude] altitude:[waypoint altitude]];
        WWPointPlacemark* placemark = [[WWPointPlacemark alloc] initWithPosition:pos];
        [placemark setUserObject:waypoint];
        [placemark setPickDelegate:waypoint]; // make the waypoint the picked object
        [placemark setDisplayName:[waypoint displayName]];
        [placemark setAltitudeMode:WW_ALTITUDE_MODE_CLAMP_TO_GROUND];
        [placemark setAttributes:attrs];
        [placemarks addObject:placemark];
    }];

    [self assembleWaypointImages:placemarks];

    [TAIGA performSelectorOnMainThread:@selector(setWaypoints:) withObject:waypoints waitUntilDone:NO];
    [self performSelectorOnMainThread:@selector(setPlacemarks:) withObject:placemarks waitUntilDone:NO];
}

- (void) enumerateTableRowsWithData:(NSData*)data block:(void (^)(NSDictionary*))block
{
    NSString* string = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    NSMutableArray* fieldNames = [[NSMutableArray alloc] init];

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

            block(rowValues);
        }
    }];
}

- (void) assembleWaypointImages:(NSArray*)placemarks
{
    NSString* highlightImageDir = NSTemporaryDirectory();
    NSError* error = nil;
    [[NSFileManager defaultManager] createDirectoryAtPath:highlightImageDir
                              withIntermediateDirectories:YES attributes:nil error:&error];
    if (error != nil)
    {
        NSDictionary* userInfo = [error userInfo];
        NSString* errMsg = [[userInfo objectForKey:NSUnderlyingErrorKey] localizedDescription];
        WWLog(@"Error %@ creating waypoint image directory %@", errMsg, highlightImageDir);
        return;
    }

    UIImage* templateImage = [UIImage imageNamed:@"airport@large"];
    CGSize templateSize = [templateImage size];

    NSDictionary* fontAttrs = @{NSFontAttributeName:[UIFont systemFontOfSize:[UIFont labelFontSize]]};
    NSDictionary* smallFontAttrs = @{NSFontAttributeName:[UIFont systemFontOfSize:[UIFont systemFontSize] - 3]};

    WWOffset* highlightImageOffset = [[WWOffset alloc] initWithFractionX:0.5 y:0.0];

    @try
    {
        UIGraphicsBeginImageContext(templateSize);
        CGContextRef gc = UIGraphicsGetCurrentContext();

        for (WWPointPlacemark* placemark in placemarks)
        {
            Waypoint* waypoint = [placemark userObject];
            NSString* text = [[waypoint properties] objectForKey:@"ICAO"];
            NSDictionary* textAttrs = fontAttrs;
            CGSize textSize = [text sizeWithAttributes:textAttrs];

            if (textSize.width > 36)
            {
                textAttrs = smallFontAttrs;
                textSize = [text sizeWithAttributes:textAttrs];
            }

            CGContextClearRect(gc, CGRectMake(0, 0, templateSize.width, templateSize.height));
            [templateImage drawAtPoint:CGPointMake(0, 0)];
            [text drawAtPoint:CGPointMake((templateSize.width - textSize.width) / 2, (templateSize.height - textSize.height) / 2)
               withAttributes:textAttrs];

            UIImage* highlightImage = UIGraphicsGetImageFromCurrentImageContext();
            NSData* highlightImageData = UIImagePNGRepresentation(highlightImage);
            NSString* highlightImagePath = [highlightImageDir stringByAppendingPathComponent:[[NSProcessInfo processInfo] globallyUniqueString]];
            [highlightImageData writeToFile:highlightImagePath atomically:YES];

            WWPointPlacemarkAttributes* highlightAttrs = [[WWPointPlacemarkAttributes alloc] init];
            [highlightAttrs setImagePath:highlightImagePath];
            [highlightAttrs setImageOffset:highlightImageOffset];
            [placemark setHighlightAttributes:highlightAttrs];
        }
    }
    @finally
    {
        UIGraphicsEndImageContext();
    }
}

- (void) setPlacemarks:(NSArray*)placemarks
{
    [self removeAllRenderables];
    [self addRenderables:placemarks];
    [WorldWindView requestRedraw];

    refreshInProgress = NO;
}

@end