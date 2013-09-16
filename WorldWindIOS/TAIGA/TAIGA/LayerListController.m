/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import "LayerListController.h"
#import "WorldWindView.h"
#import "WorldWindConstants.h"
#import "WWRenderableLayer.h"
#import "WWTiledImageLayer.h"
#import "WWSceneController.h"
#import "WWLayerList.h"
#import "ImageLayerDetailController.h"
#import "RenderableLayerDetailController.h"
#import "WWElevationShadingLayer.h"
#import "TerrainAltitudeController.h"

@implementation LayerListController

- (LayerListController*) initWithWorldWindView:(WorldWindView*)wwv
{
    self = [super initWithStyle:UITableViewStylePlain];

    _wwv = wwv;

    [[self navigationItem] setTitle:@"Overlays"];
    [self setContentSizeForViewInPopover:CGSizeMake(320, 400)];

    // Set up to handle layer list changes.
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleNotification:)
                                                 name:WW_LAYER_LIST_CHANGED
                                               object:nil];

    return self;
}

- (void) navigationController:(UINavigationController*)navigationController willShowViewController:(UIViewController*)viewController animated:(BOOL)animated
{
    // This keeps all the nested popover controllers the same size as this top-level controller.
    viewController.contentSizeForViewInPopover = navigationController.topViewController.view.frame.size;
}

- (NSInteger) numberOfSectionsInTableView:(UITableView*)tableView
{
    return 1;
}

- (NSInteger) tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section
{
    return [[[_wwv sceneController] layers] count];
}

- (void) tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath
{
    // Set the selected layer's visibility.

    WWLayer* layer = [[[_wwv sceneController] layers] layerAtIndex:(NSUInteger) [indexPath row]];
    [layer setEnabled:[layer enabled] ? NO : YES];
    [[self tableView] reloadData];
    [self requestRedraw];
}

- (UITableViewCell*) tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
    static NSString* cellIdentifier = @"cell";

    UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (cell == nil)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
        [[cell imageView] setImage:[UIImage imageNamed:@"431-yes.png"]];
        [cell setAccessoryType:UITableViewCellAccessoryDetailDisclosureButton];
        [cell setShowsReorderControl:YES];
    }

    WWLayer* layer = [[[_wwv sceneController] layers] layerAtIndex:(NSUInteger) [indexPath row]];
    [[cell textLabel] setText:[layer displayName]];
    [[cell imageView] setHidden:![layer enabled]];

    return cell;
}

- (void) tableView:(UITableView*)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath*)indexPath
{
    // Create and show a detail controller for the tapped layer.

    WWLayer* layer = [[[_wwv sceneController] layers] layerAtIndex:(NSUInteger) [indexPath row]];

    if ([layer isKindOfClass:[WWTiledImageLayer class]])
    {
        ImageLayerDetailController* detailController =
                [[ImageLayerDetailController alloc] initWithLayer:(WWTiledImageLayer*) layer];
        [detailController setTitle:[layer displayName]];

        [((UINavigationController*) [self parentViewController]) pushViewController:detailController animated:YES];
    }
    else if ([layer isKindOfClass:[WWRenderableLayer class]])
    {
        RenderableLayerDetailController* detailController =
                [[RenderableLayerDetailController alloc] initWithLayer:(WWRenderableLayer*) layer];
        [detailController setTitle:[layer displayName]];

        [((UINavigationController*) [self parentViewController]) pushViewController:detailController animated:YES];
    }
    else if ([layer isKindOfClass:[WWElevationShadingLayer class]])
    {
        TerrainAltitudeController* detailController =
                [[TerrainAltitudeController alloc] initWithLayer:(WWElevationShadingLayer*) layer];

        [((UINavigationController*) [self parentViewController]) pushViewController:detailController animated:YES];
    }
}

- (void) requestRedraw
{
    [[NSNotificationCenter defaultCenter] postNotificationName:WW_REQUEST_REDRAW object:self];
}

- (void) handleNotification:(NSNotification*)notification
{
    if ([[notification name] isEqualToString:WW_LAYER_LIST_CHANGED])
    {
        [[self tableView] reloadData];
    }
}
@end