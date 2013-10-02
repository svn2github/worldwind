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
            WWLog(@"Unable to download METAR data %@", [[retriever url] absoluteString]);

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

- (METARLayer*) init
{
    self = [super init];

    [self setDisplayName:@"METAR Weather"];

    iconFilePath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"weather32x32.png"];

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
    NSString* urlString = @"http://weather.aero/dataserver_current/httpparam?dataSource=metars&requestType=retrieve&format=xml&stationString=PA*&hoursBeforeNow=1";
    METARLayerRetriever* retriever = [[METARLayerRetriever alloc] initWithUrl:urlString layer:self];
    [[WorldWind loadQueue] addOperation:retriever];
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
        // There can be multiple sky_condition elements, so capture them in an array.

        NSMutableString* cover = [[NSMutableString alloc] initWithString:[attributeDict objectForKey:@"sky_cover"]];
        NSString* cloud_bases = [attributeDict objectForKey:@"cloud_base_ft_agl"];
        if (cloud_bases != nil)
            [cover appendFormat:@" @ %@ meters AGL", cloud_bases];

        NSMutableArray* skyCovers = [currentPlacemarkDict objectForKey:@"sky_conditions"];
        if (skyCovers == nil)
        {
            skyCovers = [[NSMutableArray alloc] initWithCapacity:1];
            [currentPlacemarkDict setObject:skyCovers forKey:@"sky_conditions"];
        }

        [skyCovers addObject:cover];
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
        WWLogE(@"Adding METAR data to layer", exception);
    }
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
    NSString* latString = [currentPlacemarkDict objectForKey:@"latitude"];
    NSString* lonString = [currentPlacemarkDict objectForKey:@"longitude"];

    double lat = [latString doubleValue];
    double lon = [lonString doubleValue];

    return [[WWPosition alloc] initWithDegreesLatitude:lat longitude:lon altitude:0];
}

@end