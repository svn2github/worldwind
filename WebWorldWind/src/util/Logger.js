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
                console.log(message);
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
            missingArray: "The specified array is null, undefined or of insufficient length.",
            missingLocation: "The specified location is null, undefined or not a Location.",
            missingPosition: "The specified position is null, undefined or not a Position.",
            missingResult: "The specified result variable is null, undefined or not the correct type."
        }
    };

    var loggingLevel = 1; // log severe messages by default

    return Logger;
});