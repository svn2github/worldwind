/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import "METARLayer.h"
#import "WorldWind/Util/WWRetriever.h"
#import "WorldWind/WorldWindConstants.h"
#import "WorldWind/WWLog.h"
#import "WorldWind/Geometry/WWPosition.h"
#import "WorldWind/Shapes/WWPointPlacemark.h"
#import "WorldWind/Shapes/WWPointPlacemarkAttributes.h"
#import "WorldWind/WorldWind.h"
#import "MetarIconGenerator.h"
#import "WWDrawContext.h"
#import "WWNavigatorState.h"
#import "WWVec4.h"
#import "WWGlobe.h"

@interface METARLayerRetriever : NSOperation
@end

@implementation METARLayerRetriever
{
    NSString* urlString;
    METARLayer* layer;
}

- (METARLayerRetriever*) initWithUrl:(NSString*)url layer:(METARLayer*)metarLayer
{
    self = [super init];

    urlString = url;
    layer = metarLayer;

    return self;
}

- (void) main
{
    NSURL* url = [[NSURL alloc] initWithString:urlString];
    WWRetriever* retriever = [[WWRetriever alloc] initWithUrl:url timeout:10
                                                finishedBlock:^(WWRetriever* myRetriever)
                                                {
                                                    [self parseData:myRetriever];
                                                }];
    [retriever performRetrieval];
}

- (void) parseData:(WWRetriever*)retriever
{
    @try
    {
        NSError* error = nil;
        NSString* cacheDir = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0];
        NSString* cachePath = [cacheDir stringByAppendingPathComponent:@"METARData"];
        NSString* filePath = [cachePath stringByAppendingPathComponent:@"METARData.xml"];

        NSData* metarData = nil;

        if (![[retriever status] isEqualToString:WW_SUCCEEDED] || [[retriever retrievedData] length] == 0)
        {
            // Use the previous copy if one is available.
            metarData = [[NSData alloc] initWithContentsOfFile:filePath];
        }
        else
        {
            [[NSFileManager defaultManager] createDirectoryAtPath:cachePath
                                      withIntermediateDirectories:YES attributes:nil error:&error];
            if (error != nil)
            {
                WWLog("@Error \"%@\" creating METAR cache directory %@", [error description], cachePath);
            }
            else
            {
                // Save this fresh copy so the data is available while off-line.
                [[retriever retrievedData] writeToFile:filePath atomically:YES];
            }

            metarData = [retriever retrievedData];
        }

        if (metarData == nil || [metarData length] == 0)
            return;

        NSXMLParser* docParser = [[NSXMLParser alloc] initWithData:metarData];
        [docParser setDelegate:layer];

        BOOL status = [docParser parse];
        if (status == NO)
        {
            WWLog(@"METAR data parsing failed");
        }
    }
    @catch (NSException* exception)
    {
        WWLogE(@"Exception loading METAR data", exception);
    }
}

@end

@implementation METARLayer
{
    NSMutableDictionary* currentPlacemarkDict;
    NSString* currentName;
    NSMutableString* currentString;
}

- (METARLayer*) init
{
    self = [super init];

    [self setDisplayName:@"METAR Weather"];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleRefreshNotification:)
                                                 name:WW_REFRESH
                                               object:self];

    return self;
}

- (void) setEnabled:(BOOL)enabled
{
    if (enabled)
    {
        if ([[self renderables] count] == 0)
            [self refreshData];
    }

    [super setEnabled:enabled];
}

- (void) refreshData
{
    [self removeAllRenderables];

    // Retrieve the data on a separate thread because it takes a while to download and parse.
    NSString* urlString = @"http://weather.aero/dataserver_current/httpparam?dataSource=metars&requestType=retrieve"
            "&format=xml&stationString=PA*&hoursBeforeNow=1&mostRecentForEachStation=postfilter";
    METARLayerRetriever* retriever = [[METARLayerRetriever alloc] initWithUrl:urlString layer:self];
    [[WorldWind loadQueue] addOperation:retriever];
}

- (void) handleRefreshNotification:(NSNotification*)notification
{
    if ([[notification name] isEqualToString:WW_REFRESH] && [notification object] == self)
    {
        [self refreshData];
    }
}

- (void) parser:(NSXMLParser*)parser parseErrorOccurred:(NSError*)parseError
{
    NSLog(@"%@", [parseError description]);
}

