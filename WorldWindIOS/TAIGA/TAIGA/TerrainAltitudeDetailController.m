/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import "TerrainAltitudeDetailController.h"
#import "WWLog.h"
#import "WWElevationShadingLayer.h"
#import "SliderCellWithReadout.h"
#import "AppConstants.h"
#import "Settings.h"

#define MAX_WARNING_OFFSET_IN_FEET (1000)

@implementation TerrainAltitudeDetailController
{
    SliderCellWithReadout* opacityCell;
    SliderCellWithReadout* warningOffsetCell;
}

- (TerrainAltitudeDetailController*) initWithLayer:(WWElevationShadingLayer*)layer
{
    if (layer == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Layer is nil")
    }

    self = [super initWithStyle:UITableViewStyleGrouped];

    _layer = layer;

    [self setTitle:@"Terrain Altitude"];

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
            return 1;
        default:
            return 0;
    }
}

- (NSString*) tableView:(UITableView*)tableView titleForHeaderInSection:(NSInteger)section
{
    if (section == 0)
        return @"Opacity";
    else if (section == 1)
        return @"Warning Offset";

    return nil;
}

- (UITableViewCell*) tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
    UITableViewCell* cell;

    if ([indexPath section] == 0)
    {
        if (opacityCell == nil)
        {
            opacityCell = [[SliderCellWithReadout alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"OpacitySlider"];
            [[opacityCell slider] addTarget:self action:@selector(opacityValueChanged:) forControlEvents:UIControlEventValueChanged];
        }

        cell = opacityCell;

        // Initialize slider to the layer's current value.
        [[opacityCell slider] setValue:[_layer opacity]];
        [[opacityCell readout] setText:[self opacityString]];
    }
    else if ([indexPath section] == 1)
    {
        if (warningOffsetCell == nil)
        {
            warningOffsetCell = [[SliderCellWithReadout alloc] initWithStyle:UITableViewCellStyleDefault
                                                             reuseIdentifier:@"warningOffsetSlider"];
            [[warningOffsetCell slider] setMinimumTrackTintColor:[UIColor yellowColor]];
            [[warningOffsetCell slider] addTarget:self action:@selector(warningOffsetValueChanged:) forControlEvents:UIControlEventValueChanged];
        }

        cell = warningOffsetCell;

        // Initialize slider to the layer's current value.
        float offsetInFeet = ([_layer redThreshold] - [_layer yellowThreshold]) * TAIGA_METERS_TO_FEET;
        [[warningOffsetCell slider] setValue:offsetInFeet / MAX_WARNING_OFFSET_IN_FEET];
        [[warningOffsetCell readout] setText:[self warningOffsetString]];
    }

    return cell;
}

- (void) opacityValueChanged:(UISlider*)opacitySlider
{
    [_layer setOpacity:[opacitySlider value]];
    [Settings setFloat:[opacitySlider value] forName:TAIGA_SHADED_ELEVATION_OPACITY];
    [[opacityCell readout] setText:[self opacityString]];
}

- (void) warningOffsetValueChanged:(UISlider*)slider
{
    float offsetInMeters = [slider value] * MAX_WARNING_OFFSET_IN_FEET / TAIGA_METERS_TO_FEET;
    [_layer setYellowThreshold:[_layer redThreshold] - offsetInMeters];
    [Settings setFloat:offsetInMeters forName:TAIGA_SHADED_ELEVATION_OFFSET];
    [[warningOffsetCell readout] setText:[self warningOffsetString]];
}

- (NSString*) opacityString
{
    return [[NSString alloc] initWithFormat:@"%d%%", (int) ([_layer opacity] * 100)];
}

- (NSString*) warningOffsetString
{
    return [[NSString alloc] initWithFormat:@"%d\u2032", (int) round(([_layer redThreshold] - [_layer yellowThreshold]) * TAIGA_METERS_TO_FEET)];
}
@end