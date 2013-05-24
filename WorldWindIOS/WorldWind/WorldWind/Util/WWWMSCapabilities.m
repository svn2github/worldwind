/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import "WorldWind/Util/WWWMSCapabilities.h"
#import "WorldWind/Util/WWUtil.h"
#import "WorldWind/WWLog.h"
#import "WorldWind/Util/WWXMLParser.h"

@implementation WWWMSCapabilities

- (WWWMSCapabilities*) initWithServerAddress:(NSString*)serverAddress
{
    if (serverAddress == nil || [serverAddress length] == 0)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Server address is nil or empty")
    }

    self = [super init];

    NSString* fullUrlString = [self composeRequestString:serverAddress];
    NSURL* url = [[NSURL alloc] initWithString:fullUrlString];

    NSData* data = [WWUtil retrieveUrl:url timeout:10];
    if (data == nil)
    {
        WWLog(@"Unable to download WMS capabilities document with request URL %@", [url absoluteString]);
        return nil;
    }

    [self parseDoc:data pathForLogMessage:serverAddress];

    return _root != nil ? self : nil;
}

- (WWWMSCapabilities*)initWithCapabilitiesFile:(NSString*)filePath
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

    return self;
}

- (void)parseDoc:(NSData*)data pathForLogMessage:(NSString*)pathForLogMessage
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
}

- (NSString*) composeRequestString:(NSString*)serverAddress
{
    NSMutableString* urls = [[NSMutableString alloc] init];

    if (!([serverAddress hasPrefix:@"http"] || [serverAddress hasPrefix:@"https"]))
    {
        [urls appendString:@"http://"];
    }

    [urls appendString:serverAddress];

    if (![serverAddress hasSuffix:@"?"])
    {
        [urls appendString:@"?"];
    }

    [urls appendString:@"service=WMS&request=GetCapabilities"];

    return urls;
}

- (NSArray*)namedLayers
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
            NSString* name = [self layerName:layerCaps];
            if ([name isEqualToString:layerName])
            {
                return layerCaps;
            }
        }
    }

    return nil;
}

- (NSString*)layerName:(NSDictionary*)layerCaps
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

- (NSDate*) layerLastUpdateTime:(NSDictionary*)layerCaps
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
                if ([characters hasSuffix:@"LastUpdate="])
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

@end