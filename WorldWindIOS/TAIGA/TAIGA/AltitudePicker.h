/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.

 @version $Id$
 */

#import <Foundation/Foundation.h>

@interface AltitudePicker : UIControl<UIPickerViewDataSource, UIPickerViewDelegate>
{
@protected
    UIPickerView* picker;
}

@property (nonatomic) double minimumAltitude;

@property (nonatomic) double maximumAltitude;

@property (nonatomic) double altitudeInterval;

@property (nonatomic) double altitude;

@property (nonatomic) NSNumberFormatter* formatter;

- (AltitudePicker*) initWithFrame:(CGRect)frame;

@end