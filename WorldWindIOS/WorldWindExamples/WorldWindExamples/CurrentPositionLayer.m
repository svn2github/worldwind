/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.

 @version $Id$
 */

#import "CurrentPositionLayer.h"
#import "LocationServicesController.h"
#import "WorldWind/Geometry/WWPosition.h"
#import "WorldWind/Render/WWDrawContext.h"
#import "WorldWind/Shapes/WWShapeAttributes.h"
#import "WorldWind/Shapes/WWSphere.h"
#import "WorldWind/Util/WWColor.h"
#import "WorldWind/WorldWindConstants.h"

@implementation CurrentPositionLayer

- (CurrentPositionLayer*) init
{
    self = [super init];

    [self setDisplayName:@"Current Position"];
    [self setEnabled:NO]; // disable the marker until we have a valid aircraft position

    _marker = [self createMarker];
    [self addRenderable:_marker];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(currentPositionDidChange:)
                                                 name:WW_CURRENT_POSITION object:nil];

    return self;
}

- (id) createMarker
{
    WWShapeAttributes* attrs = [[WWShapeAttributes alloc] init];
    [attrs setInteriorColor:[[WWColor alloc] initWithR:.24 g:.47 b:.99 a:1]];

    WWSphere* shape = [[WWSphere alloc] initWithPosition:[[WWPosition alloc] init] radiusInPixels:5];
    [shape setAttributes:attrs];

    return shape;
}

- (void) updateMarker:(id)marker
{
    [(WWSphere*) marker setPosition:forecastPosition];
    [(WWSphere*) marker setAltitudeMode:[currentLocation verticalAccuracy] < 0 ?
            WW_ALTITUDE_MODE_CLAMP_TO_GROUND : WW_ALTITUDE_MODE_ABSOLUTE];
}

- (void) doRender:(WWDrawContext*)dc
{
    [self forecastCurrentLocationWithDate:[dc timestamp] onGlobe:[dc globe]];
    [self updateMarker:_marker];

    [super doRender:dc];
}

- (void) currentPositionDidChange:(NSNotification*)notification
{
    if (![self enabled]) // display this layer once we have a fix on the current location
    {
        [self setEnabled:YES];
    }

    currentLocation = [notification object];
    [[NSNotificationCenter defaultCenter] postNotificationName:WW_REQUEST_REDRAW object:self];
}

- (void) forecastCurrentLocationWithDate:(NSDate*)date onGlobe:(WWGlobe*)globe
{
    if (forecastPosition == nil)
    {
        forecastPosition = [[WWPosition alloc] initWithZeroPosition];
    }

    [WWPosition forecastPosition:currentLocation forDate:date onGlobe:globe outputPosition:forecastPosition];
}

@end