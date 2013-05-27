/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import "WMSServerListController.h"
#import "WorldWind/WorldWindView.h"
#import "WorldWind/Util/WWWMSCapabilities.h"
#import "WMSServerDetailController.h"

NSString* WW_WMS_SERVER_LIST = @"WMSServerList";
NSString* WW_WMS_SERVER_TITLE = @"WMSServerTitle";
NSString* WW_WMS_SERVER_ADDRESS = @"WMSServerAddress";

@implementation WMSServerListController

- (WMSServerListController*) initWithWorldWindView:(WorldWindView*)wwv
{
    self = [super initWithStyle:UITableViewStylePlain];

    CGSize size = CGSizeMake(400, 400);
    [self setContentSizeForViewInPopover:size];

    _wwv = wwv;

    [self initializeServerList];

    [[self navigationItem] setRightBarButtonItem:[self editButtonItem]];
    [[self navigationItem] setTitle:@"WMS Servers"];

    addButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"05-plus"]
                                                 style:UIBarButtonItemStylePlain
                                                target:self action:@selector(handleAddButtonTap)];
    [[self navigationItem] setLeftBarButtonItem:addButton];

    return self;
}

- (void) initializeServerList
{
    servers = [[NSMutableArray alloc] init];

    NSArray* serverList = [[NSUserDefaults standardUserDefaults] objectForKey:WW_WMS_SERVER_LIST];
    if (serverList == nil)
    {
        [self addServer:@"http://neowms.sci.gsfc.nasa.gov/wms/wms" serviceTitle:@"NASA Earth Observations (NEO) WMS"];

        serverList = [[NSUserDefaults standardUserDefaults] objectForKey:WW_WMS_SERVER_LIST];
    }

    for (NSDictionary* dict in serverList)
    {
        [servers addObject:dict];
    }
}

- (void) addServer:(NSString*)serviceAddress serviceTitle:(NSString*)serviceTitle
{
    NSMutableDictionary* dict = [[NSMutableDictionary alloc] init];
    [dict setObject:serviceTitle forKey:WW_WMS_SERVER_TITLE];
    [dict setObject:serviceAddress forKey:WW_WMS_SERVER_ADDRESS];
    [servers addObject:dict];

    [[NSUserDefaults standardUserDefaults] setObject:servers forKey:WW_WMS_SERVER_LIST];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (BOOL) tableView:(UITableView*)tableView canMoveRowAtIndexPath:(NSIndexPath*)indexPath
{
    return YES;
}

- (NSInteger) numberOfSectionsInTableView:(UITableView*)tableView
{
    return 1;
}

- (NSInteger) tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section
{
    return [servers count];
}

- (UITableViewCell*) tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
    static NSString* cellIdentifier = @"cell";

    UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (cell == nil)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellIdentifier];
        [cell setAccessoryType:UITableViewCellAccessoryDetailDisclosureButton];
        [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
    }

    NSDictionary* server = [servers objectAtIndex:(NSUInteger) [indexPath row]];
    [[cell textLabel] setText:[server objectForKey:WW_WMS_SERVER_TITLE]];
    [[cell detailTextLabel] setText:[server objectForKey:WW_WMS_SERVER_ADDRESS]];

    return cell;
}

- (void) tableView:(UITableView*)tableView
commitEditingStyle:(UITableViewCellEditingStyle)editingStyle
 forRowAtIndexPath:(NSIndexPath*)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete)
    {
        [servers removeObjectAtIndex:(NSUInteger) [indexPath row]];

        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath]
                         withRowAnimation:UITableViewRowAnimationFade];

        [[NSUserDefaults standardUserDefaults] setObject:servers forKey:WW_WMS_SERVER_LIST];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
}

- (void) tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath
{
}

- (void) handleAddButtonTap
{
    UIAlertView* inputView = [[UIAlertView alloc] initWithTitle:nil
                                                        message:@"Enter WMS server URL:"
                                                       delegate:self
                                              cancelButtonTitle:@"Cancel"
                                              otherButtonTitles:@"Ok", nil];
    [inputView setAlertViewStyle:UIAlertViewStylePlainTextInput];
    [[inputView textFieldAtIndex:0] setText:@"http://"];
    [[inputView textFieldAtIndex:0] setKeyboardType:UIKeyboardTypeURL];
    [inputView show];
}

