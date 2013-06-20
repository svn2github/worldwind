/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import <Foundation/Foundation.h>

@class WWLayer;
@class WWTiledImageLayer;

/**
* Retrieves a WMS layer's capabilities and determines if those capabilities indicate whether the layer's data has
* expired. Layer expiration is optionally provided in a layer's capability element via a keyword with the following
* pattern: "LastUpdate=yyyy-MM-dd'T'HH:mm:ssZ".
*/
@interface WWWMSLayerExpirationRetriever : NSOperation

/// @name Attributes

/// The layer in question.
@property(nonatomic, readonly) id layer;

/// The WMS layer name.
@property(nonatomic, readonly) NSString* layerName;

/// The WMS service address.
@property(nonatomic, readonly) NSString* serviceAddress;

/// @name Initializing

/**
* Initializes this retriever with the specified layer, layer name and service address. The retrieval is performed
* by adding this instance to an operation queue.
*
* @param layer The layer whose expiration is of interest.
* @param layerName The WMS layer name of the layer of interest.
* @param serviceAddress The WMS server's address.
*/
- (WWWMSLayerExpirationRetriever*) initWithLayer:(id)layer
                                     layerName:(NSString*)layerName
                                serviceAddress:(NSString*)serviceAddress;

@end