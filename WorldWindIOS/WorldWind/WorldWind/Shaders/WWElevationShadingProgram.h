/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import <Foundation/Foundation.h>
#import "WWGpuProgram.h"

/**
* Represents a GLSL shader program that shades the terrain according to vertex elevation. The program displays three
* color bands: a red band, a yellow band, and a transparent band. The elevation thresholds for the bands must be
* specified by the application.
*/
@interface WWElevationShadingProgram : WWGpuProgram
{
@protected
    GLuint yellowThresholdLocation;
    GLuint redThresholdLocation;
}

/// @name Attributes

/// The elevation in meters above which to display red shading.
- (void) loadRedThreshold:(float)redThreshold;

/// The elevation in meters above which to display yellow shading until the red threshold is reached.
- (void) loadYellowThreshold:(float)yellowThreshold;

/**
* Returns a unique string appropriate for identifying a shared instance of WWElevationShadingProgram in a WWGpuResourceCache.
*
* @return A unique string identifier for WWElevationShadingProgram.
*/
+ (NSString*) programKey;

@end