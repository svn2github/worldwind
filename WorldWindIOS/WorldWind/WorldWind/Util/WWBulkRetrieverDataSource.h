/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.

 @version $Id$
 */

@class WWBulkRetriever;
@class WWSector;

/**
* WWBulkRetrieverDataSource defines an protocol for a network enabled layer or model to download network resources on
* behalf of a WWBulkRetriever.
*
* Callers create a bulk retriever configured with a data source, sector, and target resolution then the bulk retriever
* sends its data source a performBulkRetrieval: message in a non-UI thread. A bulk retriever may be cancelled at any
* time by sending it the cancel message or by setting World Wind to offline mode. Data sources must attempt to terminate
* as soon as possible thereafter by frequently testing the return value of [WWBulkRetriever mustStopBulkRetrieval].
*
* The bulk retriever defines the region and resolution that the data source should download its resources for. The data
* source must attempt to download all resources it contains in the specified region, and must meet or exceed the
* specified resolution when possible. If bulk retriever's resolution exceeds that of the data source, the data source
* should retrieve resources up to its best available resolution.
*/
@protocol WWBulkRetrieverDataSource <NSObject>

/**
* Requests that this bulk retriever data source download all resources for the region and resolution specified by the
* bulk retriever.
*
* The receiver of this message can assume that this message is sent from a non-UI thread, and may therefore perform long
* running tasks.
*
* @param retriever The retriever defining the region and resolution to download resources for.
*
* @exception NSInvalidArgumentException If the retriever is nil.
*/
- (void) performBulkRetrieval:(WWBulkRetriever*)retriever;

/**
* Returns the data size, in megabytes, of the data for a specified sector and resolution.
*
* @param sectors The sectors for which to determine the data size.
* @param targetResolution The target resolution for the data. 0 indicates use best resolution.
*
* @exception NSInvalidArgumentException If the sector is nil.
*/
- (double) dataSizeForSectors:(NSArray*)sectors targetResolution:(double)targetResolution;

@end