/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import <Foundation/Foundation.h>

/**
* Provides retrieval and caching of resources. This class is typically used to retrieve image and elevation resources
 * from the internet and save them to the local World Wind file system cache.
 *
 * When a retrieval is complete, a notification is sent indicating retrieval status. The notification's user info
 * dictionary includes the retrieval status (WW_RETRIEVAL_STATUS) of either WW_SUCCEEDED,
 * WW_FAILED or WW_CANCELED. The dictionary also includes the retriever's URL (WW_URL) and its
 * file path (WW_FILE_PATH).
*/
@interface WWRetriever : NSOperation
{
    NSMutableDictionary* responseDictionary;
    NSMutableData* retrievedData;
}

/// @name Attributes

/// The URL from which to retrieve the resource.
@property(nonatomic, readonly) NSURL* url;

/// The full path and name of the file in which to store the resource.
@property(nonatomic, readonly) NSString* filePath;

/// The optional argument specified as the source in the WW_RETRIEVAL_STATUS notification.
@property(nonatomic, readonly) id object;

/// The number of seconds to wait before the request times out.
@property (nonatomic, readonly) NSTimeInterval timeout;

/// @name Initializing Retrievers

/**
* Initialize a retriever with a specified URL, file path and notification source.
*
* @param url The URL from which to retrieve the resource.
* @param filePath The full path and name of the file in which to write the resource. If the directories in the path
* do not exist they are created.
* @param object The object to specify as the source in the WW_RETRIEVAL_STATUS notification.
* @param timeout The number of seconds to wait to establish a connection to the specified URL.
*
* @return The initialized retriever.
*
* @exception NSInvalidArgumentException If the url or file path are nil.
*/
- (WWRetriever*) initWithUrl:(NSURL*)url filePath:(NSString*)filePath object:(id)object timeout:(NSTimeInterval)timeout;

/// @name Operations

/**
* Perform the retrieval on the current thread.
*/
- (void) performRetrieval;

@end