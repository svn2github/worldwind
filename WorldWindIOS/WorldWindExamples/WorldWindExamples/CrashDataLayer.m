/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import "CrashDataLayer.h"
#import "WorldWind/Geometry/WWPosition.h"
#import "WorldWind/Shapes/WWPointPlacemark.h"
#import "WorldWind/Shapes/WWPointPlacemarkAttributes.h"
#import "WorldWind/Util/WWRetriever.h"
#import "WorldWind/WorldWind.h"
#import "WorldWind/WorldWindView.h"

@interface CrashDataLayerRetriever : NSOperation
@end

@implementation CrashDataLayerRetriever
{
    NSString* urlString;
    CrashDataLayer* layer;
}

- (CrashDataLayerRetriever*)initWithUrl:(NSString*)url layer:(CrashDataLayer*)crashDataLayer
{
    self = [super init];

    urlString = url;
    layer = crashDataLayer;

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
        WWLog(@"Unable to download crash data %@", [[retriever url] absoluteString]);
        return;
    }

    @try
    {
        NSXMLParser* docParser = [[NSXMLParser alloc] initWithData:[retriever retrievedData]];
        [docParser setDelegate:layer];

        BOOL status = [docParser parse];
        if (status == NO)
        {
            WWLog(@"Crash data parsing failed");
        }
    }
    @catch (NSException* exception)
    {
        WWLogE(@"Exception loading crash data", exception);
    }
}

@end

@implementation CrashDataLayer

- (CrashDataLayer*) initWithURL:(NSString*)urlString
{
    self = [super init];

    [self setDisplayName:@"Accidents"];

    iconFilePath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"placemark_circle.png"];
    placemarks = [[NSMutableArray alloc] init];

    // Retrieve the crash data on a separate thread because it takes a while to download and parse.
    CrashDataLayerRetriever* retriever = [[CrashDataLayerRetriever alloc] initWithUrl:urlString layer:self];
    [[WorldWind loadQueue] addOperation:retriever];

    return self;
}

- (void) parser:(NSXMLParser*)parser parseErrorOccurred:(NSError*)parseError
{
    NSLog(@"%@", [parseError description]);
}

- (void) parser:(NSXMLParser*)parser didStartElement:(NSString*)elementName namespaceURI:(NSString*)namespaceURI qualifiedName:(NSString*)qName attributes:(NSDictionary*)attributeDict
{
    if ([elementName isEqualToString:@"Placemark"])
    {
        currentPlacemark = [[NSMutableDictionary alloc] init];
    }
    else if ([elementName isEqualToString:@"SimpleData"])
    {
        currentName = [attributeDict objectForKey:@"name"];
        currentString = [[NSMutableString alloc] init];
    }
    else if ([elementName isEqualToString:@"coordinates"])
    {
        currentString = [[NSMutableString alloc] init];
    }
}

- (void) parser:(NSXMLParser*)parser didEndElement:(NSString*)elementName namespaceURI:(NSString*)namespaceURI qualifiedName:(NSString*)qName
{
    if ([elementName isEqualToString:@"Placemark"])
    {
        [self addCurrentPlacemark];
        currentPlacemark = nil;
    }
    else if ([elementName isEqualToString:@"SimpleData"])
    {
        if (currentName != nil && currentString != nil)
        {
            [currentPlacemark setObject:currentString forKey:currentName];
        }

        currentName = nil;
        currentString = nil;
    }
    else if ([elementName isEqualToString:@"coordinates"])
    {
        WWPosition* position = [self parseCoordinates:currentString];
        [currentPlacemark setObject:position forKey:@"Position"];
        currentString = nil;
    }
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
    [WorldWindView requestRedraw];
}

- (WWPosition*) parseCoordinates:(NSString*)string
{
    NSArray* coords = [string componentsSeparatedByString:@","];

    double lon = [[coords objectAtIndex:0] doubleValue];
    double lat = [[coords objectAtIndex:1] doubleValue];
    double alt = [[coords objectAtIndex:2] doubleValue];

    return [[WWPosition alloc] initWithDegreesLatitude:lat longitude:lon altitude:alt];
}

- (void) addCurrentPlacemark
{
    WWPosition* position = [currentPlacemark objectForKey:@"Position"];
    WWPointPlacemark* pointPlacemark = [[WWPointPlacemark alloc] initWithPosition:position];
    [pointPlacemark setAltitudeMode:WW_ALTITUDE_MODE_CLAMP_TO_GROUND];
    [pointPlacemark setUserObject:currentPlacemark];

    NSString* name = [currentPlacemark objectForKey:@"AcftName"];
    if (name != nil)
    {
        [pointPlacemark setDisplayName:name];
    }

    WWPointPlacemarkAttributes* attrs = [[WWPointPlacemarkAttributes alloc] init];
    [attrs setImagePath:iconFilePath];
    [pointPlacemark setAttributes:attrs];

    [placemarks addObject:pointPlacemark];
}

@end