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
    NSXMLParser* docParser;
    NSMutableDictionary* currentPlacemark;
    NSMutableString* currentName;
    NSMutableString* currentString;
}

- (CrashDataLayer*) initWithURL:(NSString*)urlString;

@end