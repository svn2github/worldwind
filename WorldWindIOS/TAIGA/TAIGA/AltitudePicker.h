/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.

 @version $Id$
 */

#import <Foundation/Foundation.h>

@class UnitsFormatter;

@interface AltitudePicker : UIControl<UIPickerViewDataSource, UIPickerViewDelegate>
{
@protected
    UIPickerView* picker;
}

@property (nonatomic) double minimumAltitude;

@property (nonatomic) double maximumAltitude;

@property (nonatomic) double altitudeInterval;

@property (nonatomic) double altitude;

@property (nonatomic) id userObject;

- (AltitudePicker*) initWithFrame:(CGRect)frame;

- (void) setToVFRAltitudes;

@end