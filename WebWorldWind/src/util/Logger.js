/*
 * Copyright (C) 2014 United States Government as represented by the Administrator of the
 * National Aeronautics and Space Administration. All Rights Reserved.
 */
/**
 * @version $Id:$
 */
define(function () {
    "use strict";

    var loggingLevel = 1; // log severe messages by default

    return {
        LEVEL_NONE: 0,
        LEVEL_SEVERE: 1,
        LEVEL_WARNING: 2,
        LEVEL_DEBUG: 3,

        setLoggingLevel: function (level) {
            loggingLevel = level;
        },

        getLoggingLevel: function () {
            return loggingLevel;
        },

        log: function (level, message) {
            if (message && level > 0 && level <= loggingLevel) {
                console.log(message);
            }
        }
    };
});