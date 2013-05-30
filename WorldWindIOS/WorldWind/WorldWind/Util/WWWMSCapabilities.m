/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import <Foundation/Foundation.h>
#import "WorldWind/Util/WWWMSCapabilities.h"
#import "WorldWind/WWLog.h"
#import "WorldWind/Util/WWXMLParser.h"
#import "WorldWind/Geometry/WWSector.h"
#import "WorldWind/WorldWindConstants.h"
#import "WorldWind/Util/WWRetriever.h"

@implementation WWWMSCapabilities

- (WWWMSCapabilities*) initWithCapabilitiesDictionary:(NSDictionary*)dictionary
{
    self = [super init];

    _root = dictionary;

    return self;
}

- (WWWMSCapabilities*) initWithServerAddress:(NSString*)serverAddress
{
    if (serverAddress == nil || [serverAddress length] == 0)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Server address is nil or empty")
    }

    self = [super init];

    _serverAddress = serverAddress;

    NSString* fullUrlString = [self composeRequestString:serverAddress];
    NSURL* url = [[NSURL alloc] initWithString:fullUrlString];

    WWRetriever* retriever = [[WWRetriever alloc] initWithUrl:url timeout:10
                                                finishedBlock:^(WWRetriever* myRetriever)
                                                {
                                                    [self parseCapabilities:myRetriever];
                                                }];
    [retriever performRetrieval];

    return self;
}

- (WWWMSCapabilities*) initWithServerAddress:(NSString*)serverAddress
                               finishedBlock:(void (^)(WWWMSCapabilities*))finishedBlock
{
    if (serverAddress == nil || [serverAddress length] == 0)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Server address is nil or empty")
    }

    if (finishedBlock == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Finish block is nil")
    }

    self = [super init];

    _serverAddress = serverAddress;

    finished = finishedBlock;

    NSString* fullUrlString = [self composeRequestString:serverAddress];
    NSURL* url = [[NSURL alloc] initWithString:fullUrlString];

    WWRetriever* retriever = [[WWRetriever alloc] initWithUrl:url timeout:10
                                              finishedBlock:^(WWRetriever* myRetriever)
                                              {
                                                  [self parseCapabilities:myRetriever];
                                              }];
    [retriever performRetrieval];

    return self;
}

- (void) parseCapabilities:(WWRetriever*)retriever
{
    if (![[retriever status] isEqualToString:WW_SUCCEEDED] || [[retriever retrievedData] length] == 0)
    {
        WWLog(@"Unable to download WMS capabilities for %@", [self serverAddress]);
        return;
    }

    [self parseDoc:[retriever retrievedData] pathForLogMessage:[self serverAddress]];
    finished(_root != nil ? self : nil);
}

- (WWWMSCapabilities*) initWithCapabilitiesFile:(NSString*)filePath
{
    if (filePath == nil || [filePath length] == 0)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Capabilities file path is nil or empty")
    }

    self = [super init];

    NSData* data = [[NSData alloc] initWithContentsOfFile:filePath];
    if (data == nil)
    {
        WWLog(@"Unable to read WMS capabilities document from file %@", filePath);
        return nil;
    }

    [self parseDoc:data pathForLogMessage:filePath];

    return _root != nil ? self : nil;
}

- (void) parseDoc:(NSData*)data pathForLogMessage:(NSString*)pathForLogMessage
{
    // These are the names of WMS Capabilities elements that may contain multiple elements of the same type. They
    // are captured in an array and the array is attached to the parent element's dictionary using the same name as
    // the child element.
    NSSet* listElements = [[NSSet alloc] initWithObjects:
            @"layer", @"format", @"crs", @"srs", @"keyword", @"style", @"metadataurl", @"boundingbox",
            @"dimension", @"authorityurl", @"identifier", @"dataurl", @"featurelisturl", @"legendurl",
            @"serviceexceptiontype", @"extendedcapabilities", @"_extendedoperation", @"dcptype", nil];

    WWXMLParser* parser = [[WWXMLParser alloc] initWithData:data listElementNames:listElements];
    if (parser == nil)
    {
        WWLog(@"WMS Capabilities parsing failed for %@", pathForLogMessage);
        return;
    }

    _root = [parser root];

    // Verify that it is indeed a WMS capabilities document.
    NSString* rootElementName = [_root objectForKey:@"elementname"];
    if (!([rootElementName isEqualToString:@"wms_capabilities"]
            || [rootElementName isEqualToString:@"wmt_ms_capabilities"]))
    {
        WWLog(@"Not a WMS Capabilities document %@", pathForLogMessage);
        _root = nil;
    }
}

