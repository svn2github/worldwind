/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import "WMSLayerDetailController.h"
#import "WorldWind/Util/WWWMSCapabilities.h"
#import "TextViewController.h"

@implementation WMSLayerDetailController

- (WMSLayerDetailController*) initWithLayerCapabilities:(NSDictionary*)capabilities size:(CGSize)size
{
    self = [super initWithStyle:UITableViewStyleGrouped];

    [self setContentSizeForViewInPopover:size];

    [[self navigationItem] setTitle:@"Layer Detail"];

    _layerCapabilities = capabilities;

    return self;
}

- (NSInteger) numberOfSectionsInTableView:(UITableView*)tableView
{
    NSArray* layers = [WWWMSCapabilities layers:_layerCapabilities];

    return layers != nil ? 3 : 2;
}

- (NSInteger) tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section
{
    switch (section)
    {
        case 0:
            return 1;

        case 1:
            return [WWWMSCapabilities layerName:_layerCapabilities] != nil ? 2 : 1;

        case 2:
            return [[WWWMSCapabilities layers:_layerCapabilities] count];

        default:
            return 0;
    }
}

- (NSString*) tableView:(UITableView*)tableView titleForHeaderInSection:(NSInteger)section
{
    if (section == 0)
    {
        NSString* layerTitle = [WWWMSCapabilities layerTitle:_layerCapabilities];
        if (layerTitle != nil)
        {
            return layerTitle;
        }

        NSString* layerName = [WWWMSCapabilities layerName:_layerCapabilities];
        if (layerName != nil)
        {
            return layerName;
        }

        return @"Layer";
    }

    if (section == 1)
    {
        return @"";
    }

    if (section == 2)
    {
        return @"Layers";
    }

    return nil;
}

- (UITableViewCell*) tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
    if ([indexPath section] == 0)
    {
        return [self cellForDetailSection:tableView indexPath:indexPath];
    }

    if ([indexPath section] == 1)
    {
        return [self cellForExpansionSection:tableView indexPath:indexPath];
    }

    if ([indexPath section] == 2)
    {
        return [self cellForLayerList:tableView indexPath:indexPath];
    }

    return nil;
}

- (UITableViewCell*) cellForDetailSection:(UITableView*)tableView indexPath:(NSIndexPath*)indexPath
{
    static NSString* cellIdentifier = @"detailCell";

    UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (cell == nil)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue2 reuseIdentifier:cellIdentifier];
        [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
    }

    if ([indexPath row] == 0)
    {
        [[cell textLabel] setText:@"Name"];
        NSString* name = [WWWMSCapabilities layerName:_layerCapabilities];
        [[cell detailTextLabel] setText:name != nil ? name : @""];
    }

    return cell;
}

- (UITableViewCell*) cellForExpansionSection:(UITableView*)tableView indexPath:(NSIndexPath*)indexPath
{
    static NSString* expansionCell = @"expansionCell";
    static NSString* switchCell = @"switchCell";

    UITableViewCell* cell = nil;

    if ([indexPath row] == 0)
    {
        cell = [tableView dequeueReusableCellWithIdentifier:expansionCell];
        if (cell == nil)
        {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:expansionCell];
            [cell setAccessoryType:UITableViewCellAccessoryDisclosureIndicator];
        }

        [[cell textLabel] setText:@"Abstract"];

        NSString* abstract = [WWWMSCapabilities layerAbstract:_layerCapabilities];
        if (abstract != nil)
        {
            [cell setAccessoryType:UITableViewCellAccessoryDisclosureIndicator];
            [[cell textLabel] setTextColor:[UIColor blackColor]];
        }
        else
        {
            [[cell textLabel] setTextColor:[UIColor lightGrayColor]];
            [cell setAccessoryType:UITableViewCellAccessoryNone];
        }
    }
    else if ([indexPath row] == 1)
    {
        cell = [tableView dequeueReusableCellWithIdentifier:switchCell];
        if (cell == nil)
        {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:switchCell];
            UISwitch* layerSwitch = [[UISwitch alloc] init];
            [cell setAccessoryView:[[UIView alloc] initWithFrame:[layerSwitch frame]]];
            [[cell accessoryView] addSubview:layerSwitch];
        }

        [[cell textLabel] setText:@"Show Layer"];
    }

    return cell;
}

- (UITableViewCell*) cellForLayerList:(UITableView*)tableView indexPath:(NSIndexPath*)indexPath
{
    static NSString* layerCellWithDetail = @"layerCellWithDetail";
    static NSString* layerCellWithDisclosure = @"layerCellWithDisclosure";

    UITableViewCell* cell = nil;

    NSDictionary* layerCaps = [[WWWMSCapabilities layers:_layerCapabilities] objectAtIndex:(NSUInteger) [indexPath row]];
    if ([WWWMSCapabilities layerName:layerCaps] != nil)
    {
        cell = [tableView dequeueReusableCellWithIdentifier:layerCellWithDetail];
        if (cell == nil)
        {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:layerCellWithDetail];
            [cell setAccessoryType:UITableViewCellAccessoryDetailDisclosureButton];
        }
    }
    else
    {
        cell = [tableView dequeueReusableCellWithIdentifier:layerCellWithDisclosure];
        if (cell == nil)
        {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:layerCellWithDisclosure];
            [cell setAccessoryType:UITableViewCellAccessoryDisclosureIndicator];
        }
    }

    [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
    [[cell textLabel] setText:[WWWMSCapabilities layerTitle:layerCaps]];

    return cell;
}

- (void) tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath
{
    if ([indexPath section] == 1)
    {
        [self buttonTappedForDisclosureSection:indexPath];
    }
    else if ([indexPath section] == 2)
    {
        [self buttonTappedForLayersSection:indexPath];
    }
}

- (void) tableView:(UITableView*)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath*)indexPath
{
    if ([indexPath section] == 1)
    {
        [self buttonTappedForDisclosureSection:indexPath];
    }
    else if ([indexPath section] == 2)
    {
        [self buttonTappedForLayersSection:indexPath];
    }
}

- (void) buttonTappedForDisclosureSection:(NSIndexPath*)indexPath
{
    if ([indexPath row] == 0)
    {
        NSString* abstract = [WWWMSCapabilities layerAbstract:_layerCapabilities];
        if (abstract == nil)
            return;

        TextViewController* detailController = [[TextViewController alloc] initWithFrame:[[self tableView] frame]];
        [[detailController navigationItem] setTitle:@"Abstract"];
        [[detailController textView] setText:abstract];
        [((UINavigationController*) [self parentViewController]) pushViewController:detailController animated:YES];
    }
}

- (void) buttonTappedForLayersSection:(NSIndexPath*)indexPath
{
    NSArray* layers = [WWWMSCapabilities layers:_layerCapabilities];
    NSDictionary* layerCaps = [layers objectAtIndex:(NSUInteger) [indexPath row]];

    WMSLayerDetailController* detailController =
            [[WMSLayerDetailController alloc] initWithLayerCapabilities:layerCaps
                                                                   size:[self contentSizeForViewInPopover]];
    [((UINavigationController*) [self parentViewController]) pushViewController:detailController animated:YES];
}

@end