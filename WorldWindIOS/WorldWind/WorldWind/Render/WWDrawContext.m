/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import "WorldWind/Render/WWDrawContext.h"

@implementation WWDrawContext

- (void) reset
{
    _timestamp = [NSDate date];
    _verticalExaggeration = 1;
}

@end
