/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.

 @version $Id$
 */

#import "AltitudePicker.h"
#import "UnitsFormatter.h"
#import "TAIGA.h"

@implementation AltitudePicker

- (AltitudePicker*) initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    [self setBackgroundColor:[UIColor whiteColor]];

    _minimumAltitude = 0;
    _maximumAltitude = 100000;
    _altitudeInterval = 1000;
    _altitude = 0;

    picker = [[UIPickerView alloc] initWithFrame:frame];
    [picker setDataSource:self];
    [picker setDelegate:self];
    [picker setAutoresizingMask:UIViewAutoresizingFlexibleWidth];
    [self addSubview:picker];

    return self;
}

- (void) setMinimumAltitude:(double)minimumAltitude
{
    _minimumAltitude = minimumAltitude;
    [picker reloadAllComponents];
}

- (void) setMaximumAltitude:(double)maximumAltitude
{
    _maximumAltitude = maximumAltitude;
    [picker reloadAllComponents];
}

- (void) setAltitudeInterval:(double)altitudeInterval
{
    _altitudeInterval = altitudeInterval;
    [picker reloadAllComponents];
}

- (void) setAltitude:(double)altitude
{
    _altitude = altitude;
    [self selectAltitude:_altitude animated:YES];
}

- (double) altitudeForRow:(NSInteger)row
{
    return _minimumAltitude + _altitudeInterval * row;
}

- (void) selectAltitude:(double)altitude animated:(BOOL)animated
{
    NSInteger row = (NSInteger) ((altitude - _minimumAltitude) / _altitudeInterval);
    NSInteger numRows = [self pickerView:picker numberOfRowsInComponent:0];
    if (row >= numRows)
    {
        row = numRows - 1;
    }

    [picker selectRow:row inComponent:0 animated:animated];
}

//--------------------------------------------------------------------------------------------------------------------//
//-- UIPickerViewDataSource --//
//--------------------------------------------------------------------------------------------------------------------//

- (NSInteger) numberOfComponentsInPickerView:(UIPickerView*)pickerView
{
    return 1;
}

- (NSInteger) pickerView:(UIPickerView*)pickerView numberOfRowsInComponent:(NSInteger)component
{
    return (NSInteger) ((_maximumAltitude - _minimumAltitude) / _altitudeInterval) + 1;
}

//--------------------------------------------------------------------------------------------------------------------//
//-- UIPickerViewDelegate --//
//--------------------------------------------------------------------------------------------------------------------//

- (NSString*) pickerView:(UIPickerView*)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
    double altitude = [self altitudeForRow:row];

    return [[TAIGA unitsFormatter] formatMetersAltitude:altitude];
}

- (void) pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component
{
    _altitude = [self altitudeForRow:row];

    [self sendActionsForControlEvents:UIControlEventValueChanged];
}

@end