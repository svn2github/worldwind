/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import "LayerDetailController.h"
#import "WorldWind/Layer/WWLayer.h"
#import "WorldWind/WorldWindConstants.h"
#import "WorldWind/WWLog.h"
#import "WWRenderableLayer.h"

@implementation LayerDetailController

- (LayerDetailController*) initWithLayer:(WWLayer*)layer
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
    return 1;
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
    static NSString* cellIdentifier = @"LayerDetailController.Opacity.cell";
    static NSInteger sliderTag = 1;

    UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (cell == nil)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
        [[cell textLabel] setText:@"Opacity"];
        UISlider* slider = [[UISlider alloc] init];
        [slider setTag:sliderTag];
        [slider addTarget:self action:@selector(opacityValueChanged:) forControlEvents:UIControlEventValueChanged];
        [cell setAccessoryView:slider];
    }

    // Initialize slider to the layer's current value.
    UISlider* slider = (UISlider*) [[cell accessoryView] viewWithTag:sliderTag];
    [slider setValue:[_layer opacity]];

    if ([_layer isKindOfClass:[WWRenderableLayer class]])
    {
        [slider setHidden:YES];
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