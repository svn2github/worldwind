/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import <Foundation/Foundation.h>
#import "WorldWind/Layer/WWRenderableLayer.h"

@class WWPosition;

@interface CrashDataLayer : WWRenderableLayer <NSXMLParserDelegate>
{
    NSMutableDictionary* currentPlacemark;
    NSMutableString* currentName;
    NSMutableString* currentString;
    NSString* iconFilePath;
    NSMutableArray* placemarks;
}

- (CrashDataLayer*) initWithURL:(NSString*)urlString;

@end