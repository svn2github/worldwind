/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.

 @version $Id$
 */

#import "WaypointLayer.h"
#import "Waypoint.h"
#import "WaypointFile.h"
#import "WorldWind/Geometry/WWPosition.h"
#import "WorldWind/Geometry/WWVec4.h"
#import "WorldWind/Navigate/WWNavigatorState.h"
#import "WorldWind/Render/WWDrawContext.h"
#import "WorldWind/Shapes/WWPointPlacemark.h"
#import "WorldWind/Shapes/WWPointPlacemarkAttributes.h"
#import "WorldWind/Terrain/WWGlobe.h"
#import "WorldWind/Util/WWMath.h"
#import "WorldWind/Util/WWOffset.h"
#import "WorldWind/WorldWind.h"

#define HIGHLIGHT_NEAR_DIST (450e3)
#define HIGHLIGHT_FAR_DIST (550e3)
#define HIGHLIGHT_NEAR_SCALE (1.0)
#define HIGHLIGHT_FAR_SCALE (0.25)

@implementation WaypointLayer

- (WaypointLayer*) init
{
    self = [super init];

    return self;
}

- (void) setWaypoints:(WaypointFile*)waypointFile
{
    if (waypointFile == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Waypoint file is nil")
    }

    [self removeAllRenderables];

    WWPointPlacemarkAttributes* attrs = [[WWPointPlacemarkAttributes alloc] init];
    [attrs setImagePath:[[NSBundle mainBundle] pathForResource:@"airport@small" ofType:@"png"]];
    [attrs setImageOffset:[[WWOffset alloc] initWithFractionX:0.5 y:0.5]];

    for (Waypoint* waypoint in [waypointFile waypoints])
    {
        if ([waypoint type] != WaypointTypeAirport)
            continue;

        WWPosition* pos = [[WWPosition alloc] initWithLocation:[waypoint location] altitude:0];
        WWPointPlacemark* placemark = [[WWPointPlacemark alloc] initWithPosition:pos];
        [placemark setUserObject:waypoint];
        [placemark setDisplayName:[waypoint displayName]];
        [placemark setAltitudeMode:WW_ALTITUDE_MODE_CLAMP_TO_GROUND];
        [placemark setAttributes:attrs];
        [self addRenderable:placemark];
    }

    [[WorldWind loadQueue] addOperationWithBlock:^{
        [self assembleWaypointImages];
    }];
}

- (void) assembleWaypointImages
{
    NSString* highlightImageDir = NSTemporaryDirectory();
    NSError* error = nil;
    [[NSFileManager defaultManager] createDirectoryAtPath:highlightImageDir
                              withIntermediateDirectories:YES attributes:nil error:&error];
    if (error != nil)
    {
        NSDictionary* userInfo = [error userInfo];
        NSString* errMsg = [[userInfo objectForKey:NSUnderlyingErrorKey] localizedDescription];
        WWLog(@"Error %@ creating waypoint image directory %@", errMsg, highlightImageDir);
        return;
    }

    UIImage* templateImage = [UIImage imageNamed:@"airport@large"];
    CGSize templateSize = [templateImage size];

    NSDictionary* fontAttrs = @{NSFontAttributeName:[UIFont systemFontOfSize:[UIFont labelFontSize]]};
    NSDictionary* smallFontAttrs = @{NSFontAttributeName:[UIFont systemFontOfSize:[UIFont systemFontSize] - 3]};

    WWOffset* highlightImageOffset = [[WWOffset alloc] initWithFractionX:0.5 y:0.0];

    @try
    {
        UIGraphicsBeginImageContext(templateSize);
        CGContextRef gc = UIGraphicsGetCurrentContext();

        for (WWPointPlacemark* placemark in [self renderables])
        {
            Waypoint* waypoint = [placemark userObject];
            NSString* displayName = [waypoint displayName];
            NSDictionary* textAttrs = fontAttrs;
            CGSize textSize = [displayName sizeWithAttributes:textAttrs];

            if (textSize.width > 36)
            {
                textAttrs = smallFontAttrs;
                textSize = [displayName sizeWithAttributes:textAttrs];
            }

            CGContextClearRect(gc, CGRectMake(0, 0, templateSize.width, templateSize.height));
            [templateImage drawAtPoint:CGPointMake(0, 0)];
            [displayName drawAtPoint:CGPointMake((templateSize.width - textSize.width) / 2, (templateSize.height - textSize.height) / 2)
               withAttributes:textAttrs];

            UIImage* highlightImage = UIGraphicsGetImageFromCurrentImageContext();
            NSData* highlightImageData = UIImagePNGRepresentation(highlightImage);
            NSString* highlightImagePath = [highlightImageDir stringByAppendingPathComponent:[[NSProcessInfo processInfo] globallyUniqueString]];
            [highlightImageData writeToFile:highlightImagePath atomically:YES];

            WWPointPlacemarkAttributes* highlightAttrs = [[WWPointPlacemarkAttributes alloc] init];
            [highlightAttrs setImagePath:highlightImagePath];
            [highlightAttrs setImageOffset:highlightImageOffset];
            [placemark performSelectorOnMainThread:@selector(setHighlightAttributes:) withObject:highlightAttrs waitUntilDone:NO];
        }
    }
    @finally
    {
        UIGraphicsEndImageContext();
        [[NSNotificationCenter defaultCenter] postNotificationName:WW_REQUEST_REDRAW object:self];
    }
}

- (void) doRender:(WWDrawContext*)dc
{
    WWVec4* eyePoint = [[dc navigatorState] eyePoint];
    WWVec4* placemarkPoint = [[WWVec4 alloc] init];
    WWGlobe* globe = [dc globe];

    for (WWPointPlacemark* placemark in [self renderables])
    {
        WWPosition* pos = [placemark position];
        WWPointPlacemarkAttributes* highlightAttrs = [placemark highlightAttributes];

        [globe computePointFromPosition:[pos latitude] longitude:[pos longitude] altitude:[pos altitude] outputPoint:placemarkPoint];
        double d = [placemarkPoint distanceTo3:eyePoint];

        BOOL highlight = d < HIGHLIGHT_FAR_DIST && highlightAttrs != nil;
        [placemark setHighlighted:highlight];

        if (highlight)
        {
            double dnorm = [WWMath smoothStepValue:d min:HIGHLIGHT_NEAR_DIST max:HIGHLIGHT_FAR_DIST];
            double scale = [WWMath interpolateValue1:HIGHLIGHT_NEAR_SCALE value2:HIGHLIGHT_FAR_SCALE amount:dnorm];
            [highlightAttrs setImageScale:scale];
        }

        [placemark render:dc];
    }
}

@end