- (void) alertView:(UIAlertView*)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 1)
    {
        NSString* serverAddress = [[alertView textFieldAtIndex:0] text];
        if (serverAddress != nil && [serverAddress length] > 0)
        {
            for (NSDictionary* dict in servers)
            {
                if ([serverAddress isEqualToString:[dict objectForKey:WW_WMS_SERVER_ADDRESS]])
                {
                    return;
                }
            }

            WWWMSCapabilities* caps = [[WWWMSCapabilities alloc] initWithServerAddress:serverAddress];
            if (caps != nil)
            {
                NSString* serviceTitle = [caps serviceTitle];
                if (serviceTitle == nil)
                {
                    serviceTitle = @"WMS Server";
                }
                [self addServer:serverAddress serviceTitle:serviceTitle];

                [[NSUserDefaults standardUserDefaults] setObject:[caps root] forKey:serverAddress];
                [[NSUserDefaults standardUserDefaults] synchronize];

                [[self tableView] reloadData];
            }
        }
    }
}

- (void) tableView:(UITableView*)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath*)indexPath
{
    UITableViewCell* cell = [tableView cellForRowAtIndexPath:indexPath];
    NSString* serverAddress = [[cell detailTextLabel] text];

    WWWMSCapabilities* caps;
    NSDictionary* capsRoot = [[NSUserDefaults standardUserDefaults] objectForKey:serverAddress];
    if (capsRoot == nil)
    {
        caps = [[WWWMSCapabilities alloc] initWithServerAddress:serverAddress];
        if (caps != nil)
        {
            [[NSUserDefaults standardUserDefaults] setObject:[caps root] forKey:serverAddress];
            [[NSUserDefaults standardUserDefaults] synchronize];
        }
    }
    else
    {
        caps = [[WWWMSCapabilities alloc] initWithCapabilitiesDictionary:capsRoot];
    }

    if (caps != nil)
    {
        WMSServerDetailController* detailController =
                [[WMSServerDetailController alloc] initWithCapabilities:caps
                                                          serverAddress:serverAddress
                                                                   size:[self contentSizeForViewInPopover]];
        [((UINavigationController*) [self parentViewController]) pushViewController:detailController animated:YES];
    }
}
//
//- (void) tableView:(UITableView*)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath*)indexPath
//{
//    UITableViewCell* cell = [tableView cellForRowAtIndexPath:indexPath];
//    NSString* serverAddress = [[cell detailTextLabel] text];
//
//    NSError* error = nil;
//    NSString* cacheDir = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0];
//    NSString* cachePath = [cacheDir stringByAppendingPathComponent:@"WMSCapabilities"];
//    [[NSFileManager defaultManager] createDirectoryAtPath:cachePath
//                              withIntermediateDirectories:YES attributes:nil error:&error];
//    if (error != nil)
//    {
//        WWLog("@Error \"%@\" creating directory %@", [error description], cachePath);
//        return;
//    }
//
//    NSString* fileName = [serverAddress stringByReplacingOccurrencesOfString:@"/" withString:@"."];
//    fileName = [fileName stringByReplacingOccurrencesOfString:@"?" withString:@""];
//    fileName = [fileName stringByReplacingOccurrencesOfString:@":" withString:@""];
//    NSString* filePath = [cachePath stringByAppendingPathComponent:fileName];
//
//    WWWMSCapabilities* caps;
//
//    if ([[NSFileManager defaultManager] fileExistsAtPath:filePath])
//    {
//        caps = [[WWWMSCapabilities alloc] initWithCapabilitiesFile:filePath];
//    }
//    else
//    {
//        caps = [[WWWMSCapabilities alloc] initWithServerAddress:serverAddress];
//        [WWXMLParser writeXML:[caps root] toFile:filePath];
//    }
//
//    if (caps != nil)
//    {
//        NSArray* layers = [caps namedLayers];
//        NSLog(@"%d", [layers count]);
//    }
//}

@end