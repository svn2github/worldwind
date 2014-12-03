/*
 * Copyright (C) 2014 United States Government as represented by the Administrator of the
 * National Aeronautics and Space Administration. All Rights Reserved.
 */
/**
 * @version $Id$
 */
define([
        'src/util/Logger',
        'src/error/UnsupportedOperationError'
    ],
    function (Logger,
              UnsupportedOperationError) {
        "use strict";

        /**
         * Defines an interface for {@link MemoryCache} listeners.
         * This is an interface class and is not meant to be instantiated directly.
         * @exports MemoryCacheListener
         */
        var MemoryCacheListener = {

            /**
             * Called when an entry is removed from the cache.
             * Implementers of this interface must implement this function.
             * @param {Object} key The key of the entry removed.
             * @param {Object} value The value of the entry.
             */
            entryRemoved: function (key, value) {
                throw new UnsupportedOperationError(
                    Logger.logMessage(Logger.LEVEL_SEVERE, "MemoryCacheListener", "entryRemoved", "abstractInvocation"));
            },

            /**
             * Called when an error occurs during entry removal.
             * Implementers of this interface must implement this function.
             * @param {Object} error The error object describing the error that occurred.
             */
            removalError: function (error) {
                throw new UnsupportedOperationError(
                    Logger.logMessage(Logger.LEVEL_SEVERE, "MemoryCacheListener", "removalError", "abstractInvocation"));
            }
        };

        return MemoryCacheListener;
    });