/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.

 @version $Id$
 */

#import <Foundation/Foundation.h>

@class WWSector;
@protocol WWBulkRetrieverDataSource;

/**
* WWBulkRetriever is a subclass of NSOperation that downloads a data source's network resources and prepares them for
* offline use.
*
* Callers configure a bulk retriever with the desired data source, sector and target resolution. The
* WWBulkRetrieverDataSource protocol defines an interface for a network enabled layer or model to download network
* resources on behalf of a bulk retriever. WWTiledImageLayer and WWBasicElevationModel implement the bulk retriever data
* source protocol and may be used as the dataSource argument in bulk retriever's initializers.
*
* Bulk retrievers typically execute their tasks on a non-UI thread by adding the bulk retriever to an NSOperationQueue.
* While a bulk retriever's task may be executed from the UI thread, these tasks are typically long running and would
* therefore block the UI thread until the task completes. Using an operation queue ensures that the task does not block
* the UI thread and enables the task to be stopped.
*
* A bulk retriever may be stopped at any time by sending it the cancel message or by setting World Wind to offline mode.
* The bulk retriever and its data source make the best attempt to terminate the task as soon as possible thereafter.
* Sending a bulk retriever the cancel message or enabling offline mode does not guarantee that the bulk retriever stops
* immediately. In order to reliably execute code when a bulk retrieval task completes, use the bulk retriever's
* completion block. For more information on stopping bulk retrievers and completion blocks, see the following:
*
* - NSOperation cancel
* - NSOperation setCompletionBlock
* - [WorldWind setOfflineMode:]
*/
@interface WWBulkRetriever : NSOperation

/// @name Bulk Retriever Attributes

/// The data source to retrieve network resources for. Downloads network resources on behalf of a bulk retriever.
@property (readonly) id <WWBulkRetrieverDataSource> dataSource;

/// The sectors in which to retrieve network resources.
@property (readonly) NSArray* sectors;

/// The maximum resolution desired for the data source's network resources, in radians per pixel or elevation cell.
/// A value of 0.0 indicates that the best available resolution should be retrieved.
@property (readonly) double targetResolution;

/// The retriever's current progress as a floating-point value between 0.0 and 1.0, inclusive. A value of 1.0 indicates
/// that the retriever's task is complete. Progress is updated by the data source as network resources are retrieved.
@property float progress;

/// @name Initializing Bulk Retrievers

/**
* Initializes this bulk retriever with the specified data source, sector and the best available resolution.
*
* This bulk retriever's targetResolution is initialized to 0.0, indicating that the best available resolution should be
* retrieved.
*
* @param dataSource The data source to retrieve network resources for. Downloads network resources on behalf of a bulk
* retriever.
* @param sectors The sectors in which to retrieve network resources.
*
* @return This bulk retriever initialized with the specified data source and sector.
*
* @exception NSInvalidArgumentException If any argument is nil.
*/
- (WWBulkRetriever*) initWithDataSource:(id <WWBulkRetrieverDataSource>)dataSource sectors:(NSArray*)sectors;

/**
* Initializes this bulk retriever with the specified data source, sector and target resolution.
*
* @param dataSource The data source to retrieve network resources for. Downloads network resources on behalf of a bulk
* retriever.
* @param sectors The sectors in which to retrieve network resources.
* @param resolution The maximum resolution desired for the data source's network resources, in radians per pixel or elevation cell.
*
* @return This bulk retriever initialized with the specified data source, sector and target resolution.
*
* @exception NSInvalidArgumentException If any argument is nil.
*/
- (WWBulkRetriever*) initWithDataSource:(id <WWBulkRetrieverDataSource>)dataSource sectors:(NSArray*)sectors
                       targetResolution:(double)resolution;

/// @name Executing the Bulk Retrieval

/**
* Performs this bulk retriever's task by calling performBulkRetrieval:.
*
* If this bulk retriever is cancelled or World Wind is in offline mode, this does nothing and exits immediately.
*/
- (void) main;

/**
* Returns a boolean value indicating whether the bulk retriever should stop its task.
*
* This return YES if this bulk retriever is cancelled or if World Wind is in offline mode, and NO otherwise.
*
* @return YES if the bulk retriever should stop its task, otherwise NO.
*/
- (BOOL) mustStopBulkRetrieval;

/**
* Requests that this retriever's data source download all resources for the sector and resolution configured during
* initialization.
*/
- (void) performBulkRetrieval;

@end