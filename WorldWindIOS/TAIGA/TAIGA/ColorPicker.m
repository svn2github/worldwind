/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.

 @version $Id$
 */

#import "ColorPicker.h"
#import "WorldWind/Util/WWColor.h"

@implementation ColorPicker

- (ColorPicker*) initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];

    _selectedColorIndex = -1;

    table = [[UITableView alloc] initWithFrame:frame style:UITableViewStylePlain];
    [table setDataSource:self];
    [table setDelegate:self];
    [table setAutoresizingMask:UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight];
    [self addSubview:table];

    return self;
}

- (void) setColorChoices:(NSArray*)colorChoices
{
    _colorChoices = colorChoices;
    [table reloadData];
}

- (void) setSelectedColorIndex:(NSInteger)selectedColorIndex
{
    _selectedColorIndex = selectedColorIndex;
    [table reloadData];
}

//--------------------------------------------------------------------------------------------------------------------//
//-- UITableViewDataSource --//
//--------------------------------------------------------------------------------------------------------------------//

- (NSInteger) numberOfSectionsInTableView:(UITableView*)tableView
{
    return 1;
}

- (NSInteger) tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section
{
    return [_colorChoices count];
}

- (UITableViewCell*) tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
    static NSString* cellId = @"cellId";

    UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:cellId];
    if (cell == nil)
    {
        cell =  [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellId];
        UIImage* image = [[UIImage imageNamed:@"circle-small"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        [[cell imageView] setImage:image];
    }

    NSDictionary* colorAttrs = [_colorChoices objectAtIndex:(NSUInteger) [indexPath row]];
    [[cell imageView] setTintColor:[[colorAttrs objectForKey:@"color"] uiColor]];
    [[cell textLabel] setText:[colorAttrs objectForKey:@"displayName"]];
    [cell setAccessoryType:_selectedColorIndex == [indexPath row] ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone];

    return cell;
}

//--------------------------------------------------------------------------------------------------------------------//
//-- UITableViewDelegate --//
//--------------------------------------------------------------------------------------------------------------------//

- (void) tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    NSInteger newIndex = [indexPath row];
    NSInteger oldIndex = _selectedColorIndex;
    if (newIndex == oldIndex)
        return;

    UITableViewCell* newCell = [tableView cellForRowAtIndexPath:[NSIndexPath indexPathForItem:newIndex inSection:0]];
    [newCell setAccessoryType:UITableViewCellAccessoryCheckmark];

    if (oldIndex >= 0)
    {
        UITableViewCell* oldCell = [tableView cellForRowAtIndexPath:[NSIndexPath indexPathForItem:oldIndex inSection:0]];
        [oldCell setAccessoryType:UITableViewCellAccessoryNone];
    }

    _selectedColorIndex = newIndex;
    [self sendActionsForControlEvents:UIControlEventValueChanged];
}

@end