/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import "CrashDataLayer.h"
#import "WorldWind/Geometry/WWPosition.h"
#import "WorldWind/WWLog.h"
#import "WorldWind/Util/WWUtil.h"
#import "WorldWind/Shapes/WWPointPlacemark.h"
#import "WWPointPlacemarkAttributes.h"
#import "WorldWindConstants.h"

@implementation CrashDataLayer

- (CrashDataLayer*) initWithURL:(NSString*)urlString
{
    self = [super init];

    [self setDisplayName:@"Accidents"];

    NSURL* url = [[NSURL alloc] initWithString:urlString];
    NSData* data = [WWUtil retrieveUrl:url timeout:5];
    if (data == nil)
    {
        WWLog(@"Unable to download flight paths file %@", [url absoluteString]);
        return self;
    }

    iconFilePath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"placemark_circle.png"];

    docParser = [[NSXMLParser alloc] initWithData:data];
    [docParser setDelegate:self];

    BOOL status = [docParser parse];
    if (status == NO)
    {
        WWLog(@"Crash data parsing failed");
    }
    NSLog(@"%d placemarks", [[self renderables] count]);

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
        [self addCurrentPlacemarkToLayer];
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

- (WWPosition*) parseCoordinates:(NSString*)string
{
    NSArray* coords = [string componentsSeparatedByString:@","];

    double lon = [[coords objectAtIndex:0] doubleValue];
    double lat = [[coords objectAtIndex:1] doubleValue];
    double alt = [[coords objectAtIndex:2] doubleValue];

    return [[WWPosition alloc] initWithDegreesLatitude:lat longitude:lon altitude:alt];
}

- (void) addCurrentPlacemarkToLayer
{
    WWPosition* position = [currentPlacemark objectForKey:@"Position"];
    WWPointPlacemark* pointPlacemark = [[WWPointPlacemark alloc] initWithPosition:position];
    [pointPlacemark setAltitudeMode:WW_ALTITUDE_MODE_CLAMP_TO_GROUND];
    NSString* name = [currentPlacemark objectForKey:@"AcftName"];
    if (name != nil)
    {
        [pointPlacemark setDisplayName:name];
    }

    WWPointPlacemarkAttributes* attrs = [[WWPointPlacemarkAttributes alloc] init];
    [attrs setImagePath:iconFilePath];
    [pointPlacemark setAttributes:attrs];

    [self addRenderable:pointPlacemark];
}

@end