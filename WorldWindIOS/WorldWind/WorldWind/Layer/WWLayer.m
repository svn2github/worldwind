/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import "WorldWind/Layer/WWLayer.h"
#import "WorldWind/Render/WWDrawContext.h"
#import "WorldWind/Geometry/WWPosition.h"

@implementation WWLayer

- (WWLayer*) init
{
    self = [super init];

    _displayName = @"Layer";
    _enabled = YES;
    _pickEnabled = YES;
    _opacity = 1;
    _minActiveAltitude = -DBL_MAX;
    _maxActiveAltitude = DBL_MAX;
    _networkRetrievalEnabled = YES;
    _userTags = [[NSMutableDictionary alloc] initWithCapacity:1]; // minimize size in case it's not used

    return self;
}

- (void) dispose
{
    // Override in subclasses to clean up when called.
}

- (void) render:(WWDrawContext *)dc
{
    if (!_enabled)
        return;

    if ([dc pickingMode] && !_pickEnabled)
        return;

    if (![self isLayerActive:dc])
        return;

    if (![self isLayerInView:dc])
        return;

    [self doRender:dc];
}

- (void) doRender:(WWDrawContext*)dc
{
    // Default implementation does nothing.
}

- (BOOL) isLayerActive:(WWDrawContext*)dc
{
    WWPosition* eyePosition = [dc eyePosition];
    if (eyePosition == nil)
    {
        return false;
    }

    double eyeAltitude = [eyePosition altitude];

    return eyeAltitude >= [self minActiveAltitude] && eyeAltitude <= [self maxActiveAltitude];
}

- (BOOL) isLayerInView:(WWDrawContext*)dc
{
    return YES; // Default implementation always returns YES.
}

@end
