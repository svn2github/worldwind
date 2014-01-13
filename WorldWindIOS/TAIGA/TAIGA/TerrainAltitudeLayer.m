/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import <CoreLocation/CoreLocation.h>
#import "TerrainAltitudeLayer.h"
#import "AppConstants.h"
#import "WorldWind/WorldWindView.h"

@implementation TerrainAltitudeLayer

- (TerrainAltitudeLayer*)init
{
    self = [super init];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleCurrentPositionNotification:)
                                                 name:TAIGA_CURRENT_AIRCRAFT_POSITION object:nil];

    return self;
}

- (void) handleCurrentPositionNotification:(NSNotification*)notification
{
    CLLocation* position = [notification object];

    if ([self redThreshold] == [position altitude])
        return; // no need for a change

    float warningOffset = [self redThreshold] - [self yellowThreshold];

    [self setRedThreshold:(float)[position altitude]];
    [self setYellowThreshold:[self redThreshold] - warningOffset];

    [WorldWindView requestRedraw];
}

@end