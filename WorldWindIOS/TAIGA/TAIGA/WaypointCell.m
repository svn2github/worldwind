/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.

 @version $Id$
 */

#import "WaypointCell.h"
#import "Waypoint.h"
#import "WorldWind/WWLog.h"

static NSDictionary* WaypointCellImageMap = nil;
static CGFloat WaypointCellMaxImageWidth = 0;
static const CGFloat WaypointCellImagePadding = 30;

@implementation WaypointCell

+ (void) initialize
{
    static BOOL initialized = NO; // protects against erroneous explicit calls to this method
    if (!initialized)
    {
        initialized = YES;

        WaypointCellImageMap = @{
                [NSNumber numberWithInt:WaypointTypeAirport]: [[UIImage imageNamed:@"38-airplane"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate],
                [NSNumber numberWithInt:WaypointTypeOther]:[[UIImage imageNamed:@"07-map-marker"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]
        };

        for (UIImage* image in [WaypointCellImageMap allValues])
        {
            if (WaypointCellMaxImageWidth < [image size].width)
                WaypointCellMaxImageWidth = [image size].width;
        }
    }
}

- (id) initWithReuseIdentifier:(NSString*)reuseIdentifier
{
    self = [super initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reuseIdentifier];

    [self layout];

    return self;
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

    CGFloat displayNameInset = WaypointCellMaxImageWidth + WaypointCellImagePadding;
    NSDictionary* metrics = @{@"displayNameInset":[NSNumber numberWithFloat:displayNameInset]};

    [contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-displayNameInset-[displayNameView]"
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

    UIImage* waypointImage = [WaypointCellImageMap objectForKey:[NSNumber numberWithInt:[waypoint type]]];
    if (waypointImage == nil)
    {
        WWLog(@"Unrecognized waypoint type %d", [waypoint type]);
    }

    [imageView setImage:waypointImage];
    [displayNameLabel setText:[waypoint displayName]];
    [displayNameLongLabel setText:[waypoint displayNameLong]];
}

@end