- (void) parser:(NSXMLParser*)parser didStartElement:(NSString*)elementName namespaceURI:(NSString*)namespaceURI qualifiedName:(NSString*)qName attributes:(NSDictionary*)attributeDict
{
    if ([elementName isEqualToString:@"METAR"])
    {
        currentPlacemarkDict = [[NSMutableDictionary alloc] init];
    }
    else if ([elementName isEqualToString:@"sky_condition"])
    {
        // There can be multiple sky_condition elements, so capture them in an array of dictionaries.
        NSMutableDictionary* conditionDict = [[NSMutableDictionary alloc] init];

        NSString* cover = [attributeDict objectForKey:@"sky_cover"];
        if (cover != nil)
            [conditionDict setObject:cover forKey:@"sky_cover"];
        else
            return;

        NSString* cloudBase = [attributeDict objectForKey:@"cloud_base_ft_agl"];
        if (cloudBase != nil)
            [conditionDict setObject:cloudBase forKey:@"cloud_base_ft_agl"];

        NSMutableArray* skyCovers = [currentPlacemarkDict objectForKey:@"sky_conditions"];
        if (skyCovers == nil)
        {
            skyCovers = [[NSMutableArray alloc] initWithCapacity:1];
            [currentPlacemarkDict setObject:skyCovers forKey:@"sky_conditions"];
        }

        [skyCovers addObject:conditionDict];
    }
    else
    {
        currentName = elementName;
        currentString = [[NSMutableString alloc] init];
    }
}

- (void) parser:(NSXMLParser*)parser didEndElement:(NSString*)elementName namespaceURI:(NSString*)namespaceURI qualifiedName:(NSString*)qName
{
    if ([elementName isEqualToString:@"METAR"])
    {
        [self addCurrentPlacemark];
        currentPlacemarkDict = nil;
    }
    else if (currentName != nil && currentString != nil)
    {
        [currentPlacemarkDict setObject:currentString forKey:currentName];
    }

    currentName = nil;
    currentString = nil;
}

- (void) parser:(NSXMLParser*)parser foundCharacters:(NSString*)string
{
    if (currentString != nil)
    {
        [currentString appendString:string];
    }
}

- (void) parserDidEndDocument:(NSXMLParser*)parser
{
    [[NSNotificationCenter defaultCenter] postNotificationName:WW_REFRESH_COMPLETE object:self];
}

- (void) addCurrentPlacemark
{
    WWPosition* position = [self parseCoordinates];
    WWPointPlacemark* pointPlacemark = [[WWPointPlacemark alloc] initWithPosition:position];
    [pointPlacemark setAltitudeMode:WW_ALTITUDE_MODE_CLAMP_TO_GROUND];
    [pointPlacemark setUserObject:currentPlacemarkDict];

    NSString* name = [currentPlacemarkDict objectForKey:@"station_id"];
    if (name != nil)
    {
        [pointPlacemark setDisplayName:name];
    }

    NSString* iconFilePath = [MetarIconGenerator createIconFile:currentPlacemarkDict];
    if (iconFilePath == nil) // in case something goes wrong
        iconFilePath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"weather32x32.png"];

    WWPointPlacemarkAttributes* attrs = [[WWPointPlacemarkAttributes alloc] init];
    [attrs setImagePath:iconFilePath];
    [attrs setImageScale:0.5];
    [pointPlacemark setAttributes:attrs];

    [self performSelectorOnMainThread:@selector(addPlacemarkOnMainThread:) withObject:pointPlacemark waitUntilDone:NO];
}

- (void) addPlacemarkOnMainThread:(WWPointPlacemark*)placemark
{
    [self addRenderable:placemark];

    [[NSNotificationCenter defaultCenter] postNotificationName:WW_REQUEST_REDRAW object:self];
}

- (WWPosition*) parseCoordinates
{
    NSString* latString = [currentPlacemarkDict objectForKey:@"latitude"];
    NSString* lonString = [currentPlacemarkDict objectForKey:@"longitude"];

    double lat = [latString doubleValue];
    double lon = [lonString doubleValue];

    return [[WWPosition alloc] initWithDegreesLatitude:lat longitude:lon altitude:0];
}

#define MIN_SCALE (0.2)
#define MAX_SCALE (1.0)
#define MIN_DIST (100e3)
#define MAX_DIST (500e3)

- (void) doRender:(WWDrawContext*)dc
{
    WWVec4* eyePoint = [[dc navigatorState] eyePoint];

    for (WWPointPlacemark* placemark in [self renderables])
    {
        WWPosition* pos = [placemark position];
        WWVec4* placemarkPoint = [[WWVec4 alloc] init];
        [[dc globe] computePointFromPosition:[pos latitude] longitude:[pos longitude]
                                                             altitude:[pos altitude] outputPoint:placemarkPoint];
        double d = [placemarkPoint distanceTo3:eyePoint];

        double scale;
        if (d >= MAX_DIST)
            scale = MIN_SCALE;
        else if (d <= MIN_DIST)
            scale = MAX_SCALE;
        else
            scale = MIN_SCALE + (MAX_SCALE - MIN_SCALE) * ((MAX_DIST - d) / (MAX_DIST - MIN_DIST));

        [[placemark attributes] setImageScale:scale];

        [placemark render:dc];
    }
}

@end