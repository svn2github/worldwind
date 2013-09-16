/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import "SliderCellWithReadout.h"

@implementation SliderCellWithReadout

- (id) initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString*)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];

    CGRect frame = [self frame];

    _slider = [[UISlider alloc] initWithFrame:CGRectMake(20, 0, 0.7 * frame.size.width, frame.size.height)];

    _readout = [[UILabel alloc] initWithFrame:CGRectMake(0.8 * frame.size.width, 0,
            0.2 * frame.size.width, frame.size.height)];
    [_readout setTextAlignment:NSTextAlignmentLeft];
    [_readout setBackgroundColor:[UIColor clearColor]];

    [self addSubview:_slider];
    [self addSubview:_readout];

    [self setSelectionStyle:UITableViewCellSelectionStyleNone];

    return self;
}

@end