/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import <Foundation/Foundation.h>

/**
* Provides retrieval and caching of resources. This class is typically used to retrieve image and elevation resources
 * from the internet and save them to the local World Wind file system cache.
*/
@interface WWRetriever : NSOperation

/// @name Attributes

/// The URL from which to retrieve the resource.
@property (nonatomic, readonly) NSURL* url;

/// The full path and name of the file in which to store the resource.
@property (nonatomic, readonly) NSString* filePath;

/// A notification instance to send to the default iOS Notification Center when the resource is successfully retrieved
// and stored.
@property (nonatomic, readonly) NSNotification* notification;

/// @name Initializing Retrievers

/**
* Initialize a retriever with a specified URL, file path and optional notification.
*
* The notification, if not nil, is sent to the default iOS Notification Center if the retrieval and storage
* operations are successful.
*
* @param url The URL from which to retrieve the resource.
* @param filePath The full path and name of the file in which to write the resource. If the directories in the path
* do not exist they are created.
* @param notification An optional notification to sent to the notification center when retrieval and storage are
* complete and successful. May be nil.
*
* @return The initialized retriever.
*
* @exception NSInvalidArgumentException If the url or file path are nil.
*/
- (WWRetriever*) initWithUrl:(NSURL*)url filePath:(NSString*)filePath notification:(NSNotification*)notification;

/**
* Adds the retriever to the World Wind retrieval queue, from which it runs asynchronously.
*
* @param retriever The retriever to run.
*
* @exception NSInvalidArgumentException If the retriever is nil.
*/
- (void) addToQueue:(WWRetriever*)retriever;

@end