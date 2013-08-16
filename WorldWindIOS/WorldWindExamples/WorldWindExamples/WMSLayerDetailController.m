/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import "WMSLayerDetailController.h"
#import "WorldWind/Util/WWWMSCapabilities.h"
#import "WorldWind/WorldWindView.h"
#import "WorldWind/Layer/WWWMSTiledImageLayer.h"
#import "WorldWind/Render/WWSceneController.h"
#import "WorldWind/Layer/WWLayerList.h"
#import "WorldWind/WorldWindConstants.h"
#import "WorldWind/WWLog.h"
#import "WebViewController.h"
#import "WorldWind/Geometry/WWSector.h"
#import "WorldWind/Util/WWWMSDimension.h"
#import "WorldWind/Layer/WWWMSDimensionedLayer.h"

@implementation WMSLayerDetailController

- (WMSLayerDetailController*) initWithLayerCapabilities:(WWWMSCapabilities*)serverCapabilities
                                      layerCapabilities:(NSDictionary*)layerCapabilities
                                                 wwView:(WorldWindView*)wwv;
{
    if (serverCapabilities == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Server capabilities is nil.")
    }

    if (layerCapabilities == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Layer capabilities is nil.")
    }

    if (wwv == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"World Wind View is nil.")
    }

    self = [super initWithStyle:UITableViewStyleGrouped];

    [[self navigationItem] setTitle:@"Layer Detail"];

    _serverCapabilities = serverCapabilities;
    _layerCapabilities = layerCapabilities;
    _wwv = wwv;

    // Create a layer ID for named layers. The ID is used to identify the layer in the WW layer list.
    NSString* layerName = [WWWMSCapabilities layerName:_layerCapabilities];
    if (layerName != nil)
    {
        isNamedLayer = YES;
        NSString* getMapURL = [_serverCapabilities getMapURL];
        NSMutableString* lid = [[NSMutableString alloc] initWithString:getMapURL];
        [lid appendString:layerName];
        layerID = lid;
    }

    NSArray* layers = [WWWMSCapabilities layers:_layerCapabilities];
    if (layers != nil)
    {
        hasLayers = YES;
    }

    NSDictionary* legendCaps = [WWWMSCapabilities layerFirstLegendURL:_layerCapabilities];
    if (legendCaps != nil && [WWWMSCapabilities legendHref:legendCaps] != nil)
    {
        hasLegend = YES;
    }

    dataSection = 0;
    controlSection = isNamedLayer ? 1 : -1;
    layerSection = hasLayers ? (isNamedLayer ? 2 : 1) : -1;

    doneButton = [[UIBarButtonItem alloc] initWithTitle:@"Servers"
                                                  style:UIBarButtonItemStylePlain
                                                 target:self action:@selector(handleReturnButtonTap)];
    [[self navigationItem] setRightBarButtonItem:doneButton];

    return self;
}

- (void) handleReturnButtonTap
{
    [[self navigationController] popToRootViewControllerAnimated:NO];
}

- (NSInteger) numberOfSectionsInTableView:(UITableView*)tableView
{
    int numSections = 1; // there's always a data section

    if (isNamedLayer)
        ++numSections; // the controls section

    if (hasLayers)
        ++numSections; // the layers section

    return numSections;
}

- (NSInteger) tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == controlSection)
        return 1;

    if (section == dataSection)
        return 2;

    if (section == layerSection)
        return [[WWWMSCapabilities layers:_layerCapabilities] count];

    return 0;
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

    if (section == layerSection)
        return @"Layers";

    return nil;
}

- (UITableViewCell*) tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
    if ([indexPath section] == controlSection)
    {
        return [self cellForControlSection:tableView indexPath:indexPath];
    }

    if ([indexPath section] == dataSection)
    {
        return [self cellForDataSection:tableView indexPath:indexPath];
    }

    if ([indexPath section] == layerSection)
    {
        return [self cellForLayerList:tableView indexPath:indexPath];
    }

    return nil;
}

- (UITableViewCell*) cellForControlSection:(UITableView*)tableView indexPath:(NSIndexPath*)indexPath
{
    UITableViewCell* cell = nil;

    if ([indexPath row] == 0)
    {
        cell = [self switchCellForLayerEnable:tableView];
    }

    return cell;
}

- (UITableViewCell*) cellForDataSection:(UITableView*)tableView indexPath:(NSIndexPath*)indexPath
{
    static NSString* expansionCell = @"dataCell";

    UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:expansionCell];
    if (cell == nil)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:expansionCell];
        [cell setAccessoryType:UITableViewCellAccessoryDisclosureIndicator];
    }

    [cell setSelectionStyle:UITableViewCellSelectionStyleNone];

    if ([indexPath row] == 0)
    {
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
        [[cell textLabel] setText:@"More Info"];

        if ([self hasMoreInfo])
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

- (UITableViewCell*) switchCellForLayerEnable:(UITableView*)tableView
{
    static NSString* switchCell = @"switchCellForLayerEnable";

    UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:switchCell];
    if (cell == nil)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:switchCell];

        UISwitch* layerSwitch = [[UISwitch alloc] init];
        [layerSwitch addTarget:self action:@selector(handleShowLayerSwitch:)
              forControlEvents:UIControlEventValueChanged];
        WWLayer* layer = [self findLayerByLayerID];
        if (layer != nil)
        {
            [layerSwitch setOn:YES];
        }
        [cell setAccessoryView:[[UIView alloc] initWithFrame:[layerSwitch frame]]];
        [[cell accessoryView] addSubview:layerSwitch];
        [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
    }

    [[cell textLabel] setText:@"Show Layer"];

    return cell;
}

