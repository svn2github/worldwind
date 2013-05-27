/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import "WorldWind/Util/WWXMLParser.h"
#import "WorldWind/WWLog.h"

@implementation WWXMLParser

- (WWXMLParser*) initWithData:(NSData*)data listElementNames:(NSSet*)listElementNames
{
    if (data == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Data is nil")
    }

    self = [super init];

    listElements = listElementNames;

    NSXMLParser* docParser = [[NSXMLParser alloc] initWithData:data];
    [docParser setDelegate:self];

    // Making the parser namespace aware causes it to strip any namespace designator from the element name. Without
    // this element names are reported with their namespace designator still attached.
    [docParser setShouldProcessNamespaces:YES];

    BOOL status = [docParser parse];

    if (status == YES)
    {
        [self removeParentElements:_root];
    }

    return status == YES ? self : nil;
}

- (void) parser:(NSXMLParser*)parser parseErrorOccurred:(NSError*)parseError
{
    WWLog(@"%@", [parseError description]);
}

- (void) parser:(NSXMLParser*)parser didStartElement:(NSString*)elementName namespaceURI:(NSString*)namespaceURI qualifiedName:(NSString*)qName attributes:(NSDictionary*)attributeDict
{
    // Allocate a dictionary for the element and set its name.
    NSMutableDictionary* element = [[NSMutableDictionary alloc] init];
    NSString* lcElementName = [elementName lowercaseString];
    [element setObject:lcElementName forKey:@"elementname"];

    if (listElements != nil && [listElements containsObject:lcElementName])
    {
        // Add this element to its parents list for this type of element.
        [self addListElements:lcElementName element:element];
    }
    else if (currentElement != nil)
    {
        // Add this element directly to the parent's dictionary.
        [currentElement setObject:element forKey:[elementName lowercaseString]];
    }

    // Capture this element's parent.
    if (currentElement != nil) // if current element is nil then this element is the root element.
    {
        [element setObject:currentElement forKey:@"parent"];
    }
    else
    {
        _root = element;
    }

    currentElement = element;

    // Capture all this element's attributes to its dictionary.
    NSEnumerator* attrKeyEnumerator = [attributeDict keyEnumerator];
    NSString* key = [attrKeyEnumerator nextObject];
    while (key != nil)
    {
        NSString* attrValue = [attributeDict valueForKey:key];
        [currentElement setObject:attrValue forKey:[key lowercaseString]];

        key = [attrKeyEnumerator nextObject];
    }

}

- (void) addListElements:(NSString*)key element:(NSMutableDictionary*)element
{
    // Create the parent's list for the element type if id doesn't exist, then add the new element to the list.

    NSMutableArray* parentsItems = [currentElement objectForKey:key];
    if (parentsItems == nil)
    {
        parentsItems = [[NSMutableArray alloc] initWithCapacity:1];
        [currentElement setObject:parentsItems forKey:key];
    }

    [parentsItems addObject:element];
}

- (void) parser:(NSXMLParser*)parser didEndElement:(NSString*)elementName namespaceURI:(NSString*)namespaceURI qualifiedName:(NSString*)qName
{
    // Associate the current string with the current element.
    if (currentString != nil)
    {
        NSString* trimmedString = [currentString stringByTrimmingCharactersInSet:
                [NSCharacterSet whitespaceAndNewlineCharacterSet]];
        if ([trimmedString length] > 0)
        {
            [currentElement setObject:trimmedString forKey:@"characters"];
        }
        currentString = nil;
    }

    // Reset the current element to the ending element's parent.
    currentElement = [currentElement objectForKey:@"parent"];
}

- (void) parser:(NSXMLParser*)parser foundCharacters:(NSString*)string
{
    if (currentString == nil)
    {
        currentString = [[NSMutableString alloc] initWithString:string];
    }
    else
    {
        [currentString appendString:string];
    }
}

-(void) removeParentElements:(NSMutableDictionary*)element
{
    [element removeObjectForKey:@"parent"];

    for (NSString* key in [element allKeys])
    {
        id childElement = [element objectForKey:key];
        if  ([childElement isKindOfClass:[NSArray class]])
        {
            for (NSMutableDictionary* dict in (NSArray*)childElement)
            {
                [self removeParentElements:dict];
            }
        }
        else if  ([childElement isKindOfClass:[NSDictionary class]])
        {
            [self removeParentElements:childElement];
        }
    }
}

+ (void) writeXML:(NSDictionary*)xml toFile:(NSString*)filePath
{
    NSMutableString* outputString = [[NSMutableString alloc] init];

    [WWXMLParser writeElement:xml outputString:outputString];

    NSError* error = nil;
    [outputString writeToFile:filePath atomically:YES encoding:NSUTF8StringEncoding error:&error];
    if (error != nil)
    {
        WWLog("@Error \"%@\" writing XML to %@", [error description], filePath);
        return;
    }
}

+ (void) writeElement:(NSDictionary*)element outputString:(NSMutableString*)outputString
{
    [outputString appendString:@"<"];
    [outputString appendString:[element objectForKey:@"elementname"]];
    [outputString appendString:@">"];

    for (NSString* key in [element allKeys])
    {
        if ([key isEqualToString:@"elementname"] || [key isEqualToString:@"parent"])
            continue;

        if ([key isEqualToString:@"characters"])
        {
            [outputString appendString:[element objectForKey:key]];
            continue;
        }

        id childElement = [element objectForKey:key];
        if  ([childElement isKindOfClass:[NSArray class]])
        {
            for (NSDictionary* dict in (NSArray*)childElement)
            {
                [self writeElement:dict outputString:outputString];
            }
        }
        else if  ([childElement isKindOfClass:[NSDictionary class]])
        {
            [self writeElement:childElement outputString:outputString];
        }
    }

    [outputString appendString:@"</"];
    [outputString appendString:[element objectForKey:@"elementname"]];
    [outputString appendString:@">"];
}

@end