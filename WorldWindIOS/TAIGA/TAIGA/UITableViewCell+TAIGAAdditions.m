/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.

 @version $Id$
 */

#import "UITableViewCell+TAIGAAdditions.h"
#import "FlightRoute.h"
#import "WorldWind/Util/WWColor.h"

@implementation UITableViewCell (TAIGAAdditions)

- (void) setToFlightRoute:(FlightRoute*)flightRoute
{
    if (flightRoute == nil)
    {
        return;
    }

    NSDictionary* colorAttrs = [[FlightRoute flightRouteColors] objectAtIndex:[flightRoute colorIndex]];

    [[self imageView] setImage:[UIImage imageNamed:@"431-yes.png"]];
    [[self imageView] setHidden:![flightRoute enabled]];
    [[self textLabel] setAdjustsFontSizeToFitWidth:YES];
    [[self textLabel] setText:[flightRoute displayName]];
    [[self detailTextLabel] setText:[colorAttrs objectForKey:@"displayName"]];
    [[self detailTextLabel] setTextColor:[[colorAttrs objectForKey:@"color"] uiColor]];
}

@end