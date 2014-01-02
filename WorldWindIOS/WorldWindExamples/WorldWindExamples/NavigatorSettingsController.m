/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.

 @version $Id$
 */

#import "NavigatorSettingsController.h"
#import "WorldWind/Navigate/WWFirstPersonNavigator.h"
#import "WorldWind/Navigate/WWLookAtNavigator.h"
#import "WorldWind/WorldWindConstants.h"
#import "WorldWind/WorldWindView.h"
#import "WorldWind/WWLog.h"

#define CONTROLLER_TITLE @"Navigation"
#define MODEL_TYPE_FIRST_PERSON @"First Person"
#define MODEL_TYPE_LOOK_AT @"Inspector"
#define POPOVER_SIZE CGSizeMake(320, 110)
#define SELECTED_IMAGE_NAME @"431-yes.png"

@implementation NavigatorSettingsController

- (NavigatorSettingsController*) initWithWorldWindView:(WorldWindView*)wwv
{
    self = [super initWithStyle:UITableViewStyleGrouped];

    modelTypes = [NSArray arrayWithObjects:MODEL_TYPE_LOOK_AT, MODEL_TYPE_FIRST_PERSON, nil];
    selectedModelType = [self modelTypeForNavigator:[wwv navigator]];
    _wwv = wwv;

    [[self navigationItem] setTitle:CONTROLLER_TITLE];
    [self setContentSizeForViewInPopover:POPOVER_SIZE];

    return self;
}

- (NSInteger) numberOfSectionsInTableView:(UITableView*)tableView
{
    return 1;
}

- (NSInteger) tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section
{
    return [modelTypes count];
}

- (UITableViewCell*) tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
    static NSString* cellIdentifier = @"cell";

    UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (cell == nil)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
        [[cell imageView] setImage:[UIImage imageNamed:SELECTED_IMAGE_NAME]];
        [cell setShowsReorderControl:YES];
    }

    id value =  [modelTypes objectAtIndex:(NSUInteger) [indexPath row]];
    [[cell textLabel] setText:value];
    [[cell imageView] setHidden:(value != selectedModelType)];

    return cell;
}

- (void) tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath
{
    id selectedObject = [modelTypes objectAtIndex:(NSUInteger) [indexPath row]];

    if (![selectedModelType isEqual:selectedObject])
    {
        selectedModelType = selectedObject;
        [self didSelectModelType:selectedModelType];
    }

    [[self tableView] reloadData];
}

- (id) modelTypeForNavigator:(id<WWNavigator>)navigator
{
    if ([navigator isKindOfClass:[WWFirstPersonNavigator class]])
    {
        return MODEL_TYPE_FIRST_PERSON;
    }
    else if ([navigator isKindOfClass:[WWLookAtNavigator class]])
    {
        return MODEL_TYPE_LOOK_AT;
    }
    else
    {
        WWLog(@"Unknown navigator: %@", navigator);
        return nil;
    }
}

- (void) didSelectModelType:(id)modelType
{
    if ([modelType isEqual:MODEL_TYPE_FIRST_PERSON])
    {
        id<WWNavigator> oldNavigator = [_wwv navigator];
        id<WWNavigator> newNavigator = [[WWFirstPersonNavigator alloc] initWithView:_wwv navigatorToMatch:oldNavigator];
        [oldNavigator dispose];
        [_wwv setNavigator:newNavigator];
        [[NSNotificationCenter defaultCenter] postNotificationName:WW_REQUEST_REDRAW object:self];
    }
    else if ([modelType isEqual:MODEL_TYPE_LOOK_AT])
    {
        id<WWNavigator> oldNavigator = [_wwv navigator];
        id<WWNavigator> newNavigator = [[WWLookAtNavigator alloc] initWithView:_wwv navigatorToMatch:oldNavigator];
        [oldNavigator dispose];
        [_wwv setNavigator:newNavigator];
        [[NSNotificationCenter defaultCenter] postNotificationName:WW_REQUEST_REDRAW object:self];
    }
    else
    {
        WWLog(@"Unknown model type: %@", modelType);
    }
}

@end