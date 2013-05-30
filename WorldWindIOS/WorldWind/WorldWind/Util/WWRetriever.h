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
 * The retrieval is performed on a separate thread from that of the initializer. The finished block is called on the
 * same thread that performRetrieval is called on.
 *
 * Instances of this class can be used directly by calling performRetrieval or as an NSOperation. In the latter case
 * the call to performRetrieval is made on the NSOperation's thread.
*/
@interface WWRetriever : NSOperation <NSURLConnectionDelegate, NSURLConnectionDataDelegate>
{
    void (^finished)(WWRetriever* retriever);
}

/// name Retriever Attributes

/// The URL from which to retrieve the resource.
@property(nonatomic, readonly) NSURL* url;

/// The status of the retrieval when the finished block is called. Will be one of WW_SUCCEEDED, WW_CANCELED or
/// WW_FAILED.
@property(nonatomic, readonly) NSString* status;

/// The number of seconds to wait before the request times out.
@property(nonatomic, readonly) NSTimeInterval timeout;

/// The retrieved data. Available only once the finished block is called.
@property(nonatomic, readonly) NSMutableData* retrievedData;

/// @name Initializing Retrievers

/**
* Initializes this instance.
*
* The specified finished block is called when the download completed. It is called on the same thread that
* initialized this instance.
*
* Call performRetrieval to begin the download.
*
* @param url The URL to download from.
* @param timeout The number of seconds to wait for a connection.
* @param finishedBlock The block to call when the download is complete.
*
* @return This instance, initialized.
*
* @exception NSInvalidArgumentException If either the specified url or finished block is nil.
*/
- (WWRetriever*) initWithUrl:(NSURL*)url
                     timeout:(NSTimeInterval)timeout
               finishedBlock:(void (^) (WWRetriever*))finishedBlock;

/**
* Perform the download.
*
* The finished block specified at initialization is called when the download completes. It is called on the same
* thread that the call to performRetrieval is made.
*/
- (void) performRetrieval;

@end