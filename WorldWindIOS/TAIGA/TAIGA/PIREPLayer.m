/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import "PIREPLayer.h"
#import "WWRetriever.h"
#import "WorldWindConstants.h"
#import "WWLog.h"
#import "WorldWind.h"
#import "WWPosition.h"
#import "WWPointPlacemarkAttributes.h"
#import "WWPointPlacemark.h"

@interface PIREPLayerRetriever : NSOperation
@end

@implementation PIREPLayerRetriever
{
    NSString* urlString;
    PIREPLayer* layer;
}

- (PIREPLayerRetriever*) initWithUrl:(NSString*)url layer:(PIREPLayer*)metarLayer
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
        NSString* cachePath = [cacheDir stringByAppendingPathComponent:@"PIREP"];
        NSString* filePath = [cachePath stringByAppendingPathComponent:@"PIREPData.xml"];

        NSData* pirepData = nil;

        if (![[retriever status] isEqualToString:WW_SUCCEEDED] || [[retriever retrievedData] length] == 0)
        {
            // Use the previous copy if one is available.
            pirepData = [[NSData alloc] initWithContentsOfFile:filePath];
        }
        else
        {
            [[NSFileManager defaultManager] createDirectoryAtPath:cachePath
                                      withIntermediateDirectories:YES attributes:nil error:&error];
            if (error != nil)
            {
                WWLog("@Error \"%@\" creating PIREP cache directory %@", [error description], cachePath);
            }
            else
            {
                // Save this fresh copy so the data is available while off-line.
                [[retriever retrievedData] writeToFile:filePath atomically:YES];
            }

            pirepData = [retriever retrievedData];
        }

        if (pirepData == nil || [pirepData length] == 0)
            return;

        NSXMLParser* docParser = [[NSXMLParser alloc] initWithData:pirepData];
        [docParser setDelegate:layer];

        BOOL status = [docParser parse];
        if (status == NO)
        {
            WWLog(@"PIREP data parsing failed");
        }
    }
    @catch (NSException* exception)
    {
        WWLogE(@"Exception loading PIREP data", exception);
    }
}

@end

@implementation PIREPLayer
{
    NSMutableDictionary* currentPlacemark;
    NSString* currentName;
    NSMutableString* currentString;
    NSString* iconFilePath;
    NSMutableArray* placemarks;
}

- (PIREPLayer*) init
{
    self = [super init];

    [self setDisplayName:@"PIREPS"];

    iconFilePath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"PIREP_ICONS_Generic.png"];

    return self;
}

- (void) setEnabled:(BOOL)enabled
{
    if (enabled)
    {
        [self refreshData];
    }

    [super setEnabled:enabled];
}

- (void) refreshData
{
    // Retrieve the data on a separate thread because it takes a while to download and parse.
    NSString* urlString = @"http://www.aviationweather"
            ".gov/adds/dataserver_current/httpparam?dataSource=aircraftreports&requestType=retrieve&format=xml&minLat"
            "=52&minLon=-170&maxLat=72&maxLon=-130&hoursBeforeNow=3&minAltitudeFt=0&maxAltitudeFt=15000";
    PIREPLayerRetriever* retriever = [[PIREPLayerRetriever alloc] initWithUrl:urlString layer:self];
    [[WorldWind loadQueue] addOperation:retriever];
}

- (void) parser:(NSXMLParser*)parser parseErrorOccurred:(NSError*)parseError
{
    NSLog(@"%@", [parseError description]);
}

- (void) parser:(NSXMLParser*)parser didStartElement:(NSString*)elementName namespaceURI:(NSString*)namespaceURI qualifiedName:(NSString*)qName attributes:(NSDictionary*)attributeDict
{
    if ([elementName isEqualToString:@"AircraftReport"])
    {
        currentPlacemark = [[NSMutableDictionary alloc] init];
    }
    else
    {
        currentName = elementName;
        currentString = [[NSMutableString alloc] init];
    }
}

- (void) parser:(NSXMLParser*)parser didEndElement:(NSString*)elementName namespaceURI:(NSString*)namespaceURI qualifiedName:(NSString*)qName
{
    if ([elementName isEqualToString:@"AircraftReport"])
    {
        [self addCurrentPlacemark];
        currentPlacemark = nil;
    }
    else if (currentName != nil && currentString != nil)
    {
        [currentPlacemark setObject:currentString forKey:currentName];
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
    [self performSelectorOnMainThread:@selector(addPlacemarksOnMainThread:)
                           withObject:nil
                        waitUntilDone:NO];
}

- (void) addPlacemarksOnMainThread:(id)object
{
    @try
    {
        [self addRenderables:placemarks];

        placemarks = nil; // placemark list is needed only during parsing

        // Redraw in case the layer was enabled before all the placemarks were loaded.
        NSNotification* redrawNotification = [NSNotification notificationWithName:WW_REQUEST_REDRAW object:self];
        [[NSNotificationCenter defaultCenter] postNotification:redrawNotification];
    }
    @catch (NSException* exception)
    {
        WWLogE(@"Adding PIREP data to layer", exception);
    }
}

- (void) addCurrentPlacemark
{
    WWPosition* position = [self parseCoordinates];
    WWPointPlacemark* pointPlacemark = [[WWPointPlacemark alloc] initWithPosition:position];
    [pointPlacemark setAltitudeMode:WW_ALTITUDE_MODE_CLAMP_TO_GROUND];
    [pointPlacemark setUserObject:currentPlacemark];

    NSString* name = [currentPlacemark objectForKey:@"observation_time"];
    if (name != nil)
    {
        [pointPlacemark setDisplayName:name];
    }

    WWPointPlacemarkAttributes* attrs = [[WWPointPlacemarkAttributes alloc] init];
    [attrs setImagePath:iconFilePath];
    [pointPlacemark setAttributes:attrs];

    if (placemarks == nil)
    {
        placemarks = [[NSMutableArray alloc] init];
    }
    [placemarks addObject:pointPlacemark];
}

- (WWPosition*) parseCoordinates
{
    NSString* latString = [currentPlacemark objectForKey:@"latitude"];
    NSString* lonString = [currentPlacemark objectForKey:@"longitude"];

    double lat = [latString doubleValue];
    double lon = [lonString doubleValue];

    return [[WWPosition alloc] initWithDegreesLatitude:lat longitude:lon altitude:0];
}

@end