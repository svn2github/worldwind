/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.

 @version $Id$
 */

#import <Foundation/Foundation.h>

@interface UnitsFormatter : NSObject
{
@protected
    NSNumberFormatter* numberFormatter;
    NSNumberFormatter* latitudeFormatter;
    NSNumberFormatter* longitudeFormatter;
    NSNumberFormatter* altitudeFormatter;
    NSNumberFormatter* angleFormatter;
    NSNumberFormatter* angleFormatter2;
    NSNumberFormatter* speedFormatter;
    NSNumberFormatter* distanceFormatterFeet;
    NSNumberFormatter* distanceFormatterMiles;
}

- (NSString*) formatDegreesLatitude:(double)latitude;

- (NSString*) formatDegreesLongitude:(double)longitude;

- (NSString*) formatDegreesLatitude:(double)latitude longitude:(double)longitude;

- (NSString*) formatDegreesLatitude:(double)latitude longitude:(double)longitude metersAltitude:(double)altitude;

- (NSString*) formatMetersAltitude:(double)meters;

- (NSString*) formatFeetAltitude:(double)meters;

- (NSString*) formatAngle:(double)degrees;

- (NSString*) formatAngle2:(double)degrees;

- (NSString*) formatKnotsSpeed:(double)metersPerSecond;

- (NSString*) formatFeetDistance:(double)meters;

- (NSString*) formatMilesDistance:(double)meters;

@end