/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import <Foundation/Foundation.h>

/**
* Provides a collection of utility methods.
*/
@interface WWUtil : NSObject

/// @name I/O and Caching

/**
* Retrieves the data designated by a URL and saves it in a local file.
*
* @param url The URL from which to retrieve the data.
* @param filePath The full path of the file in which to save the data. The directories in the path need not exist,
* they will be created.
*
* @return YES if the operation was successful, otherwise NO. A log message is written if the operation is
* unsuccessful.
*
* @exception NSInvalidArgumentException if the url or file path are nil or the file path is empty.
*/
+ (BOOL) retrieveUrl:(NSURL*)url toFile:(NSString*)filePath;

/// @name Other Utilities

/**
* Generate a unique string.
*
* @return A unique string.
*/
+ (NSString*) generateUUID;

/**
* Returns the suffix for a specified mime type.
*
* @param mimeType The mime type, e.g. _image/png_.
*
* @return The suffix for the mime type, including the ".", e.g. _.png_, or nil if the mime type is not recognized.
*/
+ (NSString*) suffixForMimeType:(NSString*)mimeType;

+ (NSString*) replaceSuffixInPath:(NSString*)path newSuffix:(NSString*)newSuffix;

@end