/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.

 @version $Id$
 */

#import "RedrawingSlider.h"
#import "WorldWind/WorldWindConstants.h"

@implementation RedrawingSlider

- (void) dealloc
{
    if (displayLink != nil)
    {
        [displayLink invalidate];
        displayLink = nil;
        displayLinkObservers = 0;
    }
}

- (BOOL) beginTrackingWithTouch:(UITouch*)touch withEvent:(UIEvent*)event
{
    BOOL track = [super beginTrackingWithTouch:touch withEvent:event];

    if (track)
    {
        [self startDisplayLink];
    }

    return track;
}

- (void) endTrackingWithTouch:(UITouch*)touch withEvent:(UIEvent*)event
{
    [super endTrackingWithTouch:touch withEvent:event];

    // Stop the display link and redraw the view. This handles the case where the last touch event occurs before the
    // display link has a chance to fire and cause a redraw.
    [self stopDisplayLink];
    [self redraw];
}

- (void) cancelTrackingWithEvent:(UIEvent*)event
{
    [super cancelTrackingWithEvent:event];

    // Stop the display link and redraw the view. This handles the case where the last touch event occurs before the
    // display link has a chance to fire and cause a redraw.
    [self stopDisplayLink];
    [self redraw];
}

- (void) redraw
{
    [[NSNotificationCenter defaultCenter] postNotificationName:WW_REQUEST_REDRAW object:self];
}

- (void) startDisplayLink
{
    if (displayLinkObservers == 0)
    {
        displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(displayLinkDidFire)];
        [displayLink setFrameInterval:3]; // redraw every 20 ms
        [displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    }

    displayLinkObservers++;
}

- (void) stopDisplayLink
{
    displayLinkObservers--;

    if (displayLinkObservers == 0)
    {
        [displayLink invalidate];
        displayLink = nil;
    }
}

- (void) displayLinkDidFire
{
    [self redraw];
}

@end