/*
 * Copyright (C) 2014 United States Government as represented by the Administrator of the
 * National Aeronautics and Space Administration. All Rights Reserved.
 */
/**
 * @version $Id$
 */
define([
        'src/util/Logger'
    ],
    function (Logger) {
        "use strict";

        /**
         * Defines an interface for {@link MemoryCache} listeners.
         * @exports MemoryCacheListener
         */
        var MemoryCacheListener = {

            /**
             * Called when an entry is removed from the cache.
             * @param {Object} key The key of the entry removed.
             * @param {Object} value The value of the entry.
             */
            entryRemoved: function (key, value) {
                // TODO
            },

            /**
             * Called when an error occurs during entry removal.
             * @param {Object} error The error object describing the error that occurred.
             */
            removalError: function (error) {
                // TODO
            }
        };

        return MemoryCacheListener;
    });