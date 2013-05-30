/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import <Foundation/Foundation.h>

@class WWSector;

/**
* Holds the contents of a parsed WMS Capabilities document and provides accessors to commonly used element contents.
* Each element of the document is held as a dictionary. See WWXMLParser for details.
*/
@interface WWWMSCapabilities : NSObject
{
    void (^finished)(WWWMSCapabilities* retriever); // the completion handler called after downloading and parsing
}

/// @name WMS Capabilities Attributes

/// The root of the parsed capabilities document. See WWXMLParser for a description of the root element's contents.
@property(nonatomic, readonly) NSDictionary* root;

/// The server address specified to initWithServerAddress.
@property(nonatomic, readonly) NSString* serverAddress;

/// @name Initializing WMS Capabilities

/**
* Initialize this instance. Retrieve and parse the capabilities document for the specified WMS server.
*
* This method initiates the download and parsing of the specified server's WMS capabilities. The capabilities contents
* are not available until the specified finishedBlock is called.
*
* @param serverAddress The address of the WMS server, e.g, "http://example.com/wms".
* @param finishedBlock The block to call once the capabilities have been downloaded and parsed.
*
* @return This instance initialized. Note that the documents contents are not available until the finishedBlock is
* called.
*
* @exception NSInvalidArgumentException If the specified server address is nil or empty or the specified finish
* block is nil.
*/
- (WWWMSCapabilities*) initWithServerAddress:(NSString*)serverAddress
                               finishedBlock:(void (^) (WWWMSCapabilities*))finishedBlock;

- (WWWMSCapabilities*) initWithCapabilitiesFile:(NSString*)filePath;

/**
* Initialize this instance from a specified dictionary of capabilities, typical retrieved from user defaults.
*
* @param dictionary A dictionary containing the capabilities. This dictionary becomes the root property of this
* instance.
*
* @return This instance, initialized.
*
* @exception NSInvalidArgumentException if the dictionary is nil.
*/
- (WWWMSCapabilities*) initWithCapabilitiesDictionary:(NSDictionary*)dictionary;

/// @name Getting Information from WMS Capabilities

/**
* Returns the service title.
*
* @return The service title, or nil if no title is specified in the capabilities.
*/
- (NSString*) serviceTitle;

/**
* Returns the service name.
*
* @return The service name, or nil if no name is specified in the capabilities.
*/
- (NSString*) serviceName;

/**
* Returns the service abstract.
*
* @return The service abstract, or nil if no abstract is specified in the capabilities.
*/
- (NSString*) serviceAbstract;

/**
* Returns the service version.
*
* @return The service version, or nil if no version is specified in the capabilities.
*/
- (NSString*) serverWMSVersion;

/**
* Returns the layers in the capabilities' Capability section. Only the top-most layers are returned.
*
* @return The layers in the capabilities' Capability section, or nil if the capabilities contains no layers.
*/
- (NSArray*) layers;

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
* Returns the GetMap request URL string.
*
* @return The GetMap request URL as a string.
*/
- (NSString*) getMapURL;

/**
* Returns the geographic bounding box for a specified layer.
*
* The bounding box returned is either that of the layer itself or the nearest ancestor specifying a geographic
* bounding box.
*
* @return The effective geographic bounding box for the specified layer, or nil if one cannot be found in the layer
* or its ancestors (which would indicate an invalid capabilities document).
*/
- (WWSector*) geographicBoundingBoxForNamedLayer:(NSDictionary*)layerCapabilities;

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
+ (NSString*) layerName:(NSDictionary*)layerCaps;

/**
* Returns the title of a specified layer.
*
* @return The specified layer's title, or nil if it has no title.
 *
 * @exception NSInvalidArgumentException if the specified layer capabilities is nil.
*/
+ (NSString*) layerTitle:(NSDictionary*)layerCaps;

/**
* Returns the abstract of a specified layer.
*
* @return The specified layer's abstract, or nil if it has no abstract.
 *
 * @exception NSInvalidArgumentException if the specified layer capabilities is nil.
*/
+ (NSString*) layerAbstract:(NSDictionary*)layerCaps;

/**
* Returns the sub-layers of a specified layer.
*
* @return The specified layer's sub-layers, or nil if it has no sub-layers.
 *
 * @exception NSInvalidArgumentException if the specified layer capabilities is nil.
*/
+ (NSArray*) layers:(NSDictionary*)layerCaps;

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
+ (NSDate*) layerLastUpdateTime:(NSDictionary*)layerCaps;

@end