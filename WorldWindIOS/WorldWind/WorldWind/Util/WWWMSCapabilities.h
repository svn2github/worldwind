/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import <Foundation/Foundation.h>

/**
* Holds the contents of a parsed WMS Capabilities document and provides accessors to commonly used element contents.
* Each element of the document is held as a dictionary. See WWXMLParser for details.
*/
@interface WWWMSCapabilities : NSObject

/// @name WMS Capabilities Attributes

/// The root of the parsed capabilities document. See WWXMLParser for a description of the root element's contents.
@property(nonatomic, readonly) NSMutableDictionary* root;

/**
* Initialize this instance. Retrieve and parse the capabilities document for the specified WMS server.
*
* @param serverAddress The address of the WMS server, e.g, "http://example.com/wms".
*
* @return This instance with its parsed capabilities document, or nil if the document could not be retrieved or parsed.
*
* @exception NSInvalidArgumentException If the specified server address is nil or empty.
*/
- (WWWMSCapabilities*) initWithServerAddress:(NSString*)serverAddress;

/**
* Returns all the layers with Name elements in the capabilities document.
*
* @return The list of named layers, or nil if the document does not contain a Layer element. The returned list is
* empty if there are no named layers in the document.
*/
- (NSArray*) namedLayers;

/**
* Return the capabilities document element for a layer with a specified name. See WWXMLParser for a description of
* the returned dictionary's contents.
*
* @param layerName The name of the layer of interest.
*
* @return The capabilities dictionary for the layer with the specified name, or nil if no layer with that name exists
* in the capabilities document.
*
* @exception NSInvalidArgumentException If the specified layer name is nil.
*/
- (NSDictionary*) namedLayer:(NSString*)layerName;

/**
* Return the layer name for the specified layer capabilities.
*
* @param layerCaps The layer capabilities.
*
* @return The contents of the Name element of the specified layer capabilities, or nil if the capabilities contain no
 * layer name.
 *
 * @exception NSInvalidArgumentException if the specified layer capabilities is nil.
*/
- (NSString*) layerName:(NSDictionary*)layerCaps;

/**
* Return the last update time given in a specified layer's keywords.
*
* This element searches a layer's keywords for a keyword with the following pattern: "LastUpdate=yyyy-MM-dd'T'HH:mm:ssZ".
* If that keyword is found it is converted to a data object and that object is returned.
*
* This convention of specifying a last-update time as a keyword is specific to World Wind servers. It is not a
* general WMS practice.
*
* @param layerCaps The layer's capabilities.
*
* @return The date and time given in the layer's capabilities LastUpdate keyword,
* or nil if that keyword does not exist.
*
* @exception NSInvalidArgumentException if the specified layer capabilities is nil.
*/
- (NSDate*) layerLastUpdateTime:(NSDictionary*)layerCaps;

@end