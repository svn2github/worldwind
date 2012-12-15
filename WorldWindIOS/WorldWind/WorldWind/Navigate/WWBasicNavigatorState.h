/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.

 @version $Id$
 */

#import <Foundation/Foundation.h>
#import "WorldWind/Navigate/WWNavigatorState.h"

@class WWMatrix;

@interface WWBasicNavigatorState : NSObject<WWNavigatorState>
{
@protected
    WWMatrix* modelview;
    WWMatrix* projection;
    WWMatrix* modelviewProjection;
}

- (WWBasicNavigatorState*) initWithModelview:(WWMatrix*)modelviewMatrix projection:(WWMatrix*)projectionMatrix;

@end
