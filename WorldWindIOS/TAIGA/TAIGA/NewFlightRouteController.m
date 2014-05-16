/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.

 @version $Id$
 */

#import "NewFlightRouteController.h"
#import "FlightRoute.h"
#import "ColorPicker.h"
#import "AltitudePicker.h"
#import "UnitsFormatter.h"
#import "TAIGA.h"
#import "WorldWind/Util/WWColor.h"

#define COLOR_ID (@"color")
#define ALTITUDE_ID (@"altitude")

@implementation NewFlightRouteController

- (id) init
{
    self = [super initWithStyle:UITableViewStyleGrouped];

    UIBarButtonItem* cancelButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                                   target:self
                                                                                   action:@selector(actionCancel:)];
    UIBarButtonItem* doneButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                                                      target:self
                                                                                      action:@selector(actionDone:)];
    [[self navigationItem] setTitle:@"New Flight Route"];
    [[self navigationItem] setLeftBarButtonItem:cancelButtonItem];
    [[self navigationItem] setRightBarButtonItem:doneButtonItem];
    [[self tableView] setBounces:NO];

    _displayName = @"New Flight Route";
    _colorIndex = 0;
    _defaultAltitude = 0;
    _completionBlock = NULL;
    tableCells = [[NSMutableArray alloc] init];

    return self;
}

- (void) viewWillAppear:(BOOL)animated
{
    [tableCells removeAllObjects];

    UITableViewCell* cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
    UITextField* textField = [[UITextField alloc] init];
    [textField addTarget:self action:@selector(actionPickName:) forControlEvents:UIControlEventAllEvents];
    [textField setText:_displayName];
    [textField setPlaceholder:_displayName];
    [textField setAutocapitalizationType:UITextAutocapitalizationTypeWords];
    [textField setClearButtonMode:UITextFieldViewModeAlways];
    [textField setTranslatesAutoresizingMaskIntoConstraints:NO];
    [[cell contentView] addSubview:textField];
    [[cell contentView] addConstraint:[NSLayoutConstraint constraintWithItem:textField attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:[cell contentView] attribute:NSLayoutAttributeCenterY multiplier:1 constant:0]];
    [[cell contentView] addConstraint:[NSLayoutConstraint constraintWithItem:textField attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual toItem:[cell contentView] attribute:NSLayoutAttributeLeading multiplier:1 constant:15]];
    [[cell contentView] addConstraint:[NSLayoutConstraint constraintWithItem:textField attribute:NSLayoutAttributeTrailing relatedBy:NSLayoutRelationEqual toItem:[cell contentView] attribute:NSLayoutAttributeTrailing multiplier:1 constant:-15]];
    [tableCells addObject:cell];

    cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:COLOR_ID];
    NSDictionary* colorAttrs = [[FlightRoute flightRouteColors] objectAtIndex:_colorIndex];
    [cell setAccessoryType:UITableViewCellAccessoryDisclosureIndicator];
    [[cell textLabel] setText:@"Color"];
    [[cell detailTextLabel] setText:[colorAttrs objectForKey:@"displayName"]];
    [[cell detailTextLabel] setTextColor:[[colorAttrs objectForKey:@"color"] uiColor]];
    [tableCells addObject:cell];

    cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:ALTITUDE_ID];
    [cell setAccessoryType:UITableViewCellAccessoryDisclosureIndicator];
    [[cell textLabel] setText:@"Default Altitude"];
    [[cell detailTextLabel] setText:[[TAIGA unitsFormatter] formatMetersAltitude:_defaultAltitude]];
    [tableCells addObject:cell];
}

- (void) setCompletionBlock:(void (^)(void))completionBlock
{
    _completionBlock = completionBlock;
}

- (void) actionCancel:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:NULL];
}

- (void) actionDone:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:NULL];

    if (_completionBlock != NULL)
    {
        _completionBlock();
    }
}

- (void) actionPickName:(id)sender
{
    _displayName = [[sender text] isEqualToString:@""] ? [sender placeholder] : [sender text];
}

- (void) actionPickColor:(id)sender
{
    _colorIndex = (NSUInteger) [sender selectedColorIndex];

    [[self tableView] reloadData];
}

- (void) actionPickDefaultAltitude:(id)sender
{
    _defaultAltitude = [sender altitude];

    [[self tableView] reloadData];
}

- (NSInteger) tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section
{
    return [tableCells count];
}

- (UITableViewCell*) tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
    return [tableCells objectAtIndex:(NSUInteger) [indexPath row]];
}

- (void) tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    UITableViewCell* cell = [tableView cellForRowAtIndexPath:indexPath];
    if ([[cell reuseIdentifier] isEqualToString:COLOR_ID])
    {
        ColorPicker* picker = [[ColorPicker alloc] initWithFrame:CGRectMake(0, 0, 1, 1)];
        [picker addTarget:self action:@selector(actionPickColor:) forControlEvents:UIControlEventValueChanged];
        [picker setColorChoices:[FlightRoute flightRouteColors]];
        [picker setSelectedColorIndex:_colorIndex];

        UIViewController* viewController = [[UIViewController alloc] init];
        [viewController setView:picker];
        [viewController setTitle:@"Color"];
        [[self navigationController] pushViewController:viewController animated:YES];
    }
    else if ([[cell reuseIdentifier] isEqualToString:ALTITUDE_ID])
    {
        AltitudePicker* picker = [[AltitudePicker alloc] initWithFrame:CGRectMake(0, 44, 1, 216)];
        [picker addTarget:self action:@selector(actionPickDefaultAltitude:) forControlEvents:UIControlEventValueChanged];
        [picker setToVFRAltitudes];
        [picker setAltitude:_defaultAltitude];

        UIViewController* viewController = [[UIViewController alloc] init];
        [viewController setView:picker];
        [viewController setTitle:@"Default Altitude"];
        [[self navigationController] pushViewController:viewController animated:YES];
    }
}

@end