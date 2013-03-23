/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import "WorldWind/Layer/WWLayerList.h"
#import "WorldWind/Layer/WWLayer.h"
#import "WorldWind/WWLog.h"

@implementation WWLayerList

- (WWLayerList*) init
{
    self = [super init];

    self->layers = [[NSMutableArray alloc] init];

    return self;
}

- (NSUInteger) count
{
    return [self->layers count];
}

- (WWLayer*)layerAtIndex:(NSUInteger)index
{
    return (WWLayer*) [self->layers objectAtIndex:index];
}

- (void) addLayer:(WWLayer*) layer
{
    if (layer == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Layer is nil")
    }

    [self->layers addObject:layer];
}

- (void) insertLayer:(WWLayer*)layer atIndex:(NSUInteger)atIndex
{
    if (layer == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Layer is nil")
    }

    [self->layers insertObject:layer atIndex:atIndex];
}

- (void) removeLayer:(WWLayer*)layer
{
    if (layer == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Layer is nil")
    }

    [layers removeObject:layer];
}

@end
