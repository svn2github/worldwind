/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import "WeatherCamLayer.h"
#import "WWRetriever.h"
#import "WorldWindConstants.h"
#import "WWLog.h"
#import "WorldWind.h"
#import "WWPosition.h"
#import "WWPointPlacemark.h"
#import "WWPointPlacemarkAttributes.h"


@interface WeatherCamLayerRetriever : NSOperation
@end

@implementation WeatherCamLayerRetriever
{
    NSString* urlString;
    WeatherCamLayer* layer;
}

- (WeatherCamLayerRetriever*) initWithUrl:(NSString*)url layer:(WeatherCamLayer*)metarLayer
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
        NSString* cachePath = [cacheDir stringByAppendingPathComponent:@"weathercams"];
        NSString* filePath = [cachePath stringByAppendingPathComponent:@"weathercamsites.xml"];

        NSData* data = nil;

        if (![[retriever status] isEqualToString:WW_SUCCEEDED] || [[retriever retrievedData] length] == 0)
        {
            // Use the previous copy if one is available.
            data = [[NSData alloc] initWithContentsOfFile:filePath];
        }
        else
        {
            [[NSFileManager defaultManager] createDirectoryAtPath:cachePath
                                      withIntermediateDirectories:YES attributes:nil error:&error];
            if (error != nil)
            {
                WWLog("@Error \"%@\" creating Weather Cam cache directory %@", [error description], cachePath);
            }
            else
            {
                // Save this fresh copy so the data is available while off-line.
                [[retriever retrievedData] writeToFile:filePath atomically:YES];
            }

            data = [retriever retrievedData];
        }

        if (data == nil || [data length] == 0)
            return;

        NSXMLParser* docParser = [[NSXMLParser alloc] initWithData:data];
        [docParser setDelegate:layer];

        BOOL status = [docParser parse];
        if (status == NO)
        {
            WWLog(@"Weather Cam data parsing failed");
        }
    }
    @catch (NSException* exception)
    {
        WWLogE(@"Exception loading Weather Cam data", exception);
    }
}

@end

@implementation WeatherCamLayer
{
    NSMutableDictionary* currentPlacemarkDict;
    NSDictionary* currentAttributesDict;
    NSString* currentName;
    NSMutableString* currentString;
    NSMutableArray* placemarks;
    NSString* iconFilePath;
}

- (WeatherCamLayer*) init
{
    self = [super init];

    [self setDisplayName:@"Weather Cams"];

    iconFilePath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"slr_camera.png"];

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
    NSString* urlString = @"http://worldwindserver.net/taiga/cameras/sites-update.xml";
    WeatherCamLayerRetriever* retriever = [[WeatherCamLayerRetriever alloc] initWithUrl:urlString layer:self];
    [[WorldWind loadQueue] addOperation:retriever];
}

- (void) parser:(NSXMLParser*)parser parseErrorOccurred:(NSError*)parseError
{
    NSLog(@"%@", [parseError description]);
}

- (void) parser:(NSXMLParser*)parser didStartElement:(NSString*)elementName namespaceURI:(NSString*)namespaceURI qualifiedName:(NSString*)qName attributes:(NSDictionary*)attributeDict
{
    if ([elementName isEqualToString:@"sites"])
    {
        currentPlacemarkDict = [[NSMutableDictionary alloc] init];
    }
    else
    {
        currentName = elementName;
        currentString = [[NSMutableString alloc] init];
        currentAttributesDict = attributeDict;
    }
}

- (void) parser:(NSXMLParser*)parser didEndElement:(NSString*)elementName namespaceURI:(NSString*)namespaceURI qualifiedName:(NSString*)qName
{
    if ([elementName isEqualToString:@"sites"])
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
    currentAttributesDict = nil;
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

        [[NSNotificationCenter defaultCenter] postNotificationName:WW_REFRESH_COMPLETE object:self];

        // Redraw in case the layer was enabled before all the placemarks were loaded.
        NSNotification* redrawNotification = [NSNotification notificationWithName:WW_REQUEST_REDRAW object:self];
        [[NSNotificationCenter defaultCenter] postNotification:redrawNotification];
    }
    @catch (NSException* exception)
    {
        WWLogE(@"Adding Weather Cam data to layer", exception);
    }
}

- (void) addCurrentPlacemark
{
    WWPosition* position = [self parseCoordinates];
    WWPointPlacemark* pointPlacemark = [[WWPointPlacemark alloc] initWithPosition:position];
    [pointPlacemark setAltitudeMode:WW_ALTITUDE_MODE_CLAMP_TO_GROUND];
    [pointPlacemark setUserObject:currentPlacemarkDict];

    NSString* name = [currentPlacemarkDict objectForKey:@"siteName"];
    if (name != nil)
    {
        [pointPlacemark setDisplayName:name];
    }

    WWPointPlacemarkAttributes* attrs = [[WWPointPlacemarkAttributes alloc] init];
    [attrs setImagePath:iconFilePath];
    [attrs setImageScale:0.25];
    [pointPlacemark setAttributes:attrs];

    if (placemarks == nil)
    {
        placemarks = [[NSMutableArray alloc] init];
    }
    [placemarks addObject:pointPlacemark];
}

- (WWPosition*) parseCoordinates
{
    NSString* latString = [currentPlacemarkDict objectForKey:@"siteLatitude"];
    NSString* lonString = [currentPlacemarkDict objectForKey:@"siteLongitude"];

    double lat = [latString doubleValue];
    double lon = [lonString doubleValue];

    return [[WWPosition alloc] initWithDegreesLatitude:lat longitude:lon altitude:0];
}

@end