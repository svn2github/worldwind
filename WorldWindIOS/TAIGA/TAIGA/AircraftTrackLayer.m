/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.

 @version $Id$
 */

#import <CoreLocation/CoreLocation.h>
#import "AircraftTrackLayer.h"
#import "AppConstants.h"
#import "WorldWind/Geometry/WWPosition.h"
#import "WorldWind/Render/WWDrawContext.h"
#import "WorldWind/Shapes/WWPath.h"
#import "WorldWind/Shapes/WWShapeAttributes.h"
#import "WorldWind/Shapes/WWSphere.h"
#import "WorldWind/Util/WWColor.h"
#import "WorldWind/Util/WWMath.h"
#import "WorldWind/WorldWindView.h"

@implementation AircraftTrackLayer

- (id) init
{
    self = [super init];

    [self setDisplayName:@"Aircraft Tracks"];
    [self setPickEnabled:NO];

    WWColor* color = [[WWColor alloc] initWithR:0.027 g:0.596 b:0.976 a:1];
    shapeAttrs = [[WWShapeAttributes alloc] init];
    [shapeAttrs setInteriorColor:color];
    [shapeAttrs setOutlineColor:color];
    [shapeAttrs setOutlineWidth:2];

    markers = [[NSMutableArray alloc] init];
    _markerDistance = 304.8; // default to 1000ft

    NSUserDefaults* userState = [NSUserDefaults standardUserDefaults];
    NSDictionary* propertyList = [userState objectForKey:@"gov.nasa.worldwind.taiga.aircraftTrackLayer"];
    if (propertyList != nil)
    {
        [self restoreWithPropertyList:propertyList];
    }

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(locationTrackingDidChange:)
                                                 name:TAIGA_LOCATION_TRACKING_ENABLED object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(aircraftPositionDidChange:)
                                                 name:TAIGA_CURRENT_AIRCRAFT_POSITION object:nil];

    return self;
}

- (void) restoreWithPropertyList:(NSDictionary*)propertyList
{
    NSArray* markerPositions = [propertyList objectForKey:@"markerPositions"];
    NSNumber* markerDistance = [propertyList objectForKey:@"markerDistance"];
    markers = [[NSMutableArray alloc] init];
    _markerDistance = [markerDistance doubleValue];

    for (NSUInteger i = 0; i < [markerPositions count]; i += 3)
    {
        double lat = [[markerPositions objectAtIndex:i] doubleValue];
        double lon = [[markerPositions objectAtIndex:i + 1] doubleValue];
        double alt = [[markerPositions objectAtIndex:i + 2] doubleValue];
        WWPosition* pos = [[WWPosition alloc] initWithDegreesLatitude:lat longitude:lon altitude:alt];
        [self addMarkerWithPosition:pos];
    }
}

- (NSDictionary*) asPropertyList
{
    NSMutableArray* markerPositions = [[NSMutableArray alloc] initWithCapacity:3 * [markers count]];
    for (id marker in markers)
    {
        WWPosition* pos = [(WWSphere*) marker position];
        [markerPositions addObject:[NSNumber numberWithDouble:[pos latitude]]];
        [markerPositions addObject:[NSNumber numberWithDouble:[pos longitude]]];
        [markerPositions addObject:[NSNumber numberWithDouble:[pos altitude]]];
    }

    return @{
        @"markerPositions" : markerPositions,
        @"markerDistance" : [NSNumber numberWithDouble:_markerDistance]
    };
}

- (void) removeAllMarkers
{
    [markers removeAllObjects];
    unmarkedDistance = 0;

    [self saveState];
    [WorldWindView requestRedraw];
}

- (void) saveState
{
    if (!savingState) // throttle state saves to once per second
    {
        [self performSelector:@selector(doSaveState) withObject:nil afterDelay:1.0];
        savingState = YES;
    }
}

- (void) doSaveState
{
    NSDictionary* propertyList = [self asPropertyList];
    NSUserDefaults* userState = [NSUserDefaults standardUserDefaults];
    [userState setObject:propertyList forKey:@"gov.nasa.worldwind.taiga.aircraftTrackLayer"];
    [userState synchronize];
    savingState = NO;
}

- (void) doRender:(WWDrawContext*)dc
{
    for (id marker in markers)
    {
        [marker render:dc];
    }
}

- (void) locationTrackingDidChange:(NSNotification*)notification
{
    locationTrackingEnabled = [[notification object] boolValue];

    if (!locationTrackingEnabled)
    {
        if (_position != nil && unmarkedDistance > 0) // mark the current location when tracking is disabled
        {
            [self addMarkerWithPosition:_position];
            [self saveState];
            [WorldWindView requestRedraw];
        }

        _position = nil;
        unmarkedDistance = 0;
    }
}

- (void) aircraftPositionDidChange:(NSNotification*)notification
{
    if (locationTrackingEnabled)
    {
        WWPosition* oldPosition = _position;
        WWPosition* newPosition = [[WWPosition alloc] initWithCLPosition:[notification object]];
        _position = newPosition;

        [self didUpdateToPosition:newPosition fromPosition:oldPosition];
    }
}

- (void) didUpdateToPosition:(WWPosition*)newPosition fromPosition:(WWPosition*)oldPosition
{
    if (oldPosition != nil)
    {
        double distanceDegrees = [WWLocation greatCircleDistance:oldPosition endLocation:newPosition];
        double distanceMeters = RADIANS(distanceDegrees) * 6378137; // equatorial radius of Earth
        unmarkedDistance += distanceMeters;
    }

    if (oldPosition == nil || unmarkedDistance >= _markerDistance)
    {
        [self addMarkerWithPosition:newPosition];
        [self saveState];
        [WorldWindView requestRedraw];
        unmarkedDistance = 0;
    }
}

- (void) addMarkerWithPosition:(WWPosition*)position
{
    WWSphere* marker = [[WWSphere alloc] initWithPosition:position radiusInPixels:4 minRadius:1 maxRadius:DBL_MAX];
    [marker setAttributes:shapeAttrs];
    [markers addObject:marker];
}

@end