/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import <Foundation/Foundation.h>

@interface SliderCellWithReadout : UITableViewCell
@property (nonatomic) UISlider* slider;
@property (nonatomic) UILabel* readout;
- (SliderCellWithReadout*) initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString*)reuseIdentifier;
@end