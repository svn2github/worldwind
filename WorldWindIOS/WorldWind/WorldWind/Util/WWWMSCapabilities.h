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

/// The service address specified to initWithServiceAddress.
@property(nonatomic, readonly) NSString* serviceAddress;

/// @name Initializing WMS Capabilities

/**
* Initialize this instance. Retrieve and parse the capabilities document for the specified WMS service.
*
* This method initiates the download and parsing of the specified service's WMS capabilities. The capabilities contents
* are not available until the specified finishedBlock is called.
*
* @param serviceAddress The address of the WMS service, e.g, "http://example.com/wms".
* @param finishedBlock The block to call once the capabilities have been downloaded and parsed.
*
* @return This instance initialized. Note that the documents contents are not available until the finishedBlock is
* called.
*
* @exception NSInvalidArgumentException If the specified service address is nil or empty or the specified finish
* block is nil.
*/
- (WWWMSCapabilities*) initWithServiceAddress:(NSString*)serviceAddress
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

/// @name Getting Service Information from WMS Capabilities

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
- (NSString*) serviceWMSVersion;

/**
* Returns the service contact organization, or nil if no organization is specified in the capabilities.
*/
- (NSString*) serviceContactOrganization;

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
* Returns the image formats supported by the GetMap request.
*
* @return The supported image formats. Returns nil if no formats are specified in the capabilities document.
*/
- (NSArray*) getMapFormats;

/// @name Getting Layer Information from WMS Capabilities

/**
* Return the layer name for the specified layer capabilities.
*
* @param layerCaps The layer capabilities.
*
* @return The contents of the Name element of the specified layer capabilities, or nil if the capabilities contain no
 * layer name.
 *
 * @exception NSInvalidArgumentException If the specified layer capabilities is nil.
*/
+ (NSString*) layerName:(NSDictionary*)layerCaps;

/**
* Returns the title of a specified layer.
*
* @param layerCaps The layer capabilities.
*
* @return The specified layer's title, or nil if it has no title.
 *
 * @exception NSInvalidArgumentException If the specified layer capabilities is nil.
*/
+ (NSString*) layerTitle:(NSDictionary*)layerCaps;

/**
* Returns the abstract of a specified layer.
*
* @param layerCaps The layer capabilities.
*
* @return The specified layer's abstract, or nil if it has no abstract.
 *
 * @exception NSInvalidArgumentException If the specified layer capabilities is nil.
*/
+ (NSString*) layerAbstract:(NSDictionary*)layerCaps;

/**
* Returns the sub-layers of a specified layer.
*
* @param layerCaps The layer capabilities.
*
* @return The specified layer's sub-layers, or nil if it has no sub-layers.
 *
 * @exception NSInvalidArgumentException If the specified layer capabilities is nil.
*/
+ (NSArray*) layers:(NSDictionary*)layerCaps;

/**
* Returns the list of coordinate systems supported by a specified layer.
*
* @param layerCaps The layer capabilities.
*
* @return the list of coordinate systems supported by the layer, or nil if no coordinate systems are declared.
*
* @exception NSInvalidArgumentException If the specified layer capabilities is nil.
*/
- (NSArray*) layerCoordinateSystems:(NSDictionary*)layerCaps;

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
* @exception NSInvalidArgumentException If the specified layer capabilities is nil.
*/
+ (NSDate*) layerLastUpdateTime:(NSDictionary*)layerCaps;

/**
* Indicates whether a specified layer is marked as opaque in its capabilities.
*
* @param layerCaps The layer's capabilities.
*
* @return YES if the layer is marked as opaque, otherwise NO.
*
* @exception NSInvalidArgumentException If the specified layer capabilities is nil.
*/
+ (BOOL) layerIsOpaque:(NSDictionary*)layerCaps;

/**
* Returns the geographic bounding box for a specified layer.
*
* The bounding box returned is either that of the layer itself or the nearest ancestor specifying a geographic
* bounding box.
*
* @param layerCaps The layer capabilities.
*
* @return The effective geographic bounding box for the specified layer, or nil if one cannot be found in the layer
* or its ancestors (which would indicate an invalid capabilities document).
*
* @exception NSInvalidArgumentException If the specified layer capabilities is nil.
*/
- (WWSector*) layerGeographicBoundingBox:(NSDictionary*)layerCaps;

/**
* Returns the data URLs for a specified layer.
*
* @param layerCaps The layer capabilities.
*
* @return The list of data URLs for the specified layer.
*
* @exception NSInvalidArgumentException If the specified layer capabilities is nil.
*/
+ (NSArray*) layerDataURLs:(NSDictionary*)layerCaps;

/**
* Returns the metadata URLs for a specified layer.
*
* @param layerCaps The layer capabilities.
*
* @return The list of metadata URLs for the specified layer.
*
* @exception NSInvalidArgumentException If the specified layer capabilities is nil.
*/
+ (NSArray*) layerMetadataURLs:(NSDictionary*)layerCaps;

/**
* Returns the keywords for a specified layer.
*
* @param layerCaps The layer capabilities.
*
* @return The list of keywords for the specified layer.
*
* @exception NSInvalidArgumentException If the specified layer capabilities is nil.
*/
+ (NSArray*) layerKeywords:(NSDictionary*)layerCaps;

/**
* Returns the min-scale-denominator for a specified layer.
*
* @param layerCaps The layer capabilities.
*
* @return The min-scale-denominator for the specified layer.
*
* @exception NSInvalidArgumentException If the specified layer capabilities is nil.
*/
+ (NSNumber*) layerMinScaleDenominator:(NSDictionary*) layerCaps;

/**
* Returns the max-scale-denominator for a specified layer.
*
* @param layerCaps The layer capabilities.
*
* @return The max-scale-denominator for the specified layer.
*
* @exception NSInvalidArgumentException If the specified layer capabilities is nil.
*/
+ (NSNumber*) layerMaxScaleDenominator:(NSDictionary*) layerCaps;

@end