- (NSString*) composeRequestString:(NSString*)serverAddress
{
    NSMutableString* urls = [[NSMutableString alloc] init];

    if (!([serverAddress hasPrefix:@"http"] || [serverAddress hasPrefix:@"https"]))
    {
        [urls appendString:@"http://"];
    }

    [urls appendString:serverAddress];

    NSRange range = [serverAddress rangeOfString:@"?"];
    if (range.location == NSNotFound)
    {
        [urls appendString:@"?"];
    }
    else
    {
        if (![serverAddress hasSuffix:@"?"])
        {
            [urls appendString:@"&"];
        }
    }

    [urls appendString:@"service=WMS&request=GetCapabilities"];

    return urls;
}

- (WWSector*) geographicBoundingBoxForNamedLayer:(NSDictionary*)layerCapabilities
{
    NSString* layerName = [WWWMSCapabilities layerName:layerCapabilities];
    if (layerName == nil)
        return nil;

    NSArray* rootLayers = [self layers];
    if (rootLayers == nil)
        return nil;

    NSDictionary* bbox = [self doFindGeographicBoundingBoxForNamedLayer:rootLayers
                                                              layerName:layerName
                                                            ancestorBox:nil];
    if (bbox == nil)
        return nil;

    return [WWWMSCapabilities makeGeographicBoundingBox:bbox];
}

- (NSDictionary*) doFindGeographicBoundingBoxForNamedLayer:(NSArray*)layerElements
                                                 layerName:(NSString*)layerName
                                               ancestorBox:(NSDictionary*)ancestorBox
{
    for (NSMutableDictionary* layerElement in layerElements)
    {
        NSDictionary* geographicBoundingBox = [layerElement objectForKey:@"ex_geographicboundingbox"];
        if (geographicBoundingBox == nil && ancestorBox != nil)
        {
            geographicBoundingBox = ancestorBox;
        }

        NSString* lname = [WWWMSCapabilities layerName:layerElement];
        if (lname != nil && [lname isEqualToString:layerName])
        {
            return geographicBoundingBox;
        }

        NSArray* subLayers = [layerElement objectForKey:@"layer"];
        if (subLayers != nil)
        {
            NSDictionary* bbox = [self doFindGeographicBoundingBoxForNamedLayer:subLayers
                                                                      layerName:layerName
                                                                    ancestorBox:geographicBoundingBox];
            if (bbox != nil)
                return bbox;
        }
    }

    return nil;
}

- (NSString*) serviceTitle
{
    NSDictionary* titleDict = [[_root objectForKey:@"service"] objectForKey:@"title"];

    return titleDict != nil ? [titleDict objectForKey:@"characters"] : nil;
}

- (NSString*) serviceName
{
    NSDictionary* titleDict = [[_root objectForKey:@"service"] objectForKey:@"name"];

    return titleDict != nil ? [titleDict objectForKey:@"characters"] : nil;
}

- (NSString*) serviceAbstract
{
    NSDictionary* abstract = [[_root objectForKey:@"service"] objectForKey:@"abstract"];

    return abstract != nil ? [abstract objectForKey:@"characters"] : nil;
}

- (NSString*) serverWMSVersion
{
    return [_root objectForKey:@"version"];
}

- (NSArray*) layers
{
    return [[_root objectForKey:@"capability"] objectForKey:@"layer"];
}

- (NSArray*) namedLayers
{
    NSArray* rootLayers = [[_root objectForKey:@"capability"] objectForKey:@"layer"];
    if (rootLayers == nil)
    {
        return nil;
    }

    NSMutableArray* layerList = [[NSMutableArray alloc] init];

    for (NSMutableDictionary* layer in rootLayers)
    {
        [self doGetNamedLayers:layer layerList:layerList];
    }

    return layerList;
}

- (void) doGetNamedLayers:(NSMutableDictionary*)layer layerList:(NSMutableArray*)layerList
{
    if (layer == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Layer is nil")
    }

    if (layerList == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Layer list is nil")
    }

    if ([layer objectForKey:@"name"] != nil)
    {
        [layerList addObject:layer];
    }

    NSArray* layers = [layer objectForKey:@"layer"];
    if (layers != nil)
    {
        for (NSMutableDictionary* childLayer in layers)
        {
            [self doGetNamedLayers:childLayer layerList:layerList];
        }
    }
}

