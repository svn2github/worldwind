/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.

 @version $Id$
 */

#import <Foundation/Foundation.h>

@interface ColorPicker : UIControl<UITableViewDataSource, UITableViewDelegate>
{
@protected
    UITableView* table;
}

@property (nonatomic) NSArray* colorChoices;

@property (nonatomic) NSInteger selectedColorIndex;

- (ColorPicker*) initWithFrame:(CGRect)frame;

@end