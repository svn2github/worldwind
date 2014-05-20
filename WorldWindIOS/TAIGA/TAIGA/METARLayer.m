/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import "METARLayer.h"
#import "MetarIconGenerator.h"
#import "WorldWind/Geometry/WWPosition.h"
#import "WorldWind/Geometry/WWVec4.h"
#import "WorldWind/Navigate/WWNavigatorState.h"
#import "WorldWind/Render/WWDrawContext.h"
#import "WorldWind/Shapes/WWPointPlacemark.h"
#import "WorldWind/Shapes/WWPointPlacemarkAttributes.h"
#import "WorldWind/Terrain/WWGlobe.h"
#import "WorldWind/Util/WWRetriever.h"
#import "WorldWind/WorldWind.h"
#import "WorldWind/WorldWindView.h"
#import "AppConstants.h"

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
        {
            layer.refreshInProgress = [[NSNumber alloc] initWithBool:NO];
            return;
        }

        NSXMLParser* docParser = [[NSXMLParser alloc] initWithData:metarData];
        [docParser setDelegate:layer];

        BOOL status = [docParser parse];
        if (status == NO)
        {
            WWLog(@"METAR data parsing failed");
        }
        else
        {
            [layer setLastUpdate:[[NSDate alloc] init]];
        }
    }
    @catch (NSException* exception)
    {
        WWLogE(@"Exception loading METAR data", exception);
    }

    layer.refreshInProgress = [[NSNumber alloc] initWithBool:NO];
}

@end

@implementation METARLayer
{
    NSMutableDictionary* currentPlacemarkDict;
    NSString* currentName;
    NSMutableString* currentString;
    NSMutableArray* placemarks;
}

- (METARLayer*) init
{
    self = [super init];

    [self setDisplayName:@"METAR Weather"];

    _refreshInProgress = [[NSNumber alloc] initWithBool:NO];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleRefreshNotification:)
                                                 name:TAIGA_REFRESH
                                               object:nil];

    NSTimer* refreshTimer = [NSTimer scheduledTimerWithTimeInterval:1800
                                                    target:self
                                                  selector:@selector(handleRefreshTimer:)
                                                  userInfo:nil
                                                   repeats:YES];
    [refreshTimer setTolerance:180];

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

- (void) handleRefreshTimer:(NSTimer*)timer
{
    NSLog(@"TIMER FIRED");
    [self refreshData];
}

- (void) refreshData
{
    [self removeAllRenderables];

    // Retrieve the data on a separate thread because it takes a while to download and parse.
    NSString* urlString = @"http://aviationweather.gov/adds"
            "/dataserver_current/httpparam?dataSource=metars&requestType=retrieve"
            "&format=xml&stationString=PA*&hoursBeforeNow=1&mostRecentForEachStation=postfilter";
    METARLayerRetriever* retriever = [[METARLayerRetriever alloc] initWithUrl:urlString layer:self];

    @synchronized (_refreshInProgress)
    {
        if ([_refreshInProgress boolValue])
            return;

        _refreshInProgress = [[NSNumber alloc] initWithBool:YES];
    }

    [[WorldWind loadQueue] addOperation:retriever];
}

- (void) handleRefreshNotification:(NSNotification*)notification
{
    if ([[notification name] isEqualToString:TAIGA_REFRESH]
            && ([notification object] == nil || [notification object] == self))
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
    [self performSelectorOnMainThread:@selector(addPlacemarksOnMainThread:) withObject:nil waitUntilDone:NO];
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

    NSString* iconFilePath = [MetarIconGenerator createIconFile:currentPlacemarkDict full:NO];
    if (iconFilePath == nil) // in case something goes wrong
        iconFilePath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"weather32x32.png"];
    [currentPlacemarkDict setObject:iconFilePath forKey:@"IconFilePath.partial"];

    WWPointPlacemarkAttributes* attrs = [[WWPointPlacemarkAttributes alloc] init];
    [attrs setImagePath:iconFilePath];
    [pointPlacemark setAttributes:attrs];

    if (placemarks == nil)
    {
        placemarks = [[NSMutableArray alloc] init];
    }
    [placemarks addObject:pointPlacemark];
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
        if ([self enabled])
            [WorldWindView requestRedraw];
    }
    @catch (NSException* exception)
    {
        WWLogE(@"Adding METAR data to layer", exception);
    }
}

- (WWPosition*) parseCoordinates
{
    NSString* latString = [currentPlacemarkDict objectForKey:@"latitude"];
    NSString* lonString = [currentPlacemarkDict objectForKey:@"longitude"];

    double lat = [latString doubleValue];
    double lon = [lonString doubleValue];

    return [[WWPosition alloc] initWithDegreesLatitude:lat longitude:lon altitude:0];
}

#define MIN_SCALE (0.3)
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

        NSString* iconFilePath;
        if (d >= MAX_DIST)
        {
            iconFilePath = [[placemark userObject] objectForKey:@"IconFilePath.partial"];
        }
        else
        {
            iconFilePath = [[placemark userObject] objectForKey:@"IconFilePath.full"];
            if (iconFilePath == nil)
            {
                iconFilePath = [MetarIconGenerator createIconFile:[placemark userObject] full:YES];
                [[placemark userObject] setObject:iconFilePath forKey:@"IconFilePath.full"];
            }
        }

        WWPointPlacemarkAttributes* attrs = [placemark attributes];
        if (![[attrs imagePath] isEqualToString:iconFilePath])
        {
            [attrs setImagePath:iconFilePath];
        }

        [placemark render:dc];
    }
}

@end