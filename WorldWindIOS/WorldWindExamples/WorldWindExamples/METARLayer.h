/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import <Foundation/Foundation.h>
#import "WorldWind/Layer/WWRenderableLayer.h"

@interface METARLayer : WWRenderableLayer <NSXMLParserDelegate>
{
    NSMutableDictionary* currentPlacemark;
    NSString* currentName;
    NSMutableString* currentString;
    NSString* iconFilePath;
    NSMutableArray* placemarks;
}

- (METARLayer*) init;

@end