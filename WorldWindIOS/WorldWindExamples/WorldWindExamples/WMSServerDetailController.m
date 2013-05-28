/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import "WMSServerDetailController.h"
#import "WorldWind/Util/WWWMSCapabilities.h"
#import "WMSLayerDetailController.h"
#import "TextViewController.h"
#import "WorldWindView.h"

@implementation WMSServerDetailController

- (WMSServerDetailController*) initWithCapabilities:(WWWMSCapabilities*)capabilities
                                      serverAddress:(NSString*)serverAddress
                                               size:(CGSize)size
                                             wwview:(WorldWindView*)wwv;
{
    self = [super initWithStyle:UITableViewStyleGrouped];

    [self setContentSizeForViewInPopover:size];

    [[self navigationItem] setTitle:@"Server Detail"];

    _capabilities = capabilities;
    _serverAddress = serverAddress;
    _wwv = wwv;

    return self;
}

- (NSInteger) numberOfSectionsInTableView:(UITableView*)tableView
{
    return 3;
}

- (NSInteger) tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section
{
    switch (section)
    {
        case 0:
            return 1;

        case 1:
            return 1;

        case 2:
            return [_capabilities layers] != nil ? [[_capabilities layers] count] : 0;

        default:
            return 0;
    }
}

- (NSString*) tableView:(UITableView*)tableView titleForHeaderInSection:(NSInteger)section
{
    if (section == 0)
    {
        NSString* headerTitle = [_capabilities serviceTitle];
        return headerTitle != nil ? headerTitle : _serverAddress;
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
        NSString* name = [_capabilities serviceName];
        [[cell detailTextLabel] setText:name != nil ? name : @""];
    }

    return cell;
}

- (UITableViewCell*) cellForExpansionSection:(UITableView*)tableView indexPath:(NSIndexPath*)indexPath
{
    static NSString* cellIdentifier = @"expansionCell";

    NSString* label = nil;
    BOOL hasValue = YES;
    if ([indexPath row] == 0)
    {
        label = @"Abstract";
        hasValue = [_capabilities serviceAbstract] != nil;
    }

    UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (cell == nil)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
        [cell setAccessoryType:UITableViewCellAccessoryDisclosureIndicator];
        [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
    }

    [[cell textLabel] setText:label];

    if (hasValue)
    {
        [cell setAccessoryType:UITableViewCellAccessoryDisclosureIndicator];
        [[cell textLabel] setTextColor:[UIColor blackColor]];
    }
    else
    {
        [[cell textLabel] setTextColor:[UIColor lightGrayColor]];
        [cell setAccessoryType:UITableViewCellAccessoryNone];
    }

    return cell;
}

- (UITableViewCell*) cellForLayerList:(UITableView*)tableView indexPath:(NSIndexPath*)indexPath
{
    static NSString* layerCellWithDetail = @"layerCellWithDetail";
    static NSString* layerCellWithDisclosure = @"layerCellWithDisclosure";

    UITableViewCell* cell = nil;

    NSDictionary* layerCaps = [[_capabilities layers] objectAtIndex:(NSUInteger) [indexPath row]];
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

    NSString* label = [WWWMSCapabilities layerTitle:layerCaps];
    if (label == nil)
    {
        label = [WWWMSCapabilities layerName:layerCaps];
    }
    [[cell textLabel] setText:label != nil ? label : @"Layer"];

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
        NSString* abstract = [_capabilities serviceAbstract];
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
    NSArray* layers = [_capabilities layers];
    NSDictionary* layerCaps = [layers objectAtIndex:(NSUInteger) [indexPath row]];

    WMSLayerDetailController* detailController =
            [[WMSLayerDetailController alloc] initWithLayerCapabilities:_capabilities
                                                      layerCapabilities:layerCaps
                                                                   size:[self contentSizeForViewInPopover]
                                                                 wwView:_wwv];
    [((UINavigationController*) [self parentViewController]) pushViewController:detailController animated:YES];
}

@end