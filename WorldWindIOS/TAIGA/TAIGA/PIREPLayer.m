/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import "PIREPLayer.h"
#import "WorldWind/Geometry/WWPosition.h"
#import "WorldWind/Shapes/WWPointPlacemark.h"
#import "WorldWind/Shapes/WWPointPlacemarkAttributes.h"
#import "WorldWind/Util/WWRetriever.h"
#import "WorldWind/WorldWind.h"
#import "WorldWind/WorldWindView.h"

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
    NSMutableDictionary* currentPlacemarkDict;
    NSDictionary* currentAttributesDict;
    NSString* currentName;
    NSMutableString* currentString;
    NSMutableArray* placemarks;
}

// The schema for AircraftReport is here: http://weather.aero/schema/aircraftreport1_0.xsd
// The attribute strings used below are taken from http://weather
// .aero/tools/dataservices/textdataserver/dataproducts/view/product/aircraftreports/section/fields

- (PIREPLayer*) init
{
    self = [super init];

    [self setDisplayName:@"PIREPS"];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleRefreshNotification:)
                                                 name:WW_REFRESH
                                               object:self];

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
    // Retrieve the data on a separate thread because it takes a while to download and parse.
    NSString* urlString = @"http://www.aviationweather"
            ".gov/adds/dataserver_current/httpparam?dataSource=aircraftreports&requestType=retrieve&format=xml&minLat"
            "=52&minLon=-170&maxLat=72&maxLon=-130&hoursBeforeNow=3&minAltitudeFt=0&maxAltitudeFt=15000";
    PIREPLayerRetriever* retriever = [[PIREPLayerRetriever alloc] initWithUrl:urlString layer:self];
    [[WorldWind loadQueue] addOperation:retriever];
}

