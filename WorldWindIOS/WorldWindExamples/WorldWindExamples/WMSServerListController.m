/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import "WMSServerListController.h"
#import "WorldWindView.h"

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

    return self;
}

- (void) initializeServerList
{
    servers = [[NSMutableArray alloc] init];

    NSArray* serverList = [[NSUserDefaults standardUserDefaults] objectForKey:WW_WMS_SERVER_LIST];
    if (serverList == nil)
    {
        NSMutableArray* defaultServerList = [[NSMutableArray alloc] init];

        NSMutableDictionary* dict = [[NSMutableDictionary alloc] init];
        [dict setObject:@"NASA Earth Observations (NEO) WMS" forKey:WW_WMS_SERVER_TITLE];
        [dict setObject:@"http://neowms.sci.gsfc.nasa.gov/wms/wms" forKey:WW_WMS_SERVER_ADDRESS];
        [defaultServerList addObject:dict];

        [[NSUserDefaults standardUserDefaults] setObject:defaultServerList forKey:WW_WMS_SERVER_LIST];
        [[NSUserDefaults standardUserDefaults] synchronize];

        serverList = [[NSUserDefaults standardUserDefaults] objectForKey:WW_WMS_SERVER_LIST];
    }

    for (NSDictionary* dict in serverList)
    {
        [servers addObject:dict];
    }
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
    }

    NSDictionary* server = [servers objectAtIndex:(NSUInteger)[indexPath row]];
    [[cell textLabel] setText:[server objectForKey:WW_WMS_SERVER_TITLE]];
    [[cell detailTextLabel] setText:[server objectForKey:WW_WMS_SERVER_ADDRESS]];

    return cell;
}

- (void) tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath
{
}

@end