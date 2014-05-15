/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import "ImageLayerDetailController.h"
#import "RedrawingSlider.h"
#import "Settings.h"
#import "WorldWind/Layer/WWTiledImageLayer.h"
#import "WorldWind/WorldWindView.h"
#import "WorldWind/WWLog.h"
#import "WorldWind.h"

@implementation ImageLayerDetailController

- (ImageLayerDetailController*) initWithLayer:(WWTiledImageLayer*)layer
{
    if (layer == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Layer is nil")
    }

    self = [super initWithStyle:UITableViewStyleGrouped];

    _layer = layer;

    // Uncomment below four lines to implement a refresh button. Currently see no reason to do that.
//    UIBarButtonItem* refreshButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"01-refresh"]
//                                                                      style:UIBarButtonItemStylePlain
//                                                                     target:self action:@selector(handleRefreshButtonTap)];
//    [[self navigationItem] setRightBarButtonItem:refreshButton];

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
            RedrawingSlider* slider = [[RedrawingSlider alloc] init];
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

    NSString* settingName = [[NSString alloc] initWithFormat:@"gov.nasa.worldwind.taiga.layer.%@.opacity",
                                                             [_layer displayName]];
    [Settings setFloat:[_layer opacity] forName:settingName];
}

- (void) handleRefreshButtonTap
{
    if ([WorldWind isNetworkAvailable])
    {
        [_layer setExpiration:[[NSDate alloc] initWithTimeIntervalSinceNow:-1]];
        [WorldWindView requestRedraw];
    }
    else
    {
        UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:@"Unable to Refresh"
                                                            message:@"Cannot refresh layer because network is unavailable"
                                                           delegate:self
                                                  cancelButtonTitle:@"Dismiss"
                                                  otherButtonTitles:nil];
        [alertView show];
    }
}

@end