- (void) tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath
{
    if ([indexPath section] == dataSection)
    {
        [self buttonTappedForDataSection:indexPath];
    }
    else if ([indexPath section] == layerSection)
    {
        [self buttonTappedForLayersSection:indexPath];
    }
}

- (void) tableView:(UITableView*)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath*)indexPath
{
    if ([indexPath section] == dataSection)
    {
        [self buttonTappedForDataSection:indexPath];
    }
    else if ([indexPath section] == layerSection)
    {
        [self buttonTappedForLayersSection:indexPath];
    }
}

- (void) buttonTappedForDataSection:(NSIndexPath*)indexPath
{
    if ([indexPath row] == 0)
    {
        NSString* abstract = [WWWMSCapabilities layerAbstract:_layerCapabilities];
        if (abstract == nil)
            return;

        WebViewController* detailController = [[WebViewController alloc] initWithFrame:[[self tableView] frame]];
        [[detailController navigationItem] setTitle:@"Abstract"];
        [[detailController webView] loadHTMLString:abstract baseURL:nil];
        [((UINavigationController*) [self parentViewController]) pushViewController:detailController animated:YES];
    }
    else if ([indexPath row] == 1)
    {
        [self showMoreInfoView];
    }
}

- (void) buttonTappedForLayersSection:(NSIndexPath*)indexPath
{
    NSArray* layers = [WWWMSCapabilities layers:_layerCapabilities];
    NSDictionary* layerCaps = [layers objectAtIndex:(NSUInteger) [indexPath row]];

    WMSLayerDetailController* detailController =
            [[WMSLayerDetailController alloc] initWithLayerCapabilities:_serverCapabilities
                                                      layerCapabilities:layerCaps
                                                                 wwView:_wwv];
    [detailController setContentSizeForViewInPopover:[self contentSizeForViewInPopover]];
    [((UINavigationController*) [self parentViewController]) pushViewController:detailController animated:YES];
}

- (void) handleShowLayerSwitch:(UISwitch*)layerSwitch
{
    @try
    {
        if ([layerSwitch isOn])
        {
            WWLayer* layer;
            if ([WWWMSCapabilities layerDimension:_layerCapabilities] == nil)
            {
                layer = [[WWWMSTiledImageLayer alloc] initWithWMSCapabilities:_serverCapabilities
                                                            layerCapabilities:_layerCapabilities];
            }
            else
            {
                layer = [[WWWMSDimensionedLayer alloc] initWithWMSCapabilities:_serverCapabilities
                                                            layerCapabilities:_layerCapabilities];
                [((WWWMSDimensionedLayer*) layer) setEnabledLayerNumber:0];
            }

            if (layer == nil)
                return;

            [[layer userTags] setObject:layerID forKey:@"layerid"];
            [layer setEnabled:YES];
            if (hasLegend)
                [layer setLegendEnabled:YES];

            [[[_wwv sceneController] layers] addLayer:layer];
        }
        else
        {
            WWLayer* layer = [self findLayerByLayerID];
            if (layer != nil)
            {
                [layer setEnabled:NO];
                [[[_wwv sceneController] layers] removeLayer:layer];
            }
        }
        NSNotification* redrawNotification = [NSNotification notificationWithName:WW_REQUEST_REDRAW object:self];
        [[NSNotificationCenter defaultCenter] postNotification:redrawNotification];
    }
    @catch (NSException* exception)
    {
        WWLogE(@"Exception attempting to add layer to layer list", exception);
    }
}

- (WWLayer*) findLayerByLayerID
{
    NSArray* layerList = [[[_wwv sceneController] layers] allLayers];
    for (WWLayer* layer in layerList)
    {
        NSString* lid = [[layer userTags] objectForKey:@"layerid"];
        if (lid != nil && [lid isEqualToString:layerID])
        {
            return layer;
        }
    }

    return nil;
}

- (BOOL) hasMoreInfo
{
    if ([WWWMSCapabilities layerName:_layerCapabilities] != nil)
        return YES;

    if ([WWWMSCapabilities layerDataURLs:_layerCapabilities] != nil)
        return YES;

    if ([_serverCapabilities layerGeographicBoundingBox:_layerCapabilities] != nil)
        return YES;

    if ([WWWMSCapabilities layerKeywords:_layerCapabilities])
        return YES;

    if ([WWWMSCapabilities layerMinScaleDenominator:_layerCapabilities] != nil)
        return YES;

    if ([WWWMSCapabilities layerMaxScaleDenominator:_layerCapabilities] != nil)
        return YES;

    return NO;
}

