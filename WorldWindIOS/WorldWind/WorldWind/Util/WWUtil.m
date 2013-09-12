/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import <UIKit/UIKit.h>
#import "WorldWind/Util/WWUtil.h"
#import "WorldWind/WWLog.h"

@implementation WWUtil

+ (NSString*) generateUUID
{
    // Taken from here: http://stackoverflow.com/questions/8684551/generate-a-uuid-string-with-arc-enabled

    CFUUIDRef uuid = CFUUIDCreate(NULL);
    NSString* uuidStr = (__bridge_transfer NSString*) CFUUIDCreateString(NULL, uuid);
    CFRelease(uuid);

    return uuidStr;
}
//
//+ (BOOL) retrieveUrl:(NSURL*)url toFile:(NSString*)filePath timeout:(NSTimeInterval)timeout
//{
//    if (url == nil)
//    {
//        WWLOG_AND_THROW(NSInvalidArgumentException, @"URL is nil")
//    }
//
//    if (filePath == nil || [filePath length] == 0)
//    {
//        WWLOG_AND_THROW(NSInvalidArgumentException, @"File path is nil or empty")
//    }
//
//    // Get the data from the URL.
//    NSData* data = [self retrieveUrl:url timeout:timeout];
//    if (data == nil)
//    {
//        return NO;
//    }
//
//    // Ensure that the directory for the file exists.
//    NSError* error = nil;
//    NSString* pathDir = [filePath stringByDeletingLastPathComponent];
//    [[NSFileManager defaultManager] createDirectoryAtPath:pathDir
//                              withIntermediateDirectories:YES attributes:nil error:&error];
//    if (error != nil)
//    {
//        WWLog("@Error \"%@\" creating path %@", [error description], filePath);
//        return NO;
//    }
//
//    // Write the data to the file.
//    [data writeToFile:filePath options:NSDataWritingAtomic error:&error];
//    if (error != nil)
//    {
//        WWLog("@Error \"%@\" writing file %@", [error description], filePath);
//        return NO;
//    }
//
//    return YES;
//}
//
//+ (NSData*) retrieveUrl:(NSURL*)url timeout:(NSTimeInterval)timeout
//{
//    if (url == nil)
//    {
//        WWLOG_AND_THROW(NSInvalidArgumentException, @"URL is nil")
//    }
//
//    @try
//    {
//        [WorldWind setNetworkBusySignalVisible:YES];
//
//        // Get the data from the URL.
//        NSURLRequest* request = [[NSURLRequest alloc] initWithURL:url
//                                                      cachePolicy:NSURLRequestReloadIgnoringLocalCacheData
//                                                  timeoutInterval:timeout];
//        NSURLResponse* response;
//        NSError* error = nil;
//        NSData* data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
//        if (error != nil)
//        {
//            WWLog("@Error \"%@\" retrieving %@", [error description], [url absoluteString]);
//        }
//
//        return data;
//    }
//    @finally
//    {
//        [WorldWind setNetworkBusySignalVisible:NO];
//    }
//}

+ (NSString*) suffixForMimeType:(NSString*)mimeType
{
    if ([@"image/png" isEqualToString:mimeType])
        return @"png";

    if ([@"image/jpeg" isEqualToString:mimeType])
        return @"jpg";

    return nil;
}

+ (NSString*) replaceSuffixInPath:(NSString*)path newSuffix:(NSString*)newSuffix
{
    if (newSuffix == nil)
    {
        return [path stringByDeletingPathExtension];
    }

    return [[path stringByDeletingPathExtension] stringByAppendingPathExtension:newSuffix];
}

+ (NSString*) makeValidFilePath:(NSString*)path
{
    if (path == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Path is nil")
    }

    // TODO: Verify that this set of characters is the correct set of invalid file name characters.
    NSString* filePath = [path stringByReplacingOccurrencesOfString:@"/" withString:@"_"];
    filePath = [filePath stringByReplacingOccurrencesOfString:@"?" withString:@"_"];
    filePath = [filePath stringByReplacingOccurrencesOfString:@":" withString:@"_"];
    filePath = [filePath stringByReplacingOccurrencesOfString:@"*" withString:@"_"];

    return filePath;
}

+ (UIImage*) convertPDFToUIImage:(NSURL*)pdfURL
{
    if (pdfURL == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"PDF URL is nil")
    }

    CGPDFDocumentRef pdf = CGPDFDocumentCreateWithURL((__bridge CFURLRef) pdfURL);
    CGPDFPageRef pdfPage = CGPDFDocumentGetPage(pdf, 1);
    CGRect rect = CGPDFPageGetBoxRect(pdfPage, kCGPDFCropBox);

    UIGraphicsBeginImageContextWithOptions( rect.size, NO, [ UIScreen mainScreen ].scale );
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    CGContextGetCTM( ctx );
    CGContextScaleCTM( ctx, 1, -1 );
    CGContextTranslateCTM( ctx, 0, -rect.size.height );
    CGContextScaleCTM( ctx, 1, 1 );
    CGContextTranslateCTM( ctx, -rect.origin.x, -rect.origin.y );
    CGContextDrawPDFPage( ctx, pdfPage );
    CGPDFDocumentRelease( pdf );

    UIImage* pdfImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return pdfImage;
}

@end