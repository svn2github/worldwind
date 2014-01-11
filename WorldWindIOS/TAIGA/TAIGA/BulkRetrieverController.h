/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.

@version $Id$
 */

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@class WorldWindView;
@class WWBulkRetriever;
@class WWPath;
@class WWSector;
@protocol WWBulkRetrieverDataSource;

@interface BulkRetrieverCell : UITableViewCell
{
@protected
    UIView* startAccessory;
    UIView* stopAccessory;
    UIProgressView* progress;
    int dataSize;
    WWBulkRetriever* retriever;
}

@property (nonatomic, readonly) id dataSource;

@property (nonatomic, readonly) NSArray* sectors;

@property (nonatomic, readonly) NSOperationQueue* operationQueue;

- (BulkRetrieverCell*) initWithDataSource:(id)dataSource sectors:(NSArray*)sectors operationQueue:(NSOperationQueue*)
        queue;

- (void) startRetrieving;

- (void) stopRetrieving;

- (void) retrieverDidFinish;

@end

@interface BulkRetrieverController : UITableViewController
{
@protected
    NSMutableArray* layerCells;
    NSMutableArray* elevationCells;
}

@property (nonatomic, readonly) WorldWindView* wwv;

@property (nonatomic, readonly) NSOperationQueue* operationQueue;

@property (nonatomic) NSArray* sectors;

- (BulkRetrieverController*) initWithWorldWindView:(WorldWindView*)wwv;

@end