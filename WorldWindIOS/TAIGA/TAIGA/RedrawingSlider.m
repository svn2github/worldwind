/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.

 @version $Id$
 */

#import "RedrawingSlider.h"
#import "WorldWind/WorldWindView.h"

@implementation RedrawingSlider
{
@protected
    NSUInteger trackingCount;
}

- (void) dealloc
{
    if (trackingCount > 0)
    {
        [WorldWindView stopRedrawing];
    }
}

- (BOOL) beginTrackingWithTouch:(UITouch*)touch withEvent:(UIEvent*)event
{
    BOOL track = [super beginTrackingWithTouch:touch withEvent:event];

    if (track && (++trackingCount == 1))
    {
        [WorldWindView startRedrawing];
    }

    return track;
}

- (void) endTrackingWithTouch:(UITouch*)touch withEvent:(UIEvent*)event
{
    [super endTrackingWithTouch:touch withEvent:event];

    if (--trackingCount == 0)
    {
        [WorldWindView stopRedrawing];
    }
}

- (void) cancelTrackingWithEvent:(UIEvent*)event
{
    [super cancelTrackingWithEvent:event];

    if (--trackingCount == 0)
    {
        [WorldWindView stopRedrawing];
    }
}

@end