- (void) handleRefreshNotification:(NSNotification*)notification
{
    if ([[notification name] isEqualToString:WW_REFRESH] && [notification object] == self)
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
    if ([elementName isEqualToString:@"AircraftReport"])
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
    if ([elementName isEqualToString:@"AircraftReport"])
    {
        // Filter out report types other than PIREPs.
        NSString* reportType = [currentPlacemarkDict objectForKey:@"report_type"];
        if (reportType != nil && [reportType isEqualToString:@"PIREP"])
            [self addCurrentPlacemark];

        currentPlacemarkDict = nil;
    }
    else if ([currentName isEqualToString:@"sky_condition"]
            || [currentName isEqualToString:@"turbulence_condition"]
            || [currentName isEqualToString:@"icing_condition"])
    {
        NSMutableArray* attrsArray = [currentPlacemarkDict objectForKey:currentName];
        if (attrsArray == nil)
        {
            attrsArray = [[NSMutableArray alloc] init];
            [currentPlacemarkDict setObject:attrsArray forKey:currentName];
        }
        [attrsArray addObject:currentAttributesDict];
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
        [self removeAllRenderables];

        [self addRenderables:placemarks];

        placemarks = nil; // placemark list is needed only during parsing

        [[NSNotificationCenter defaultCenter] postNotificationName:WW_REFRESH_COMPLETE object:self];

        // Redraw in case the layer was enabled before all the placemarks were loaded.
        [WorldWindView requestRedraw];
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
    [pointPlacemark setUserObject:currentPlacemarkDict];

    NSString* name = [currentPlacemarkDict objectForKey:@"observation_time"];
    if (name != nil)
    {
        [pointPlacemark setDisplayName:name];
    }

    WWPointPlacemarkAttributes* attrs = [[WWPointPlacemarkAttributes alloc] init];
    [attrs setImagePath:[self determineIconFilePath:currentPlacemarkDict]];
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

- (NSString*) determineIconFilePath:(NSDictionary*)placemarkDict
{
    // The strings used below are taken from http://weather.aero/tools/dataservices/textdataserver/dataproducts/view/product/aircraftreports/section/fields

    NSString* iconFile = @"PIREP_ICONS_Generic.png";
    NSString* genericIconPath = [[[NSBundle mainBundle] resourcePath]
            stringByAppendingPathComponent:iconFile];

    NSDictionary* skyCondition = [placemarkDict objectForKey:@"sky_condition"];
    NSDictionary* turbulenceCondition = [placemarkDict objectForKey:@"turbulence_condition"];
    NSDictionary* icingCondition = [placemarkDict objectForKey:@"icing_condition"];

    if (skyCondition != nil && turbulenceCondition == nil && icingCondition == nil)
    {
        NSArray* attrsArray = [placemarkDict objectForKey:@"sky_condition"];
        if (attrsArray == nil || [attrsArray count] != 1)
            return genericIconPath;

        NSString* condition = [[attrsArray objectAtIndex:0] objectForKey:@"sky_cover"];
        if (condition != nil)
        {
            if ([condition isEqualToString:@"UNKN"])
                iconFile = @"PIREP_ICONS_0015_Layer-17.png";
            else if ([condition isEqualToString:@"CLEAR"])
                iconFile = @"PIREP_ICONS_0016_Layer-18.png";
            else if ([condition isEqualToString:@"FEW"])
                iconFile = @"PIREP_ICONS_0017_Layer-19.png";
            else if ([condition isEqualToString:@"SCT"])
                iconFile = @"PIREP_ICONS_0018_Layer-20.png";
            else if ([condition isEqualToString:@"BKN"])
                iconFile = @"PIREP_ICONS_0019_Layer-21.png";
            else if ([condition isEqualToString:@"OVC"])
                iconFile = @"PIREP_ICONS_0020_Layer-22.png";
            else if ([condition isEqualToString:@"IMC"])
                iconFile = @"PIREP_ICONS_0021_Layer-23.png";
            // Missing icons for VMC, VFR, SKC, CAVOC, OVX, IFR
        }
    }
    else if (turbulenceCondition != nil && skyCondition == nil && icingCondition != nil)
    {
        NSArray* attrsArray = [placemarkDict objectForKey:@"turbulence_condition"];
        if (attrsArray == nil || [attrsArray count] != 1)
            return genericIconPath;

        NSString* condition = [[attrsArray objectAtIndex:0] objectForKey:@"turbulence_intensity"];
        if (condition != nil)
        {
            if ([condition isEqualToString:@"NEG"])
                iconFile = @"PIREP_ICONS_0000_Layer-2.png";
            else if ([condition isEqualToString:@"SMTH-LGT"])
                iconFile = @"PIREP_ICONS_0008_Layer-10.png";
            else if ([condition isEqualToString:@"LGT"])
                iconFile = @"PIREP_ICONS_0009_Layer-11.png";
            else if ([condition isEqualToString:@"LGT-MOD"])
                iconFile = @"PIREP_ICONS_0010_Layer-12.png";
            else if ([condition isEqualToString:@"MOD"])
                iconFile = @"PIREP_ICONS_0011_Layer-13.png";
            else if ([condition isEqualToString:@"MOD-SEV"])
                iconFile = @"PIREP_ICONS_0012_Layer-14.png";
            else if ([condition isEqualToString:@"SEV"])
                iconFile = @"PIREP_ICONS_0013_Layer-15.png";
            else if ([condition isEqualToString:@"SEV-EXTM"])
                iconFile = @"PIREP_ICONS_0014_Layer-16.png";
            else if ([condition isEqualToString:@"EXTM"])
                iconFile = @"PIREP_ICONS_0014_Layer-16.png"; // duplicates SEV-EXTM because correct icon undefined
        }
    }
    else if (icingCondition != nil && skyCondition == nil && turbulenceCondition == nil)
    {
        NSArray* attrsArray = [placemarkDict objectForKey:@"icing_condition"];
        if (attrsArray == nil || [attrsArray count] != 1)
            return genericIconPath;

        NSString* condition = [[attrsArray objectAtIndex:0] objectForKey:@"icing_intensity"];
        if (condition != nil)
        {
            if ([condition isEqualToString:@"NEG"])
                iconFile = @"PIREP_ICONS_0000_Layer-2.png";
            if ([condition isEqualToString:@"NEGClr"])
                iconFile = @"PIREP_ICONS_0000_Layer-2.png";
            else if ([condition isEqualToString:@"TRC"])
                iconFile = @"PIREP_ICONS_0001_Layer-3.png";
            else if ([condition isEqualToString:@"TRC-LGT"])
                iconFile = @"PIREP_ICONS_0002_Layer-4.png";
            else if ([condition isEqualToString:@"LGT"])
                iconFile = @"PIREP_ICONS_0003_Layer-5.png";
            else if ([condition isEqualToString:@"LGT-MOD"])
                iconFile = @"PIREP_ICONS_0004_Layer-6.png";
            else if ([condition isEqualToString:@"MOD"])
                iconFile = @"PIREP_ICONS_0005_Layer-7.png";
            else if ([condition isEqualToString:@"MOD-SEV"])
                iconFile = @"PIREP_ICONS_0006_Layer-8.png";
            else if ([condition isEqualToString:@"HVY"]) // duplicates EXTM because correct icon undefined
                iconFile = @"PIREP_ICONS_0007_Layer-9.png";
            else if ([condition isEqualToString:@"EXTM"])
                iconFile = @"PIREP_ICONS_0007_Layer-9.png";
            // Missing icons for HVY
        }
    }
    else
    {
        return genericIconPath;
    }

    return [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:iconFile];
}

@end