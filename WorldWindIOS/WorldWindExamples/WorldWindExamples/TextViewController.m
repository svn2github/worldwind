/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import <CoreGraphics/CoreGraphics.h>
#import "TextViewController.h"

@implementation TextViewController

- (TextViewController*) initWithFrame:(CGRect)frame
{
    self = [super init];

    [self setContentSizeForViewInPopover:frame.size];

    _textView = [[UITextView alloc] initWithFrame:frame];
    [_textView setEditable:NO];
    [_textView setFont:[UIFont systemFontOfSize:16]];

    return self;
}

- (void) viewDidLoad
{
    [super viewDidLoad];

    [[self view] addSubview:_textView];
}

@end