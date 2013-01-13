/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import "WorldWind/WorldWindConstants.h"
#import "WorldWind/WWLog.h"

/**
* Provides access to World Wind singletons.
*/
@interface WorldWind : NSObject

/**
* Returns the singleton World Wind retrieval queue.
*
* @return The World Wind retrieval queue.
*/
+ (NSOperationQueue*) retrievalQueue;

/**
* Show or hide the device's network busy signal.
*
* Calls to this method are reference counted so the signal may still display even after calling this method. If so,
* it means that the method has been called by other code performing network activity.
*
* @param visible YES to turn the busy signal on, NO to turn it off.
*/
+ (void) setNetworkBusySignalVisible:(BOOL)visible;

@end
