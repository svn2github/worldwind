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
    if (![[retriever status] isEqualToString:WW_SUCCEEDED] || [[retriever retrievedData] length] == 0)
    {
        WWLog(@"Unable to download METAR data %@", [[retriever url] absoluteString]);
        return;
    }

    @try
    {
        NSXMLParser* docParser = [[NSXMLParser alloc] initWithData:[retriever retrievedData]];
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
    placemarks = [[NSMutableArray alloc] init];

    // Retrieve the data on a separate thread because it takes a while to download and parse.
    NSString* urlString = @"http://weather.aero/dataserver_current/httpparam?dataSource=metars&requestType=retrieve&format=xml&stationString=PA*&hoursBeforeNow=1";
    METARLayerRetriever* retriever = [[METARLayerRetriever alloc] initWithUrl:urlString layer:self];
    [[WorldWind loadQueue] addOperation:retriever];

    return self;
}

- (void) parser:(NSXMLParser*)parser parseErrorOccurred:(NSError*)parseError
{
    NSLog(@"%@", [parseError description]);
}

- (void) parser:(NSXMLParser*)parser didStartElement:(NSString*)elementName namespaceURI:(NSString*)namespaceURI qualifiedName:(NSString*)qName attributes:(NSDictionary*)attributeDict
{
    if ([elementName isEqualToString:@"METAR"])
    {
        currentPlacemark = [[NSMutableDictionary alloc] init];
    }
    else if ([elementName isEqualToString:@"sky_condition"])
    {
        NSMutableString* cover = [[NSMutableString alloc] initWithString:[attributeDict objectForKey:@"sky_cover"]];
        NSString* cloud_bases = [attributeDict objectForKey:@"cloud_base_ft_agl"];
        if (cloud_bases != nil)
            [cover appendFormat:@" @ %@ meters AGL", cloud_bases];

        NSMutableArray* skyCovers = [currentPlacemark objectForKey:@"sky_conditions"];
        if (skyCovers == nil)
        {
            skyCovers = [[NSMutableArray alloc] initWithCapacity:1];
            [currentPlacemark setObject:skyCovers forKey:@"sky_conditions"];
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
    [self addRenderables:placemarks];

    placemarks = nil; // placemark list is needed only during parsing

    // Redraw in case the layer was enabled before all the placemarks were loaded.
    NSNotification* redrawNotification = [NSNotification notificationWithName:WW_REQUEST_REDRAW object:self];
    [[NSNotificationCenter defaultCenter] postNotification:redrawNotification];
}

- (void) addCurrentPlacemark
{
    WWPosition* position = [self parseCoordinates];
    WWPointPlacemark* pointPlacemark = [[WWPointPlacemark alloc] initWithPosition:position];
    [pointPlacemark setAltitudeMode:WW_ALTITUDE_MODE_CLAMP_TO_GROUND];
    [pointPlacemark setUserObject:currentPlacemark];

    NSString* name = [currentPlacemark objectForKey:@"station_id"];
    if (name != nil)
    {
        [pointPlacemark setDisplayName:name];
    }

    WWPointPlacemarkAttributes* attrs = [[WWPointPlacemarkAttributes alloc] init];
    [attrs setImagePath:iconFilePath];
    [pointPlacemark setAttributes:attrs];

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