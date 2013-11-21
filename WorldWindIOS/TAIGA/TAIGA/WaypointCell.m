/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.

 @version $Id$
 */

#import "WaypointCell.h"
#import "Waypoint.h"
#import "WorldWind/WWLog.h"

@implementation WaypointCell

- (id) initWithReuseIdentifier:(NSString*)reuseIdentifier
{
    self = [super initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reuseIdentifier];

    [self assembleImages];
    [self layout];

    return self;
}

- (void) assembleImages
{
    waypointTypeToImage = @{
            [NSNumber numberWithInt:WaypointTypeAirport]: [[UIImage imageNamed:@"38-airplane"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate],
            [NSNumber numberWithInt:WaypointTypeOther]:[[UIImage imageNamed:@"07-map-marker"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]
    };

    for (UIImage* image in [waypointTypeToImage allValues])
    {
        if (maxImageWidth < [image size].width)
            maxImageWidth = [image size].width;
    }
}

- (void) layout
{
    UIView* contentView = [self contentView];

    imageView = [[UIImageView alloc] init];
    [imageView setTranslatesAutoresizingMaskIntoConstraints:NO];
    [contentView addSubview:imageView];

    displayNameView = [[UIView alloc] init];
    [displayNameView setTranslatesAutoresizingMaskIntoConstraints:NO];
    [contentView addSubview:displayNameView];

    displayNameLabel = [[UILabel alloc] init];
    [displayNameLabel setFont:[UIFont systemFontOfSize:[UIFont labelFontSize]]];
    [displayNameLabel setTranslatesAutoresizingMaskIntoConstraints:NO];
    [displayNameView addSubview:displayNameLabel];

    displayNameLongLabel = [[UILabel alloc] init];
    [displayNameLongLabel setFont:[UIFont systemFontOfSize:[UIFont smallSystemFontSize]]];
    [displayNameLongLabel setTranslatesAutoresizingMaskIntoConstraints:NO];
    [displayNameView addSubview:displayNameLongLabel];

    UIView* imageTopSpace = [[UIView alloc] init];
    UIView* imageBottomSpace = [[UIView alloc] init];
    UIView* imageLeftSpace = [[UIView alloc] init];
    UIView* imageRightSpace = [[UIView alloc] init];
    UIView* displayNameTopSpace = [[UIView alloc] init];
    UIView* displayNameBottomSpace = [[UIView alloc] init];
    [imageTopSpace setTranslatesAutoresizingMaskIntoConstraints:NO];
    [imageBottomSpace setTranslatesAutoresizingMaskIntoConstraints:NO];
    [imageLeftSpace setTranslatesAutoresizingMaskIntoConstraints:NO];
    [imageRightSpace setTranslatesAutoresizingMaskIntoConstraints:NO];
    [displayNameTopSpace setTranslatesAutoresizingMaskIntoConstraints:NO];
    [displayNameBottomSpace setTranslatesAutoresizingMaskIntoConstraints:NO];
    [contentView addSubview:imageTopSpace];
    [contentView addSubview:imageBottomSpace];
    [contentView addSubview:imageLeftSpace];
    [contentView addSubview:imageRightSpace];
    [contentView addSubview:displayNameTopSpace];
    [contentView addSubview:displayNameBottomSpace];

    NSDictionary* views = NSDictionaryOfVariableBindings(imageView, imageTopSpace, imageBottomSpace, imageLeftSpace,
    imageRightSpace, displayNameView, displayNameTopSpace, displayNameBottomSpace);

    NSDictionary* metrics = @{@"displayNameInsetLeft":[NSNumber numberWithFloat:maxImageWidth + 30]};

    [contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-displayNameInsetLeft-[displayNameView]"
                                                                        options:0 metrics:metrics views:views]];
    [contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[imageLeftSpace][imageView][imageRightSpace(==imageLeftSpace)][displayNameView]"
                                                                        options:0 metrics:nil views:views]];
    [contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[imageTopSpace][imageView][imageBottomSpace(==imageTopSpace)]|"
                                                                        options:0 metrics:nil views:views]];
    [contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[displayNameTopSpace][displayNameView][displayNameBottomSpace(==displayNameTopSpace)]|"
                                                                        options:0 metrics:nil views:views]];

    views = NSDictionaryOfVariableBindings(displayNameLabel, displayNameLongLabel);
    [displayNameView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[displayNameLabel]|"
                                                                            options:0 metrics:nil views:views]];
    [displayNameView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[displayNameLongLabel]|"
                                                                            options:0 metrics:nil views:views]];
    [displayNameView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[displayNameLabel][displayNameLongLabel]|"
                                                                            options:0 metrics:nil views:views]];
}

- (void) setToWaypoint:(Waypoint*)waypoint
{
    if (waypoint == nil)
    {
        WWLOG_AND_THROW(NSInvalidArgumentException, @"Waypoint is nil")
    }

    UIImage* waypointImage = [waypointTypeToImage objectForKey:[NSNumber numberWithInt:[waypoint type]]];
    if (waypointImage == nil)
    {
        WWLog(@"Unrecognized waypoint type %d", [waypoint type]);
    }

    [imageView setImage:waypointImage];
    [displayNameLabel setText:[waypoint displayName]];
    [displayNameLongLabel setText:[waypoint displayNameLong]];
}

@end