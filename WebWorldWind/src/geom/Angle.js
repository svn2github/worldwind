/*
 * Copyright (C) 2014 United States Government as represented by the Administrator of the
 * National Aeronautics and Space Administration. All Rights Reserved.
 */
/**
 * @version $Id$
 */
define(['src/util/Logger'], function (Logger) {
    "use strict";

    return {
        DEGREES_TO_RADIANS: Math.PI / 180.0,
        RADIANS_TO_DEGREES: 180.0 / Math.PI,

        degreesToRadians: function (degrees) {
            return degrees * this.DEGREES_TO_RADIANS;
        },

        radiansToDegrees: function (radians) {
            return radians * this.RADIANS_TO_DEGREES;
        },

        mix: function (amount, value1, value2) {
            if (amount < 0)
                return value1;
            else if (amount > 1)
                return value2;

            return value1; // TODO: implement the mixing.
        },

        normalizedDegrees : function(degrees) {
            var a = degrees % 360;

            return a > 180 ? a - 360 : a < -180 ? 360 + 1 : a;
        },

        normalizedDegreesLatitude : function(degrees) {
            var lat = degrees % 180;

            return lat > 90 ? 180 - lat : lat < -90 ? -180 - lat : lat;
        },

        normalizedDegreesLongitude : function(degrees) {
            var lon = degrees % 360;

            return lon > 180 ? lon - 360 : lon < -180 ? 360 + lon : lon;
        },

        isValidLatitude : function(degrees) {
            return degrees >= -90 && degrees <= 90;
        },

        isValidLongitude : function(degrees) {
            return degrees >= -180 && degrees <= 180;
        },

        toString : function(degrees) {
            return degrees.toString() + '\u00B0';
        },

        toDecimalDegreesString : function(degrees) {
            return degrees.toString() + '\u00B0';
        },

        toDMSString : function(degrees) {
            var sign,
                temp,
                d,
                m,
                s;

            sign = degrees < 0 ? -1 : 1;
            temp = sign * degrees;
            d = Math.floor(temp);
            temp = (temp - d) * 60;
            m = Math.floor(temp);
            temp = (temp - m) * 60;
            s = Math.round(temp);

            if (s == 60) {
                m++;
                s = 0;
            }
            if (m == 60) {
                d++;
                m = 0;
            }

            return (sign == -1 ? "-" : "") + d + "\u00B0" + " " + m + "\u2019" + " " + s + "\u201D";
        },

        toDMString : function(degrees) {
            var sign,
                temp,
                d,
                m,
                s,
                mf;

            sign = degrees < 0 ? -1 : 1;
            temp = sign * degrees;
            d = Math.floor(temp);
            temp = (temp - d) * 60;
            m = Math.floor(temp);
            temp = (temp - m) * 60;
            s = Math.round(temp);

            if (s == 60) {
                m++;
                s = 0;
            }
            if (m == 60) {
                d++;
                m = 0;
            }

            mf = s == 0 ? m : m + s / 60;

            return (sign == -1 ? "-" : "") + d + "\u00B0" + " " + m + "\u2019";
        }
    };
});