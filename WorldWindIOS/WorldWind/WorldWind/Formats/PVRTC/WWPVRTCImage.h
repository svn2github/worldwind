/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import <Foundation/Foundation.h>

/**
* Represents an image in PVRTC compressed format.
*/
@interface WWPVRTCImage : NSObject

/// @name PVRTC Image Attributes

/// The file path of the PVRTC image.
@property (nonatomic, readonly) NSString* filePath;

/// The PVRTC image's width.
@property (nonatomic, readonly) int imageWidth;

/// The PVRTC image's height.
@property (nonatomic, readonly) int imageHeight;

/// The PVRTC image's data, including its header.
@property (nonatomic, readonly) NSData* imageBits;

/// The number of mipmap levels in the image.
@property (nonatomic, readonly) int numLevels;

/// @name Initializing PVRTC Textures

/**
* Initializes this instance to the PVRTC image in a specified file.
*
* @param filePath The full path to the PVRTC image file.
*
* @return This instance initialized with the specified image.
*
* @exception NSInvalidArgumentException If the specified file path is nil or empty, the specified file does not
* exist or the file is not a PVRTC image.
*/
- (WWPVRTCImage*) initWithContentsOfFile:(NSString*)filePath;

/// @name Compressing PVRTC Textures

/**
* Compress the image in a specified file and save it as a PVRTC image.
*
* The compressed image is written to the same location and has the same name as the specified image but with a file
* name extension of _pvr_.
*
* @param filePath The file containing the image to compress.
*
* @return YES if compression was successful, otherwise NO.
*
* @exception NSInvalidArgumentException If the specified file path is nil or empty or the file does not exist.
*/
+ (void) compressFile:(NSString*)filePath;

@end