- (void) showMoreInfoView
{
    WebViewController* detailController = [[WebViewController alloc] initWithFrame:[[self tableView] frame]];
    [[detailController navigationItem] setTitle:@"Layer Info"];

    NSMutableString* htmlString = [[NSMutableString alloc] init];

    NSString* name = [WWWMSCapabilities layerName:_layerCapabilities];
    if (name != nil && [name length] > 0)
    {
        [htmlString appendString:@"<b>Name:</b> "];
        [htmlString appendString:name];
        [htmlString appendFormat:@"<br><br>"];
    }

    NSArray* dataURLs = [WWWMSCapabilities layerDataURLs:_layerCapabilities];
    if (dataURLs != nil && [dataURLs count] > 0)
    {
        for (NSString* dataURL in dataURLs)
        {
            [htmlString appendString:@"<b>Data URL:</b> "];
            [htmlString appendString:[self wrapLink:dataURL]];
            [htmlString appendFormat:@"<br><br>"];
        }
    }

    NSArray* metadataURLs = [WWWMSCapabilities layerMetadataURLs:_layerCapabilities];
    if (metadataURLs != nil && [metadataURLs count] > 0)
    {
        for (NSString* dataURL in metadataURLs)
        {
            [htmlString appendString:@"<b>Metadata URL:</b> "];
            [htmlString appendString:[self wrapLink:dataURL]];
            [htmlString appendFormat:@"<br><br>"];
        }
    }

    WWSector* bbox = [_serverCapabilities layerGeographicBoundingBox:_layerCapabilities];
    if (bbox != nil)
    {
        NSMutableArray* tableData = [[NSMutableArray alloc] initWithCapacity:8];
        [tableData addObject:@"Min Latitude"];
        [tableData addObject:[[NSString alloc] initWithFormat:@"%f", [bbox minLatitude]]];
        [tableData addObject:@"Max Latitude"];
        [tableData addObject:[[NSString alloc] initWithFormat:@"%f", [bbox maxLatitude]]];
        [tableData addObject:@"Min Longitude"];
        [tableData addObject:[[NSString alloc] initWithFormat:@"%f", [bbox minLongitude]]];
        [tableData addObject:@"Max Longitude"];
        [tableData addObject:[[NSString alloc] initWithFormat:@"%f", [bbox maxLongitude]]];

        [htmlString appendFormat:@"<b>Bounding Box</b>:"];
        [htmlString appendString:[self twoColumnTable:tableData]];
        [htmlString appendFormat:@"<br>"];
    }

    NSNumber* minScale = [WWWMSCapabilities layerMinScaleDenominator:_layerCapabilities];
    if (minScale != nil)
    {
        [htmlString appendFormat:@"<b>Min Scale:</b> %f<br>", [minScale doubleValue]];
    }

    NSNumber* maxScale = [WWWMSCapabilities layerMaxScaleDenominator:_layerCapabilities];
    if (minScale != nil)
    {
        [htmlString appendFormat:@"<b>Max Scale:</b> %f<br><br>", [maxScale doubleValue]];
    }

    NSArray* keywords = [WWWMSCapabilities layerKeywords:_layerCapabilities];
    if (keywords != nil && [keywords count] > 0)
    {
        [htmlString appendFormat:@"<b>Keywords</b>:"];
        [htmlString appendString:[self oneColumnTable:keywords]];
        [htmlString appendFormat:@"<br>"];
    }

    if ([htmlString length] > 0)
    {
        [[detailController webView] loadHTMLString:htmlString baseURL:nil];
        [((UINavigationController*) [self parentViewController]) pushViewController:detailController animated:YES];
    }
}

- (NSString*) wrapLink:(NSString*)url
{
    NSMutableString* htmlString = [[NSMutableString alloc] init];

    [htmlString appendString:@"<a href=\""];
    [htmlString appendString:url];
    [htmlString appendString:@"\">"];
    [htmlString appendString:url];
    [htmlString appendString:@"</a>"];

    return htmlString;
}

- (NSString*) oneColumnTable:(NSArray*)data
{
    NSMutableString* htmlString = [[NSMutableString alloc] initWithString:@"<table>"];

    for (NSString* dataObject in data)
    {
        [htmlString appendString:@"<tr>"];
        [htmlString appendFormat:@"<td>%@</td>", dataObject];
    }

    [htmlString appendString:@"</table>"];

    return htmlString;
}

- (NSString*) twoColumnTable:(NSArray*)data
{
    NSMutableString* htmlString = [[NSMutableString alloc] initWithString:@"<table border=\"0\">"];

    for (NSUInteger i = 0; i < [data count]; i += 2)
    {
        [htmlString appendString:@"<tr>"];
        [htmlString appendFormat:@"<td>%@</td>", [data objectAtIndex:i]];
        [htmlString appendFormat:@"<td>%@</td>", i + 1 < [data count] ? [data objectAtIndex:i + 1] : @""];
        [htmlString appendString:@"</tr>"];
    }

    [htmlString appendString:@"</table>"];

    return htmlString;
}

@end