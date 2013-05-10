/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import <Foundation/Foundation.h>

/**
* Protected class used only internally to WWAbsentResourceList.
*/
@interface WWAbsentResourceEntry : NSObject <NSCopying>

@property NSTimeInterval timeOfLastMark;
@property int numTries;

- (WWAbsentResourceEntry*)init;
- (WWAbsentResourceEntry*)initWithTimeOfLastMark:(NSTimeInterval)timeOfLastMark numTries:(int)numTries;

@end

/**
* Provides a means to keep track of resources that failed to be retrieved or otherwise obtained.
*/
@interface WWAbsentResourceList : NSObject
{
@protected
    NSLock* synchronizationLock;
    NSMutableDictionary* possiblyAbsent;
}

/// @name Attributes

/// The maximum number of attempts to make to obtain the resource. This value is reset to zero when the
// tryAgainInterval expires, thereby repeating the try/retry sequence.
@property int maxTries;

/// The number of seconds to wait between successive attempts to obtain the resource.
@property NSTimeInterval minCheckInterval;

/// The number of seconds to wait before repeating the try/retry sequence. Typically this value is on the order of a
// minute or more.
@property NSTimeInterval tryAgainInterval;

/// @name Initializing

/**
* Initialize this absent resource list to specified maximum number of tries and a retry interval.
*
* @param maxTries The maximum number of attempts to obtain the resource.
* @param minCheckInterval The number of seconds to wait between successive retries.
*
* @return This instance initialized to the specified values.
*/
- (WWAbsentResourceList*) initWithMaxTries:(int)maxTries minCheckInterval:(NSTimeInterval)minCheckInterval;

/**
* Indicates whether a specified resource is marked as absent in this absent resource list.
*
* @param resourceID The resource's ID.
*
* @return YES if the resource is marked as absent, otherwise NO.
*/
- (BOOL) isResourceAbsent:(NSString*)resourceID;

/**
* Marks a specified resource as being absent.
*
* @param resourceID The resource's ID.
*/
- (void) markResourceAbsent:(NSString*)resourceID;

/**
* Marks the resource as not absent if it is currently marked as absent. This method removes the specified resource
* from this absent resource list.
*
* @param resourceID The resource's ID.
*/
- (void) unmarkResourceAbsent:(NSString*)resourceID;

@end