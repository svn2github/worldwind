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
                if (mimeType === "image/png")
                    return "png";

                if (mimeType === "image/jpeg")
                    return "jpg";

                if (mimeType === "application/bil")
                    return "bil";

                return null;
            },

            /**
             * Returns the current location URL as obtained from <code>window.location</code> with the last path component
             * removed.
             * @returns {string} The current location URL with the last path component removed.
             */
            currentUrlSansFilePart: function () {
                var protocol = window.location.protocol,
                    host = window.location.host,
                    path = window.location.pathname,
                    pathParts = path.split("/"),
                    newPath = "";

                for (var i = 0, len = pathParts.length; i < len - 1; i++) {
                    if (pathParts[i].length > 0) {
                        newPath = newPath + "/" + pathParts[i];
                    }
                }

                return protocol + "//" + host + newPath;
            },

            /**
             * Returns the path component of a specified URL.
             * @param {String} url The URL from which to determine the path component.
             * @returns {string} The path component, or the empty string if the specified URL is null, undefined
             * or empty.
             */
            urlPath: function (url) {
                if (!url)
                    return "";

                var urlParts = url.split("/"),
                    newPath = "";

                for (var i = 0, len = urlParts.length; i < len; i++) {
                    var part = urlParts[i];

                    if (!part || part.length === 0
                        || part.indexOf(":") != -1
                        || part === "."
                        || part === ".."
                        || part === "null"
                        || part === "undefined") {
                        continue;
                    }

                    if (newPath.length !== 0) {
                        newPath = newPath + "/";
                    }

                    newPath = newPath + part;
                }

                return newPath;
            }
        };

        return WWUtil;
    });