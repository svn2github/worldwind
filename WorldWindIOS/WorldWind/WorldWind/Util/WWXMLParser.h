/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import <Foundation/Foundation.h>

/**
* Parses an XML document into a tree of dictionaries and lists. After initialization,
* at which time the specified XML data is parsed, each element in the document is represented by a dictionary
* containing keys and values for all its elements. Elements that may repeat within a parent element are captured as a
 * list within the parent element. The key for the list is the element name of those elements that repeat. Textual
 * content of an element is captured in an element's dictionary using the "characters" key.
 *
 * Each element's dictionary contains a "parent" key whose corresponding value is the element's parent element. Each
 * dictionary also contains an "elementname" key whose value is the lowercase name of the element.
*/
@interface WWXMLParser : NSObject <NSXMLParserDelegate>
{
    NSSet* listElements;
    NSMutableDictionary* currentElement;
    NSMutableString* currentString;
}

/// @name XML Parser Attributes

/// The dictionary of the XML document's root element.
@property(nonatomic, readonly) NSMutableDictionary* root;

/**
* Initialize this parser and parse the specified XML. Upon return the root element of the document is available via
* the root property.
*
* @param data The XML to parse.
* @param listElementNames A list identifying the lowercase element names of all elements that may be contained
* multiple times within their enclosing parent element. Elements with the specified names are captured in their
* parent's dictionary as an NSArray, whose key is that same element name. For example,
* if an element may contain multiple Layer elements, then those elements are captured in the enclosing element's
* dictionary under the "layer" key.
*
* @return This instance after parsing the specified XML, or nil if the XML could not be parsed.
*
* @exception NSInvalidArgumentException if the specified data is nil.
*/
- (WWXMLParser*)initWithData:(NSData*)data listElementNames:(NSSet*)listElementNames;

+ (void) writeXML:(NSDictionary*)xml toFile:(NSString*)filePath;

@end