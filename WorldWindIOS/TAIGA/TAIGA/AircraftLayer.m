/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.

 @version $Id$
 */

#import "AircraftLayer.h"
#import "AircraftShape.h"
#import "AppConstants.h"
#import "WorldWind/Geometry/WWLocation.h"
#import "WorldWind/Geometry/WWPosition.h"
#import "WorldWind/Shapes/WWShapeAttributes.h"
#import "WorldWind/Util/WWColor.h"
#import "WorldWind/WorldWindView.h"

@implementation AircraftLayer

- (id) init
{
    self = [super init];

    [self setDisplayName:@"Aircraft"];
    [self setEnabled:NO]; // disable the aircraft shape until we have a valid aircraft position
    [self setPickEnabled:NO];

    aircraftShape = [self createAircraftShape];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(aircraftPositionDidChange:)
                                                 name:TAIGA_CURRENT_AIRCRAFT_POSITION object:nil];

    return self;
}

- (void) doRender:(WWDrawContext*)dc
{
    [aircraftShape render:dc];
}

- (id) createAircraftShape
{
    WWShapeAttributes* shapeAttrs = [[WWShapeAttributes alloc] init];
//    [shapeAttrs setInteriorColor:[[WWColor alloc] initWithR:0.027 g:0.596 b:0.976 a:1]];
    [shapeAttrs setInteriorColor:[[WWColor alloc] initWithR:1.0 g:0 b:0 a:1]];
    [shapeAttrs setOutlineColor:[[WWColor alloc] initWithR:1 g:1 b:1 a:1]];
    [shapeAttrs setOutlineWidth:2];

    AircraftShape* shape = [[AircraftShape alloc] initWithSizeInPixels:30 minSize:10 maxSize:DBL_MAX];
    [shape setAlwaysOnTop:YES];
    [shape setAttributes:shapeAttrs];

    return shape;
}

- (void) updateAircraftShape:(id)shape withLocation:(CLLocation*)location
{
    WWPosition* position = [[WWPosition alloc] initWithCLPosition:location];
    [(AircraftShape*) shape setPosition:position];
    [(AircraftShape*) shape setHeading:[location course]];
}

- (void) aircraftPositionDidChange:(NSNotification*)notification
{
    if (![self enabled]) // enable this layer once we have a fix on the current location
    {
        [self setEnabled:YES];
    }

    CLLocation* location = [notification object];
    [self updateAircraftShape:aircraftShape withLocation:location];
    [WorldWindView requestRedraw];
}

@end