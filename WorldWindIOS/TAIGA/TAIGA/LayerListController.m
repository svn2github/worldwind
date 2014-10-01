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
#import "WWElevationShadingLayer.h"
#import "TerrainAltitudeDetailController.h"
#import "AppConstants.h"
#import "Settings.h"
#import "PIREPLayer.h"
#import "METARLayer.h"
#import "RenderableLayerDetailController.h"
#import "WorldWind.h"
#import "WeatherCamLayer.h"
#import "DAFIFLayer.h"
#import "WaypointLayer.h"
#import "AircraftTrackLayer.h"
#import "AircraftTrackDetailController.h"

@implementation LayerListController

- (LayerListController*) initWithWorldWindView:(WorldWindView*)wwv
{
    self = [super initWithStyle:UITableViewStylePlain];

    _wwv = wwv;

    [[self navigationItem] setTitle:@"Overlays"];
    [self setPreferredContentSize:CGSizeMake(320, 500)];

    // Set up to handle layer list changes.
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleNotification:)
                                                 name:WW_LAYER_LIST_CHANGED
                                               object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleRefreshNotification:)
                                                 name:TAIGA_REFRESH_COMPLETE
                                               object:nil];

    return self;
}

- (void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    [[self tableView] flashScrollIndicators];
}

- (void) flashScrollIndicator
{
    [[self tableView] performSelector:@selector(flashScrollIndicators) withObject:nil afterDelay:0];
}

- (NSInteger) numberOfSectionsInTableView:(UITableView*)tableView
{
    return 1;
}

- (NSInteger) tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section
{
    return [[self nonHiddenLayers] count];
}

- (void) tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath
{
    // Set the selected layer's visibility.

    WWLayer* layer = [[self nonHiddenLayers] objectAtIndex:(NSUInteger) [indexPath row]];
    [layer setEnabled:[layer enabled] ? NO : YES];
    [Settings setBool:[layer enabled] forName:
            [[NSString alloc] initWithFormat:@"gov.nasa.worldwind.taiga.layer.enabled.%@", [layer displayName]]];
    [[self tableView] reloadData];
    [WorldWindView requestRedraw];
}

- (UITableViewCell*) tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
    UITableViewCell* cell;
    WWLayer* layer = [[self nonHiddenLayers] objectAtIndex:(NSUInteger) [indexPath row]];

    if ([layer isKindOfClass:[METARLayer class]]
            || [layer isKindOfClass:[PIREPLayer class]])
    {
        static NSString* cellWithRefreshIdentifier = @"cellWithRefreshButton";
        cell = [tableView dequeueReusableCellWithIdentifier:cellWithRefreshIdentifier];

        if (cell == nil)
        {
            UITableViewCellStyle cellStyle = ([layer isKindOfClass:[METARLayer class]]
                    || [layer isKindOfClass:[PIREPLayer class]])
                    ? UITableViewCellStyleSubtitle : UITableViewCellStyleDefault;
            cell = [[UITableViewCell alloc] initWithStyle:cellStyle
                                          reuseIdentifier:cellWithRefreshIdentifier];
            [[cell imageView] setImage:[UIImage imageNamed:@"431-yes.png"]];
            [cell setAccessoryType:UITableViewCellAccessoryDetailButton];
            [cell setShowsReorderControl:YES];

            UIImage* image = [[UIImage imageNamed:@"01-refresh.png"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
            UIButton* refreshButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 25, 30)];
            [refreshButton setImage:image forState:UIControlStateNormal];
            [[refreshButton imageView] setTintColor:[[cell accessoryView] tintColor]];
            [refreshButton addTarget:self action:@selector(handleRefreshButtonTap:)
                    forControlEvents:UIControlEventTouchUpInside];
            [cell setAccessoryView:refreshButton];
        }
    }
    else
    {
        static NSString* cellIdentifier = @"cell";
        cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];

        if (cell == nil)
        {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
            [[cell imageView] setImage:[UIImage imageNamed:@"431-yes.png"]];
            [cell setAccessoryType:UITableViewCellAccessoryDetailButton];
            [cell setShowsReorderControl:YES];
        }
    }

    [[cell textLabel] setText:[layer displayName]];
    [[cell imageView] setHidden:![layer enabled]];
    [[cell accessoryView] setTag:[indexPath row]];

    if ([layer isKindOfClass:[METARLayer class]])
        [[cell detailTextLabel] setText:[self formatDate:[((METARLayer*) layer) lastUpdate]]];
    else if ([layer isKindOfClass:[PIREPLayer class]])
        [[cell detailTextLabel] setText:[self formatDate:[((PIREPLayer*) layer) lastUpdate]]];

    return cell;
}

