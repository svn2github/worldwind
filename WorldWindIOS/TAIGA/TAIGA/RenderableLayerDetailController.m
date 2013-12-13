/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import <WWRenderableLayer.h>
#import "WorldWind/WWLog.h"
#import "WorldWind/WorldWindConstants.h"
#import "RenderableLayerDetailController.h"
#import "Settings.h"
#import "RedrawingSlider.h"

@implementation RenderableLayerDetailController
{
    UIBarButtonItem* refreshButton;
}

- (RenderableLayerDetailController*) initWithLayer:(WWRenderableLayer*)layer refreshButtonEnabled:(BOOL)refreshButtonEnabled
{
    if (layer == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Layer is nil")
    }

    self = [super initWithStyle:UITableViewStyleGrouped];

    _layer = layer;

    if (refreshButtonEnabled)
    {
        refreshButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"01-refresh"]
                                                         style:UIBarButtonItemStylePlain
                                                        target:self action:@selector(handleRefreshButtonTap)];
        [[self navigationItem] setRightBarButtonItem:refreshButton];

        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(handleRefreshNotification:)
                                                     name:WW_REFRESH_COMPLETE
                                                   object:_layer];
    }

    return self;
}

- (NSInteger) numberOfSectionsInTableView:(UITableView*)tableView
{
    return 2;
}

- (NSInteger) tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section
{
    switch (section)
    {
        case 0:
            return 1;
        case 1:
            return [[_layer renderables] count];
        default:
            return 0;
    }
}

- (NSString*) tableView:(UITableView*)tableView titleForHeaderInSection:(NSInteger)section
{
    switch (section)
    {
        case 0:
            return @"Layer Controls";
        case 1:
            return @"Layer Contents";
        default:
            return @"Empty";
    }
}

- (UITableViewCell*) tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
    UITableViewCell* cell = nil;

    if ([indexPath section] == 0)
    {
        static NSString* layerControlOpacityCellIdentifier = @"LayerControlOpacityCellIdentifier";
        static NSInteger sliderTag = 1;

        if ([indexPath row] == 0)
        {
            cell = [tableView dequeueReusableCellWithIdentifier:layerControlOpacityCellIdentifier];
            if (cell == nil)
            {
                cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:layerControlOpacityCellIdentifier];
                [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
                [[cell textLabel] setText:@"Opacity"];
                RedrawingSlider* slider = [[RedrawingSlider alloc] init];
                [slider setTag:sliderTag];
                [slider addTarget:self action:@selector(opacityValueChanged:) forControlEvents:UIControlEventValueChanged];
                [cell setAccessoryView:slider];
            }

            // Initialize slider to the layer's current value.
            UISlider* slider = (UISlider*) [[cell accessoryView] viewWithTag:sliderTag];
            [slider setValue:[_layer opacity]];
        }
    }
    else if ([indexPath section] == 1)
    {
        static NSString* layerContentsCellIdentifier = @"LayerContentsCellIdentifier";

        cell = [tableView dequeueReusableCellWithIdentifier:layerContentsCellIdentifier];
        if (cell == nil)
        {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:layerContentsCellIdentifier];
            [[cell imageView] setImage:[UIImage imageNamed:@"431-yes.png"]];
        }

        id <WWRenderable> r = [[_layer renderables] objectAtIndex:(NSUInteger) [indexPath row]];
        NSString* displayName = [r displayName];
        [[cell textLabel] setText:displayName != nil ? displayName : @"Renderable"];
        [[cell imageView] setHidden:![r enabled]];
    }

    return cell;
}

- (void) tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath
{
    if ([indexPath section] == 0)
    {
        [[NSNotificationCenter defaultCenter] postNotificationName:WW_REQUEST_REDRAW object:_layer];
    }
    else if ([indexPath section] == 1) // the list of renderables
    {
        // Set the selected renderables's visibility.
        id <WWRenderable> renderable = [[_layer renderables] objectAtIndex:(NSUInteger) [indexPath row]];
        [renderable setEnabled:[renderable enabled] ? NO : YES];
        [Settings setBool:[renderable enabled] forName:
                [[NSString alloc] initWithFormat:@"gov.nasa.worldwind.taiga.layer.renderable.enabled.%@", [renderable displayName]]];
        [[self tableView] reloadData];
        [self requestRedraw];
    }
}

- (void) opacityValueChanged:(UISlider*)opacitySlider
{
    [_layer setOpacity:[opacitySlider value]];
}

- (void) handleRefreshButtonTap
{
    [[NSNotificationCenter defaultCenter] postNotificationName:WW_REFRESH object:_layer];
}

- (void) requestRedraw
{
    [[NSNotificationCenter defaultCenter] postNotificationName:WW_REQUEST_REDRAW object:self];
}

- (void) handleRefreshNotification:(NSNotification*)notification
{
    if ([[notification name] isEqualToString:WW_REFRESH_COMPLETE] && [notification object] == _layer)
    {
        [[self tableView] reloadData];
    }
}

@end