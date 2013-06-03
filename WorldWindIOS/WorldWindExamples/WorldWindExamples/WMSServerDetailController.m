/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import "WMSServerDetailController.h"
#import "WorldWind/Util/WWWMSCapabilities.h"
#import "WMSLayerDetailController.h"
#import "WorldWind/WorldWindView.h"
#import "WorldWind/WWLog.h"
#import "WebViewController.h"

@implementation WMSServerDetailController

- (WMSServerDetailController*) initWithCapabilities:(WWWMSCapabilities*)capabilities
                                      serverAddress:(NSString*)serverAddress
                                             wwview:(WorldWindView*)wwv;
{
    if (capabilities == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Server capabilities is nil.")
    }

    if (serverAddress == nil || [serverAddress length] == 0)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Server address is nil or empty.")
    }

    if (wwv == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"World Wind View is nil.")
    }

    self = [super initWithStyle:UITableViewStyleGrouped];

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
            return 2;

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
        return @""; // no title for this section
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
        [[cell textLabel] setText:@"Owner"];
        NSString* organization = [_capabilities serviceContactOrganization];
        [[cell detailTextLabel] setText:organization != nil ? organization : @""];
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
    else if ([indexPath row] == 1)
    {
        label = @"More Info";
        hasValue = [self hasMoreInfo];
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

        WebViewController* detailController = [[WebViewController alloc] initWithFrame:[[self tableView] frame]];
        [[detailController navigationItem] setTitle:@"Abstract"];
        [[detailController webView] loadHTMLString:abstract baseURL:nil];
        [((UINavigationController*) [self parentViewController]) pushViewController:detailController animated:YES];
    }
    if ([indexPath row] == 1)
    {
        [self showMoreInfoView];
    }
}

- (void) buttonTappedForLayersSection:(NSIndexPath*)indexPath
{
    NSArray* layers = [_capabilities layers];
    NSDictionary* layerCaps = [layers objectAtIndex:(NSUInteger) [indexPath row]];

    WMSLayerDetailController* detailController =
            [[WMSLayerDetailController alloc] initWithLayerCapabilities:_capabilities
                                                      layerCapabilities:layerCaps
                                                                 wwView:_wwv];
    [detailController setContentSizeForViewInPopover:[self contentSizeForViewInPopover]];
    [((UINavigationController*) [self parentViewController]) pushViewController:detailController animated:YES];
}

- (BOOL) hasMoreInfo
{
    if ([_capabilities serviceKeywords] != nil)
        return YES;

    if ([_capabilities serviceHasContactInfo])
        return YES;

    if ([_capabilities serviceMaxWidth] != nil)
        return YES;

    if ([_capabilities serviceMaxHeight] != nil)
        return YES;

    if ([_capabilities serviceLayerLimit] != nil)
        return YES;

    if ([_capabilities serviceAccessConstraints] != nil)
        return YES;

    if ([_capabilities serviceFees] != nil)
        return YES;

    return NO;
}

- (void) showMoreInfoView
{
    WebViewController* detailController = [[WebViewController alloc] initWithFrame:[[self tableView] frame]];
    [[detailController navigationItem] setTitle:@"Layer Info"];

    NSMutableString* htmlString = [[NSMutableString alloc] init];

    NSArray* keywords = [_capabilities serviceKeywords];
    if (keywords != nil && [keywords count] > 0)
    {
        [htmlString appendFormat:@"<b>Keywords</b>:"];
        [htmlString appendString:[self oneColumnTable:keywords]];
        [htmlString appendFormat:@"<br>"];
    }

    NSDictionary* contactInfo = [_capabilities serviceContactInfo];
    if (contactInfo != nil)
    {
        NSMutableArray* tableValues = [[NSMutableArray alloc] initWithCapacity:[contactInfo count]];

        [self addItemIfDefined:@"contactorganization" element:contactInfo title:@"Organization:" itemsOut:tableValues];
        [self addItemIfDefined:@"contactperson" element:contactInfo title:@"Person:" itemsOut:tableValues];
        [self addItemIfDefined:@"contactposition" element:contactInfo title:@"Position:" itemsOut:tableValues];
        [self addItemIfDefined:@"contactvoicetelephone" element:contactInfo title:@"Phone:" itemsOut:tableValues];
        [self addItemIfDefined:@"contactfacsimiletelephone" element:contactInfo title:@"Fax:" itemsOut:tableValues];
        [self addItemIfDefined:@"contactelectronicmailaddress" element:contactInfo title:@"Email:" itemsOut:tableValues];
        [self addItemIfDefined:@"addresstype" element:contactInfo title:@"Address Type:" itemsOut:tableValues];
        [self addItemIfDefined:@"address" element:contactInfo title:@"Address:" itemsOut:tableValues];
        [self addItemIfDefined:@"city" element:contactInfo title:@"City:" itemsOut:tableValues];
        [self addItemIfDefined:@"stateorprovince" element:contactInfo title:@"State/Province:" itemsOut:tableValues];
        [self addItemIfDefined:@"postcode" element:contactInfo title:@"Postcode:" itemsOut:tableValues];
        [self addItemIfDefined:@"country" element:contactInfo title:@"Country:" itemsOut:tableValues];

        [htmlString appendString:@"<b>Contact Info:</b>"];
        [htmlString appendString:[self twoColumnTable:tableValues]];
        [htmlString appendFormat:@"<br>"];
    }

    NSString* value = [_capabilities serviceMaxWidth];
    if (value != nil && [value length] > 0)
    {
        [htmlString appendFormat:@"<b>Max Width:</b> %@<br>", value];
    }

    value = [_capabilities serviceMaxHeight];
    if (value != nil && [value length] > 0)
    {
        [htmlString appendFormat:@"<b>Max Height:</b> %@<br>", value];
    }

    value = [_capabilities serviceLayerLimit];
    if (value != nil && [value length] > 0)
    {
        [htmlString appendFormat:@"<b>Layer Limit:</b> %@<br>", value];
    }

    value = [_capabilities serviceAccessConstraints];
    if (value != nil && [value length] > 0)
    {
        [htmlString appendFormat:@"<b>Access Constraints:</b> %@<br>", value];
    }

    value = [_capabilities serviceFees];
    if (value != nil && [value length] > 0)
    {
        [htmlString appendFormat:@"<b>Fees:</b> %@</b><br>", value];
    }

    if ([htmlString length] > 0)
    {
        [[detailController webView] loadHTMLString:htmlString baseURL:nil];
        [((UINavigationController*) [self parentViewController]) pushViewController:detailController animated:YES];
    }
}

- (void) addItemIfDefined:(NSString*)name
                  element:(NSDictionary*)element
                    title:(NSString*)title
                 itemsOut:(NSMutableArray*)itemsOut
{
    NSString* item = [element objectForKey:name];
    if (item != nil)
    {
        [itemsOut addObject:title];
        [itemsOut addObject:item];
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