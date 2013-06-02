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
#import "WorldWind/Util/WWMath.h"

@implementation WWWMSCapabilities

- (WWWMSCapabilities*) initWithCapabilitiesDictionary:(NSDictionary*)dictionary
{
    self = [super init];

    _root = dictionary;

    return self;
}

- (WWWMSCapabilities*) initWithServiceAddress:(NSString*)serverAddress
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

    _serviceAddress = serverAddress;

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
        WWLog(@"Unable to download WMS capabilities for %@", _serviceAddress);
        finished(nil);
        return;
    }

    [self parseDoc:[retriever retrievedData] pathForLogMessage:_serviceAddress];
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

- (WWSector*) layerGeographicBoundingBox:(NSDictionary*)layerCaps
{
    NSString* layerName = [WWWMSCapabilities layerName:layerCaps];
    if (layerName == nil)
        return nil;

    NSArray* rootLayers = [self layers];
    if (rootLayers == nil)
        return nil;

    // EX_GeographicBoundingBox elements can be inherited, with descendant bounding boxes replacing that of an
    // ancestor. So get a path to the layer and search it from bottom to top order to find the first layer that
    // specifies an EX_GeographicBoundingBox.

    NSMutableArray* pathToLayer = [[NSMutableArray alloc] init];
    for (NSDictionary* layer in rootLayers)
    {
        if ([self makePathToLayer:layer layerToFind:layerCaps path:pathToLayer])
            break;
    }
    if ([pathToLayer count] == 0)
    {
        return nil;
    }

    NSDictionary* bbox = nil;
    for (int i = [pathToLayer count] - 1; i >= 0; i--)
    {
        bbox = [[pathToLayer objectAtIndex:(NSUInteger)i] objectForKey:@"ex_geographicboundingbox"];
        if (bbox != nil)
            break;
    }
    if (bbox == nil)
    {
        return nil;
    }

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

- (NSString*) serviceWMSVersion
{
    NSString* version = [_root objectForKey:@"version"];

    return (version != nil && [version length] > 0) ? version : @"1.3.0";
}

- (NSString*) serviceContactOrganization
{
    NSDictionary* element = [[_root objectForKey:@"service"] objectForKey:@"contactinformation"];
    if (element == nil)
        return nil;

    element = [element objectForKey:@"contactpersonprimary"];
    if (element == nil)
        return nil;

    element = [element objectForKey:@"contactorganization"];
    if (element == nil)
        return nil;

    return [element objectForKey:@"characters"];
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
        return;
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

- (NSArray*) getMapFormats
{
    NSDictionary* element = [_root objectForKey:@"capability"];
    element = [element objectForKey:@"request"];
    element = [element objectForKey:@"getmap"];


    NSArray* formats = [element objectForKey:@"format"];
    if (formats == nil || [formats count] == 0)
        return nil;

    NSMutableArray* result = [[NSMutableArray alloc] initWithCapacity:[formats count]];

    for (NSDictionary* format in formats)
    {
        NSString* formatString = [format objectForKey:@"characters"];
        if (formatString != nil && [formatString length] > 0)
        {
            [result addObject:[formatString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]]];
        }
    }

    return result;
}

- (NSArray*) layerCoordinateSystems:(NSDictionary*)layerCaps
{
    if (layerCaps == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Layer capabilities is nil")
    }

    NSArray* rootLayers = [[_root objectForKey:@"capability"] objectForKey:@"layer"];
    if (rootLayers == nil)
    {
        return nil;
    }

    // Coordinate systems are inherited, so get a path to the layer then traverse that path to collect all the
    // coordinate systems defined in each ancestor layer and the target layer, itself.

    NSMutableArray* pathToLayer = [[NSMutableArray alloc] init];
    for (NSDictionary* layer in rootLayers)
    {
        if ([self makePathToLayer:layer layerToFind:layerCaps path:pathToLayer])
            break;
    }
    if ([pathToLayer count] == 0)
    {
        return nil;
    }

    // WMS 1.1 coordinate system elements are named "SRS", whereas 1.3 are named "CRS".
    NSComparisonResult order = [[self serviceWMSVersion] compare:@"1.3.0"];
    NSString* crsName = order == NSOrderedAscending ? @"srs" : @"crs";

    NSMutableSet* csList = [[NSMutableSet alloc] init];
    for (NSDictionary* layer in pathToLayer)
    {
        NSArray* layersCoordSystemList = [layer objectForKey:crsName];
        if (layersCoordSystemList != nil)
        {
            for (NSDictionary* coordSystemElement in layersCoordSystemList)
            {
                NSString* cs = [coordSystemElement objectForKey:@"characters"];
                if (cs != nil && [cs length] > 0)
                {
                    [csList addObject:cs];
                }
            }
        }
    }

    return [csList allObjects];
}

- (BOOL) makePathToLayer:(NSDictionary*)layerCaps layerToFind:(NSDictionary*)layerToFind path:(NSMutableArray*)path
{
    if (layerCaps == layerToFind)
    {
        [path addObject:layerCaps];
        return YES;
    }

    NSArray* layers = [WWWMSCapabilities layers:layerCaps];
    if (layers == nil || [layers count] == 0)
        return NO;

    [path addObject:layerCaps];
    for (NSDictionary* childLayer in layers)
    {
        if ([self makePathToLayer:childLayer layerToFind:layerToFind path:path])
        {
            return YES;
        }
    }
    [path removeLastObject];

    return NO;
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

+ (BOOL) layerIsOpaque:(NSDictionary*)layerCaps
{
    if (layerCaps == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Layer capabilities is nil")
    }

    NSString* opaque = [layerCaps objectForKey:@"opaque"];

    return opaque != nil && [opaque isEqualToString:@"1"];
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

    double latMin = [minLat doubleValue];
    double latMax = [maxLat doubleValue];
    double lonMin = [minLon doubleValue];
    double lonMax = [maxLon doubleValue];

    // Some servers return bounding boxes that are just slightly outside the normal bounds, e.g., 180.0000000001.
    // Clamp such values to be in range.
    return [[WWSector alloc] initWithDegreesMinLatitude:[WWMath clampValue:latMin min:-90 max:90]
                                            maxLatitude:[WWMath clampValue:latMax min:-90 max:90]
                                           minLongitude:[WWMath clampValue:lonMin min:-180 max:180]
                                           maxLongitude:[WWMath clampValue:lonMax min:-180 max:180]];
}

+ (NSArray*) layerDataURLs:(NSDictionary*)layerCaps
{
    if (layerCaps == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Layer capabilities is nil")
    }

    NSArray* dataURLs = [layerCaps objectForKey:@"dataurl"];
    if (dataURLs == nil || [dataURLs count] == 0)
        return nil;

    NSMutableArray* urls = [[NSMutableArray alloc] initWithCapacity:[dataURLs count]];
    for (NSDictionary* dataURL in dataURLs)
    {
        NSDictionary* orl = [dataURL objectForKey:@"onlineresource"];
        if (orl == nil)
            continue;

        NSString* url = [orl objectForKey:@"href"];
        if (url == nil)
        {
            url = [orl objectForKey:@"xlink:href"];
        }

        if (url != nil && [url length] > 0)
        {
            [urls addObject:url];
        }
    }

    return [urls count] > 0 ? urls : nil;
}

+ (NSArray*) layerMetadataURLs:(NSDictionary*)layerCaps
{
    NSArray* dataURLs = [layerCaps objectForKey:@"metadataurl"];
    if (dataURLs == nil || [dataURLs count] == 0)
        return nil;

    NSMutableArray* urls = [[NSMutableArray alloc] initWithCapacity:[dataURLs count]];
    for (NSDictionary* dataURL in dataURLs)
    {
        NSDictionary* orl = [dataURL objectForKey:@"onlineresource"];
        if (orl == nil)
            continue;

        NSString* url = [orl objectForKey:@"href"];
        if (url == nil)
        {
            url = [orl objectForKey:@"xlink:href"];
        }

        if (url != nil && [url length] > 0)
        {
            [urls addObject:url];
        }
    }

    return [urls count] > 0 ? urls : nil;
}

+ (NSArray*) layerKeywords:(NSDictionary*)layerCaps
{
    if (layerCaps == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Layer capabilities is nil")
    }

    NSMutableDictionary* keywordListElement = [layerCaps objectForKey:@"keywordlist"];
    if (keywordListElement != nil)
    {
        NSMutableArray* keywordsOut = [[NSMutableArray alloc] init];

        NSArray* keywordElementList = [keywordListElement objectForKey:@"keyword"];
        if (keywordElementList != nil)
        {
            for (NSDictionary* keywordElement in keywordElementList)
            {
                NSString* keyword = [keywordElement objectForKey:@"characters"];
                if (keyword != nil)
                {
                    [keywordsOut addObject:keyword];
                }
            }
        }

        return [keywordsOut count] > 0 ? keywordsOut : nil;
    }

    return nil;
}

+ (NSNumber*) layerMinScaleDenominator:(NSDictionary*)layerCaps
{
    NSDictionary* minScale = [layerCaps objectForKey:@"minscaledenominator"];
    if (minScale == nil)
        return nil;

    NSString* numberString = [minScale objectForKey:@"characters"];
    if (numberString == nil || [numberString length] == 0)
        return nil;

    return [[NSNumber alloc] initWithDouble:[numberString doubleValue]];
}

+ (NSNumber*) layerMaxScaleDenominator:(NSDictionary*)layerCaps
{
    NSDictionary* minScale = [layerCaps objectForKey:@"maxscaledenominator"];
    if (minScale == nil)
        return nil;

    NSString* numberString = [minScale objectForKey:@"characters"];
    if (numberString == nil || [numberString length] == 0)
        return nil;

    return [[NSNumber alloc] initWithDouble:[numberString doubleValue]];
}

@end