/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import "CompassLayer.h"
#import "WorldWind/Shapes/WWScreenImage.h"
#import "WorldWind/Util/WWOffset.h"
#import "WorldWind/Util/WWSize.h"
#import "WorldWind/Render/WWDrawContext.h"
#import "WorldWind/Navigate/WWNavigatorState.h"

@implementation CompassLayer

- (CompassLayer*) init
{
    self = [super init];

    [self setDisplayName:@"Compass"];

    NSString* imagePath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"notched-compass.png"];
    WWOffset* offset = [[WWOffset alloc] initWithInsetPixelsX:130 y:130];
    WWSize* size = [[WWSize alloc] initWithPixelsWidth:120 height:120];

    WWScreenImage* screenImage = [[WWScreenImage alloc] initWithScreenOffset:offset imagePath:imagePath];
    [screenImage setImageSize:size];
    [self addRenderable:screenImage];

    return self;
}

- (void) doRender:(WWDrawContext*)dc
{
    WWScreenImage* screenImage = [[self renderables] objectAtIndex:0];

    id <WWNavigatorState> nav_state = [dc navigatorState];
    [screenImage setImageRotation:-[nav_state heading]];
    [screenImage setImageTilt:0.9 * [nav_state tilt]];

    [super doRender:dc];
}

@end