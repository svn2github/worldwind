/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import "WeatherCamLayer.h"
#import "WorldWind/Geometry/WWPosition.h"
#import "WorldWind/Shapes/WWPointPlacemark.h"
#import "WorldWind/Shapes/WWPointPlacemarkAttributes.h"
#import "WorldWind/Util/WWRetriever.h"
#import "WorldWind/WorldWind.h"
#import "WorldWind/WorldWindView.h"
#import "AppConstants.h"

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
        {
            layer.refreshInProgress = [[NSNumber alloc] initWithBool:NO];
            return;
        }

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

    layer.refreshInProgress = [[NSNumber alloc] initWithBool:NO];
}

@end

@implementation WeatherCamLayer
{
    NSMutableDictionary* currentPlacemarkDict;
    NSDictionary* currentAttributesDict;
    NSString* currentName;
    NSMutableString* currentString;
    NSMutableDictionary* sitesInfo;
    NSMutableArray* placemarks;
    NSString* iconFilePath;
}

- (WeatherCamLayer*) init
{
    self = [super init];

    [self setDisplayName:@"Weather Cams"];

    _refreshInProgress = [[NSNumber alloc] initWithBool:NO];

    iconFilePath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"slr_camera.png"];
    sitesInfo = [[NSMutableDictionary alloc] init];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleRefreshNotification:)
                                                 name:TAIGA_REFRESH
                                               object:nil];

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

- (void) handleRefreshNotification:(NSNotification*)notification
{
    if ([[notification name] isEqualToString:TAIGA_REFRESH]
            && ([notification object] == self || [notification object] == nil))
    {
        [self refreshData];
    }
}

- (void) refreshData
{
    // Retrieve the data on a separate thread because it takes a while to download and parse.
    NSString* urlString = @"http://worldwindserver.net/taiga/cameras/sites-update.xml";
    WeatherCamLayerRetriever* retriever = [[WeatherCamLayerRetriever alloc] initWithUrl:urlString layer:self];

    @synchronized (_refreshInProgress)
    {
        if ([_refreshInProgress boolValue])
            return;

        _refreshInProgress = [[NSNumber alloc] initWithBool:YES];
    }

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
        [self addCurrentCamera];

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
    [self createPlacemarks];

    [self performSelectorOnMainThread:@selector(addPlacemarksOnMainThread:)
                           withObject:nil
                        waitUntilDone:NO];
}

- (void) addPlacemarksOnMainThread:(id)object
{
    @try
    {
        [self removeAllRenderables];

        [self addRenderables:placemarks];

        placemarks = nil; // placemark list is needed only during parsing

        [[NSNotificationCenter defaultCenter] postNotificationName:TAIGA_REFRESH_COMPLETE object:self];

        // Redraw in case the layer was enabled before all the placemarks were loaded.
        [WorldWindView requestRedraw];
    }
    @catch (NSException* exception)
    {
        WWLogE(@"Adding Weather Cam data to layer", exception);
    }
}

- (void) addCurrentCamera
{
    NSString* siteID = [currentPlacemarkDict objectForKey:@"siteID"];
    NSMutableArray* siteCameraList = [sitesInfo objectForKey:siteID];

    if (siteCameraList == nil)
    {
        siteCameraList = [[NSMutableArray alloc] init];
        [sitesInfo setObject:siteCameraList forKey:siteID];
    }

    [siteCameraList addObject:currentPlacemarkDict];
}

- (void) createPlacemarks
{
    NSEnumerator* enumerator = [sitesInfo objectEnumerator];
    NSArray* siteCameras;
    while ((siteCameras = [enumerator nextObject]) != nil)
    {
        NSDictionary* firstCamera = [siteCameras objectAtIndex:0];

        NSString* latString = [firstCamera objectForKey:@"siteLatitude"];
        NSString* lonString = [firstCamera objectForKey:@"siteLongitude"];
        double lat = [latString doubleValue];
        double lon = [lonString doubleValue];
        WWPosition* position = [[WWPosition alloc] initWithDegreesLatitude:lat longitude:lon altitude:0];

        WWPointPlacemark* pointPlacemark = [[WWPointPlacemark alloc] initWithPosition:position];
        [pointPlacemark setAltitudeMode:WW_ALTITUDE_MODE_CLAMP_TO_GROUND];
        [pointPlacemark setUserObject:siteCameras];

        NSString* name = [firstCamera objectForKey:@"siteName"];
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

    // Sites info hash table is no longer needed.
    [sitesInfo removeAllObjects];
}

@end