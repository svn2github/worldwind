/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import "WorldWind/Layer/WWLayerList.h"
#import "WorldWind/Layer/WWLayer.h"
#import "WorldWind/WWLog.h"
#import "WorldWindConstants.h"

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

- (NSArray*) allLayers
{
    return [[NSArray alloc] initWithArray:layers];
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
    [self notifyLayerListChange];
}

- (void) insertLayer:(WWLayer*)layer atIndex:(NSUInteger)atIndex
{
    if (layer == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Layer is nil")
    }

    [self->layers insertObject:layer atIndex:atIndex];
    [self notifyLayerListChange];
}

- (void) removeLayer:(WWLayer*)layer
{
    if (layer == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Layer is nil")
    }

    [layers removeObject:layer];
    [self notifyLayerListChange];
}

- (void) removeLayerAtRow:(int)rowIndex
{
    if (rowIndex < 0 || rowIndex >= [layers count])
    {
        NSString* msg = [[NSString alloc] initWithFormat:@"Row index %d is out of range", rowIndex];
        WWLOG_AND_THROW(NSInvalidArgumentException, msg)
    }

    WWLayer* layer = [layers objectAtIndex:(NSUInteger)rowIndex];
    [self removeLayer:layer];
    [self notifyLayerListChange];
}

- (void) moveLayerAtRow:(int)fromIndex toRow:(int)toIndex
{
    if (fromIndex < 0 || fromIndex >= [layers count])
    {
        NSString* msg = [[NSString alloc] initWithFormat:@"From index %d is out of range", fromIndex];
        WWLOG_AND_THROW(NSInvalidArgumentException, msg)
    }

    if (toIndex < 0 || toIndex >= [layers count])
    {
        NSString* msg = [[NSString alloc] initWithFormat:@"To index %d is out of range", toIndex];
        WWLOG_AND_THROW(NSInvalidArgumentException, msg)
    }

    WWLayer* layer = [layers objectAtIndex:(NSUInteger)fromIndex];

    [layers removeObjectAtIndex:(NSUInteger)fromIndex];
    [layers insertObject:layer atIndex:(NSUInteger)toIndex];
    [self notifyLayerListChange];
}

- (void) notifyLayerListChange
{
    NSNotification* redrawNotification = [NSNotification notificationWithName:WW_LAYER_LIST_CHANGED object:self];
    [[NSNotificationCenter defaultCenter] postNotification:redrawNotification];
}

@end