- (NSString*) formatDate:(NSDate*)date
{
    if (date == nil)
        return @"Select to update";

    NSDateFormatter* formatter = [[NSDateFormatter alloc] init];
    [formatter setDateStyle:NSDateFormatterShortStyle];
    [formatter setTimeStyle:NSDateFormatterShortStyle];

    return [NSString stringWithFormat:@"Updated %@", [formatter stringFromDate:date]];
}

- (void) tableView:(UITableView*)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath*)indexPath
{
    // Create and show a detail controller for the tapped layer.

    WWLayer* layer = [[self nonHiddenLayers] objectAtIndex:(NSUInteger) [indexPath row]];

    if ([layer isKindOfClass:[WWTiledImageLayer class]])
    {
        ImageLayerDetailController* detailController =
                [[ImageLayerDetailController alloc] initWithLayer:(WWTiledImageLayer*) layer];
        [detailController setTitle:[layer displayName]];

        [((UINavigationController*) [self parentViewController]) pushViewController:detailController animated:YES];
    }
    else if ([layer isKindOfClass:[WWRenderableLayer class]])
    {
        bool showRefreshButton = [layer isKindOfClass:[DAFIFLayer class]]
                || [layer isKindOfClass:[WaypointLayer class]]
                || [layer isKindOfClass:[WeatherCamLayer class]];
        RenderableLayerDetailController* detailController =
                [[RenderableLayerDetailController alloc] initWithLayer:(WWRenderableLayer*) layer
                                                  refreshButtonEnabled:showRefreshButton];
        [detailController setTitle:[layer displayName]];

        [((UINavigationController*) [self parentViewController]) pushViewController:detailController animated:YES];
    }
    else if ([layer isKindOfClass:[WWElevationShadingLayer class]])
    {
        TerrainAltitudeDetailController* detailController =
                [[TerrainAltitudeDetailController alloc] initWithLayer:(WWElevationShadingLayer*) layer];

        [((UINavigationController*) [self parentViewController]) pushViewController:detailController animated:YES];
    }
    else if ([layer isKindOfClass:[AircraftTrackLayer class]])
    {
        AircraftTrackDetailController* detailController =
                [[AircraftTrackDetailController alloc] initWithLayer:(AircraftTrackLayer*) layer];
        [((UINavigationController*) [self parentViewController]) pushViewController:detailController animated:YES];
    }
}

- (void) handleRefreshButtonTap:(UIButton*)button
{
    WWLayer* layer = [[self nonHiddenLayers] objectAtIndex:(NSUInteger) [button tag]];

    if (![WorldWind isNetworkAvailable])
    {
        NSString* msg = [[NSString alloc] initWithFormat:@"Cannot refresh %@ because network is unavailable",
                                                         [layer displayName]];
        UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:@"Unable to Refresh"
                                                            message:msg
                                                           delegate:self
                                                  cancelButtonTitle:@"Dismiss"
                                                  otherButtonTitles:nil];
        [alertView show];
    }
    else
    {
        [[NSNotificationCenter defaultCenter] postNotificationName:TAIGA_REFRESH object:layer];
    }

}

- (NSArray*) nonHiddenLayers
{
    NSMutableArray* nonHiddenLayers = [[NSMutableArray alloc] init];

    WWLayerList* layers = [[_wwv sceneController] layers];
    for (NSUInteger i = 0; i < [layers count]; i++)
    {
        WWLayer* layer = [layers layerAtIndex:i];
        if ([[layer userTags] objectForKey:TAIGA_HIDDEN_LAYER] == nil)
        {
            [nonHiddenLayers addObject:layer];
        }
    }

    return nonHiddenLayers;
}

- (void) handleNotification:(NSNotification*)notification
{
    if ([[notification name] isEqualToString:WW_LAYER_LIST_CHANGED])
    {
        [[self tableView] reloadData];
    }
}


- (void) handleRefreshNotification:(NSNotification*)notification
{
    if ([[notification name] isEqualToString:TAIGA_REFRESH_COMPLETE])
    {
        [[self tableView] reloadData];
    }
}

@end