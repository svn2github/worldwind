/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import <Foundation/Foundation.h>

#define NMEA_SENTENCE_TYPE_GPGGA @"GPGGA"
#define NMEA_SENTENCE_TYPE_GPGSA @"GPGSA"
#define NMEA_SENTENCE_TYPE_GPGSV @"GPGSV"
#define NMEA_SENTENCE_TYPE_GPRMC @"GPRMC"

#define NMEA_FIELD_3D_FIX @"3DFix"
#define NMEA_FIELD_ALTITUDE @"Altitude"
#define NMEA_FIELD_AUTO_SELECTION @"AutoSelection"
#define NMEA_FIELD_DATE @"Date"
#define NMEA_FIELD_DGPS_STATION_ID @"DGPSStationID"
#define NMEA_FIELD_DGPS_UPDATE_TIME @"DGPSUpdateTime"
#define NMEA_FIELD_DILUTION_OF_PRECISION @"DilutionOfPrecision"
#define NMEA_FIELD_FIX_QUALITY @"FixQuality"
#define NMEA_FIELD_FIX_TIME @"FixTime"
#define NMEA_FIELD_FIX_TYPE @"FixType"
#define NMEA_FIELD_GEOID_HEIGHT @"GeoidHeight"
#define NMEA_FIELD_HORIZONTAL_DILUTION_OF_PRECISION @"HorizontalDilutionOfPrecision"
#define NMEA_FIELD_LATITUDE @"Latitude"
#define NMEA_FIELD_LONGITUDE @"Longitude"
#define NMEA_FIELD_MAGNETIC_VARIATION_DIRECTION @"MagneticVariationDirection"
#define NMEA_FIELD_MAGNETIC_VARIATION_VALUE @"MagneticVariationValue"
#define NMEA_FIELD_MESSAGE_TYPE @"MessageType"
#define NMEA_FIELD_NUMBER_OF_SENTENCES @"NumberOfSentences"
#define NMEA_FIELD_NUMBER_OF_SATELLITES_IN_VIEW @"NumberOfSatellitesInView"
#define NMEA_FIELD_SATELLITE_INFO @"SatelliteInfo"
#define NMEA_FIELD_SATELLITE_AZIMUTH @"SatelliteAzimuth"
#define NMEA_FIELD_SATELLITE_ELEVATION @"SatelliteElevation"
#define NMEA_FIELD_SATELLITE_PRN @"SatellitePRN"
#define NMEA_FIELD_SATELLITE_SIGNAL_TO_NOISE_RATIO @"SatelliteSignalToNoiseRatio"
#define NMEA_FIELD_SENTENCE_NUMBER @"SentenceNumber"
#define NMEA_FIELD_SPEED_OVER_GROUND @"SpeedOverGround"
#define NMEA_FIELD_STATUS @"Status"
#define NMEA_FIELD_NUM_SATELLITES_TRACKED @"NumSatellitesTracked"
#define NMEA_FIELD_TRACK_ANGLE @"TrackAngle"
#define NMEA_FIELD_TRACKED_SATELLITE_PRNS @"TrackedSatellitePRNs"
#define NMEA_FIELD_VERTICAL_DILUTION_OF_PRECISION @"VerticalDilutionOfPrecision"

@interface NMEASentence : NSObject

@property (nonatomic, readonly) NSString* sentence;

- (NMEASentence*) initWithString:(NSString*)sentence;

- (id) fieldWithName:(NSString*)fieldName;

@end