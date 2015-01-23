/*
 * Copyright (C) 2014 United States Government as represented by the Administrator of the
 * National Aeronautics and Space Administration. All Rights Reserved.
 */
/**
 * @version $Id$
 */
define(function () {
    "use strict";
    /**
     * Logs selected message types to the console.
     * @exports Logger
     */

    var Logger = {
        /**
         * Log no messages.
         * @constant
         */
        LEVEL_NONE: 0,
        /**
         * Log messages marked as severe.
         * @constant
         */
        LEVEL_SEVERE: 1,
        /**
         * Log messages marked as warnings and messages marked as severe.
         * @constant
         */
        LEVEL_WARNING: 2,
        /**
         * Log messages marked as information, messages marked as warnings and messages marked as severe.
         * @constant
         */
        LEVEL_INFO: 3,

        /**
         * Set the logging level used by subsequent invocations of the logger.
         * @param {Number} level The logging level, one of Logger.LEVEL_NONE, Logger.LEVEL_SEVERE, Logger.LEVEL_WARNING,
         * or Logger.LEVEL_INFO.
         */
        setLoggingLevel: function (level) {
            loggingLevel = level;
        },

        /**
         * Indicates the current logging level.
         * @returns {number} The current logging level.
         */
        getLoggingLevel: function () {
            return loggingLevel;
        },

        /**
         * Logs a specified message at a specified level.
         * @param {Number} level The logging level of the message. If the current logging level allows this message to be
         * logged it is written to the console.
         * @param {String} message The message to log. Nothing is logged if the message is null or undefined.
         */
        log: function (level, message) {
            if (message && level > 0 && level <= loggingLevel) {
                if (level === Logger.LEVEL_SEVERE) {
                    console.error(message);
                } else if (level === Logger.LEVEL_WARNING) {
                    console.warn(message);
                } else if (level === Logger.LEVEL_INFO) {
                    console.info(message);
                } else {
                    console.log(message);
                }
            }
        },

        makeMessage: function (className, functionName, message) {
            var msg = this.messageTable[message] ? this.messageTable[message] : message;

            return className + "." + functionName + ": " + msg;
        },

        logMessage: function (level, className, functionName, message) {
            var msg = this.makeMessage(className, functionName, message);
            this.log(level, msg);

            return msg;
        },

        messageTable: { // KEEP THIS TABLE IN ALPHABETICAL ORDER
            abstractInvocation: "The function called is abstract and must be overridden in a subclass.",
            indexOutOfRange: "The specified index is out of range.",
            invalidViewport: "The specified viewport's width or height is zero or negative.",
            missingArray: "The specified array is null, undefined or of insufficient length.",
            missingColor: "The specified color is null or undefined.",
            missingDc: "The specified draw context is null or undefined.",
            missingEntry: "The specified entry is null or undefined.",
            missingFrustum: "The specified frustum is null or undefined.",
            missingGlContext: "The specified WebGL rendering context is null or undefined.",
            missingGlobe: "The specified globe is null or undefined.",
            missingImage: "The specified image is null or undefined.",
            missingKey: "The specified key is null or undefined.",
            missingLevel: "The specified level is null or undefined.",
            missingLine: "The specified line is null or undefined.",
            missingLocation: "The specified location is null or undefined.",
            missingMatrix: "The specified matrix is null or undefined.",
            missingNavigatorState: "The specified navigator state is null or undefined.",
            missingPath: "The specified path is null or undefined.",
            missingPlacename: "The specified place name is null or undefined.",
            missingPlane: "The specified plane is null or undefined.",
            missingPoint: "The specified point is null or undefined.",
            missingPosition: "The specified position is null or undefined.",
            missingProgram: "The specified program is null or undefined.",
            missingRenderable: "The specified renderable is null or undefined.",
            missingResource: "The specified resource is null or undefined.",
            missingResult: "The specified result variable is null or undefined.",
            missingSector: "The specified sector is null or undefined.",
            missingText: "The specified text is null or undefined.",
            missingTexture: "The specified texture is null or undefined.",
            missingTile: "The specified tile is null or undefined.",
            missingVector: "The specified vector is null or undefined.",
            missingViewport: "The specified viewport is null or undefined.",
            missingWorldWindow: "The specified World Window is null or undefined.",
            notYetImplemented: "This function is not yet implemented"
        }
    };

    var loggingLevel = 1; // log severe messages by default

    return Logger;
});