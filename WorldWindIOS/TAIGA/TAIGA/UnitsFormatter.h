/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.

 @version $Id$
 */

#import <Foundation/Foundation.h>

@interface UnitsFormatter : NSObject
{
@protected
    NSNumberFormatter* latitudeFormatter;
    NSNumberFormatter* longitudeFormatter;
    NSNumberFormatter* altitudeFormatter;
}

- (NSString*) formatDegreesLatitude:(double)latitude;

- (NSString*) formatDegreesLongitude:(double)longitude;

- (NSString*) formatDegreesLatitude:(double)latitude longitude:(double)longitude;

- (NSString*) formatMetersAltitude:(double)altitude;

- (NSString*) formatFeetAltitude:(double)altitude;

@end