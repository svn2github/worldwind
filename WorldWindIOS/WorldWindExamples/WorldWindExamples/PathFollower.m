/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import "PathFollower.h"
#import "WorldWind/Shapes/WWPath.h"
#import "WorldWind/WorldWindView.h"
#import "WorldWind/Shapes/WWSphere.h"
#import "WorldWind/Layer/WWLayer.h"
#import "WorldWind/Layer/WWRenderableLayer.h"
#import "WorldWind/Render/WWSceneController.h"
#import "WorldWind/Layer/WWLayerList.h"
#import "WorldWind/Geometry/WWPosition.h"
#import "WorldWind/Util/WWMath.h"
#import "WorldWind/Terrain/WWGlobe.h"
#import "WorldWind/Shapes/WWShapeAttributes.h"
#import "WorldWind/Util/WWColor.h"

@implementation PathFollower

- (PathFollower*) initWithPath:(WWPath*)path speed:(double)speed view:(WorldWindView*)view
{
    self = [super init];

    _path = path;
    _speed = speed;
    _wwv = view;

    [self createLayerAndMarker];

    return self;
}

- (void) dispose
{
    [layer removeRenderable:marker];
    [[[_wwv sceneController] layers] removeLayer:layer];

    if (timer != nil)
    {
        [timer invalidate];
        timer = nil;
    }
}

- (void) createLayerAndMarker
{
    WWPosition* firstPosition = [[_path positions] objectAtIndex:0];
    marker = [[WWSphere alloc] initWithPosition:firstPosition radiusInPixels:5];

    WWShapeAttributes* attributes = [[WWShapeAttributes alloc] init];
    [attributes setInteriorEnabled:YES];
    [attributes setInteriorColor:[[WWColor alloc] initWithR:.24 g:.47 b:.99 a:1]];
    [marker setAttributes:attributes];

    layer = [[WWRenderableLayer alloc] init];
    [layer setDisplayName:@"Path Marker"];
    [layer addRenderable:marker];

    [[[_wwv sceneController] layers] addLayer:layer];
}

- (void) start
{
    startTime = [[NSDate alloc] init];

    timer = [NSTimer scheduledTimerWithTimeInterval:0.2 // update at 5 Hz
                                             target:self
                                           selector:@selector(timerDidFire:)
                                           userInfo:nil repeats:YES];
}

- (void) stop
{
    [timer invalidate];
    timer = nil;
}

- (void) timerDidFire:(NSTimer*)notifyingTimer
{
    WWPosition* position = [self computePositionForNow];

    if (position == nil)
    {
        [self stop];
    }
    else
    {
        [marker setPosition:position];
        [_wwv drawView];
    }
}

- (WWPosition*) computePositionForNow
{
    double elapsedTime = fabs([startTime timeIntervalSinceNow]);
    double distanceTraveled = _speed * elapsedTime;

    double remainingDistance = distanceTraveled;
    WWPosition* previousPathPosition = [[_path positions] objectAtIndex:0];

    for (NSUInteger i = 1; i < [[_path positions] count]; i++)
    {
        WWPosition* nextPathPosition = [[_path positions] objectAtIndex:i];

        double segmentDistance = [WWPosition rhumbDistance:previousPathPosition endLocation:nextPathPosition];
        segmentDistance = RADIANS(segmentDistance);
        segmentDistance *= [[[_wwv sceneController] globe] equatorialRadius];
        if (remainingDistance - segmentDistance > 0) // current position is beyond this segment
        {
            remainingDistance -= segmentDistance;
            previousPathPosition = nextPathPosition;
            continue;
        }

        if (remainingDistance - segmentDistance == 0)
        {
            return nextPathPosition;
        }

        // remainingDistance - segmentDistance < 0 ==> current position is within this segment
        double s = remainingDistance / segmentDistance;
        WWPosition* outputPosition = [[WWPosition alloc] init];
        [WWPosition rhumbInterpolate:previousPathPosition
                         endLocation:nextPathPosition
                              amount:s
                      outputLocation:outputPosition];
        double altitude = 0.5 * ([previousPathPosition altitude] + [nextPathPosition altitude]);
        [outputPosition setAltitude:altitude];
        return outputPosition;
    }

    return nil;
}

@end