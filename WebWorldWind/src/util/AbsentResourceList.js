/*
 * Copyright (C) 2014 United States Government as represented by the Administrator of the
 * National Aeronautics and Space Administration. All Rights Reserved.
 */
/**
 * @exports AbsentResourceList
 * @version $Id$
 */
define([],
    function () {
        "use strict";

        /**
         * Constructs an absent resource list.
         * @alias AbsentResourceList
         * @constructor
         * @classdesc Provides a collection to keep track of resources whose retrieval failed and when retrieval
         * may be tried again. Applications typically do not use this class directly.
         * @param {Number} maxTrys The number of attempts to make before the resource is marked as absent.
         * @param {Number} minCheckInterval The amount of time to wait between attempts, in milliseconds.
         * @constructor
         */

        var AbsentResourceList = function (maxTrys, minCheckInterval) {

            /**
             * The number  of attempts to make before the resource is marked as absent.
             * @type {Number}
             * @readonly
             */
            this.maxTrys = maxTrys;

            /**
             * The amount of time to wait before each attempt.
             * @type {Number}
             * @readonly
             */
            this.minCheckInterval = minCheckInterval;

            /**
             * The amount of time, in milliseconds, beyond which retrieval attempts should again be allowed.
             * When this time has elapsed from the most recent failed attempt the number of trys attempted is
             * reset to 0. This prevents the resource from being permanently blocked.
             * @type {number}
             * @default 60,000 milliseconds (one minute)
             */
            this.tryAgainInterval = 60e3; // 60 seconds
            this.possiblyAbsent = {};
        };

        /**
         * Indicates whether a specified resource is marked as absent.
         * @param {String} resourceId The resource identifier.
         * @returns {boolean} <code>true</code> if the resource is marked as absent, otherwise <code>false</code>.
         */
        AbsentResourceList.prototype.isResourceAbsent = function (resourceId) {
            var entry = this.possiblyAbsent[resourceId];

            if (!entry) {
                return false;
            }

            var timeSinceLastMark = new Date().getTime() - entry.timeOfLastMark;

            if (timeSinceLastMark > this.tryAgainInterval) {
                delete this.possiblyAbsent[resourceId];
                return false;
            }

            return timeSinceLastMark < this.minCheckInterval || entry.numTrys > this.maxTrys;
        };

        /**
         * Marks a resource attempt as having failed. This increments the number-of-tries counter and sets the time
         * of the last attempt. When this method has been called <code>this.maxTrys</code> times the resource is marked
         * as absent until this absent resource list's try-again-interval is reached.
         * @param {String} resourceId The resource identifier.
         */
        AbsentResourceList.prototype.markResourceAbsent = function (resourceId) {
            var entry = this.possiblyAbsent[resourceId];

            if (!entry) {
                entry = {
                    timeOfLastMark: new Date().getTime(),
                    numTrys: 0
                };
                this.possiblyAbsent[resourceId] = entry;
            }

            entry.numTrys = entry.numTrys + 1;
            entry.timeOfLastMark = new Date().getTime();
        };

        /**
         * Removes the specified resource from this absent resource list. Call this method when retrieval attempts
         * succeed.
         * @param {String} resourceId The resource identifier.
         */
        AbsentResourceList.prototype.unmarkResourceAbsent = function (resourceId) {
            var entry = this.possiblyAbsent[resourceId];

            if (entry) {
                delete this.possiblyAbsent[resourceId];
            }
        };

        return AbsentResourceList;
    });