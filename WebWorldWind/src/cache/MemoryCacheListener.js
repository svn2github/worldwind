/*
 * Copyright (C) 2014 United States Government as represented by the Administrator of the
 * National Aeronautics and Space Administration. All Rights Reserved.
 */
/**
 * @version $Id$
 */
define([
        '../util/Logger',
        '../error/UnsupportedOperationError'
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
             * @param {Object} entry The entry removed.
             */
            entryRemoved: function (key, entry) {
                throw new UnsupportedOperationError(
                    Logger.logMessage(Logger.LEVEL_SEVERE, "MemoryCacheListener", "entryRemoved", "abstractInvocation"));
            },

            /**
             * Called when an error occurs during entry removal.
             * Implementers of this interface must implement this function.
             * @param {Object} error The error object describing the error that occurred.
             * @param {Object} key The key of the entry being removed.
             * @param {Object} entry The entry being removed.
             */
            removalError: function (error, key, entry) {
                throw new UnsupportedOperationError(
                    Logger.logMessage(Logger.LEVEL_SEVERE, "MemoryCacheListener", "removalError", "abstractInvocation"));
            }
        };

        return MemoryCacheListener;
    });