- (NSDictionary*) namedLayer:(NSString*)layerName
{
    if (layerName == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Layer name is nil")
    }

    NSArray* namedLayers = [self namedLayers];
    if (namedLayers != nil)
    {
        for (NSDictionary* layerCaps in namedLayers)
        {
            NSString* name = [WWWMSCapabilities layerName:layerCaps];
            if ([name isEqualToString:layerName])
            {
                return layerCaps;
            }
        }
    }

    return nil;
}

- (NSString*) getMapURL
{
    NSDictionary* element = [_root objectForKey:@"capability"];
    element = [element objectForKey:@"request"];
    element = [element objectForKey:@"getmap"];

    NSArray* dcpTypes = [element objectForKey:@"dcptype"];
    for (NSDictionary* dict in dcpTypes)
    {
        element = [dict objectForKey:@"http"];
        if (element != nil)
        {
            element = [element objectForKey:@"get"];
            element = [element objectForKey:@"onlineresource"];
            break;
        }
    }

    NSString* url = [element objectForKey:@"href"];
    if (url == nil)
    {
        url = [element objectForKey:@"xlink:href"];
    }

    return url;
}

+ (NSString*) layerName:(NSDictionary*)layerCaps
{
    if (layerCaps == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Layer capabilities is nil")
    }

    NSDictionary* name = [layerCaps objectForKey:@"name"];
    if (name != nil)
    {
        return [name objectForKey:@"characters"];
    }

    return nil;
}

+ (NSString*) layerAbstract:(NSDictionary*)layerCaps
{
    if (layerCaps == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Layer capabilities is nil")
    }

    NSDictionary* abstract = [layerCaps objectForKey:@"abstract"];
    if (abstract != nil)
    {
        return [abstract objectForKey:@"characters"];
    }

    return nil;
}

+ (NSString*) layerTitle:(NSDictionary*)layerCaps
{
    if (layerCaps == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Layer capabilities is nil")
    }

    NSDictionary* name = [layerCaps objectForKey:@"title"];
    if (name != nil)
    {
        return [name objectForKey:@"characters"];
    }

    return nil;
}

+ (NSArray*) layers:(NSDictionary*)layerCaps
{
    return [layerCaps objectForKey:@"layer"];
}

+ (NSDate*) layerLastUpdateTime:(NSDictionary*)layerCaps
{
    if (layerCaps == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Layer capabilities is nil")
    }

    // Search for a keyword with the pattern "LastUpdate=yyyy-MM-dd'T'HH:mm:ssZ".

    NSMutableDictionary* keywordListElement = [layerCaps objectForKey:@"keywordlist"];
    if (keywordListElement != nil)
    {
        NSArray* keywordElementList = [keywordListElement objectForKey:@"keyword"];
        if (keywordElementList != nil)
        {
            for (NSDictionary* keywordElement in keywordElementList)
            {
                NSString* characters = [keywordElement objectForKey:@"characters"];
                if ([characters hasPrefix:@"LastUpdate="])
                {
                    NSArray* splitString = [characters componentsSeparatedByString:@"="];
                    if ([splitString count] == 2)
                    {
                        NSString* dateString = [splitString objectAtIndex:1];
                        NSDateFormatter* formatter = [[NSDateFormatter alloc] init];

                        [formatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ssZ"];
                        dateString = [dateString stringByReplacingOccurrencesOfString:@"Z" withString:@"-0000"];
                        return [formatter dateFromString:dateString];
                    }
                }
            }
        }
    }

    return nil;
}

+ (WWSector*) makeGeographicBoundingBox:(NSDictionary*)boundingBoxElement
{
    NSDictionary* wbl = [boundingBoxElement objectForKey:@"westboundlongitude"];
    NSDictionary* ebl = [boundingBoxElement objectForKey:@"eastboundlongitude"];
    NSDictionary* sbl = [boundingBoxElement objectForKey:@"southboundlatitude"];
    NSDictionary* nbl = [boundingBoxElement objectForKey:@"northboundlatitude"];

    if (wbl == nil || ebl == nil || sbl == nil || nbl == nil)
        return nil;

    NSString* minLon = [wbl objectForKey:@"characters"];
    NSString* maxLon = [ebl objectForKey:@"characters"];
    NSString* minLat = [sbl objectForKey:@"characters"];
    NSString* maxLat = [nbl objectForKey:@"characters"];

    if (minLon == nil || maxLon == nil || minLat == nil || maxLat == nil)
        return nil;

    return [[WWSector alloc] initWithDegreesMinLatitude:[minLat doubleValue]
                                            maxLatitude:[maxLat doubleValue]
                                           minLongitude:[minLon doubleValue]
                                           maxLongitude:[maxLon doubleValue]];
}

@end