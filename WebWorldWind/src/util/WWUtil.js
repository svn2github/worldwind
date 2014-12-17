/*
 * Copyright (C) 2014 United States Government as represented by the Administrator of the
 * National Aeronautics and Space Administration. All Rights Reserved.
 */
/**
 * @version $Id$
 */
define([
        '../error/ArgumentError',
        '../geom/Line',
        '../util/Logger',
        '../geom/Rectangle',
        '../geom/Vec3'],
    function (ArgumentError,
              Line,
              Logger,
              Rectangle,
              Vec3) {
        "use strict";
        /**
         * Provides math constants and functions.
         * @exports WWUtil
         */
        var WWUtil = {

            POSITIVE_ZERO: +0.0,

            NEGATIVE_ZERO: -0.0,

            /**
             * Returns the suffix for a specified mime type.
             * @param {String} mimeType The mime type to determine a suffix for.
             * @returns {string} The suffix for the specified mime type, or null if the mime type is not recognized.
             */
            suffixForMimeType: function (mimeType) {
                if (mimeType == "image/png")
                    return "png";

                if (mimeType == "image/jpeg")
                    return "jpg";

                return null;
            }
        };

        return WWUtil;
    });