/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import <WWTiledImageLayer.h>
#import "ImageLayerDetailController.h"
#import "WorldWind/WWLog.h"
#import "WorldWind/WorldWindConstants.h"

@implementation ImageLayerDetailController

- (ImageLayerDetailController*) initWithLayer:(WWTiledImageLayer*)layer
{
    if (layer == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Layer is nil")
    }

    self = [super initWithStyle:UITableViewStyleGrouped];

    _layer = layer;

    return self;
}

- (NSInteger) numberOfSectionsInTableView:(UITableView*)tableView
{
    return 1;
}

- (NSInteger) tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section
{
    switch (section)
    {
        case 0:
            return 1;
        default:
            return 0;
    }
}

- (NSString*) tableView:(UITableView*)tableView titleForHeaderInSection:(NSInteger)section
{
    if (section == 0)
    {
        return @"Layer Controls";
    }

    return @"Empty";
}

- (UITableViewCell*) tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
    UITableViewCell* cell = nil;

    if ([indexPath section] == 0)
    {
        static NSString* layerControlCellIdentifier = @"LayerControlCellIdentifier";
        static NSInteger sliderTag = 1;

        cell = [tableView dequeueReusableCellWithIdentifier:layerControlCellIdentifier];
        if (cell == nil)
        {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:layerControlCellIdentifier];
            [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
            [[cell textLabel] setText:@"Opacity"];
            UISlider* slider = [[UISlider alloc] init];
            [slider setTag:sliderTag];
            [slider addTarget:self action:@selector(opacityValueChanged:) forControlEvents:UIControlEventValueChanged];
            [cell setAccessoryView:slider];
            [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
        }

        // Initialize slider to the layer's current value.
        UISlider* slider = (UISlider*) [[cell accessoryView] viewWithTag:sliderTag];
        [slider setValue:[_layer opacity]];
    }

    return cell;
}

- (void) opacityValueChanged:(UISlider*)opacitySlider
{
    [_layer setOpacity:[opacitySlider value]];

    NSNotification* redrawNotification = [NSNotification notificationWithName:WW_REQUEST_REDRAW object:self];
    [[NSNotificationCenter defaultCenter] postNotification:redrawNotification];
}
@end