/*
 * Copyright (C) 2014 United States Government as represented by the Administrator of the
 * National Aeronautics and Space Administration. All Rights Reserved.
 */
/**
 * @exports LevelSet
 * @version $Id$
 */
define([
        'src/error/ArgumentError',
        'src/util/Level',
        'src/geom/Location',
        'src/util/Logger',
        'src/geom/Sector'
    ],
    function (ArgumentError,
              Level,
              Location,
              Logger,
              Sector) {
        "use strict";

        /**
         * Constructs a level set.
         * @alias Level
         * @constructor
         * @classdesc Represents a multi-resolution, hierarchical collection of tiles. Applications typically do not
         * interact with this class.
         * @param {Sector} sector The sector spanned by this level set.
         * @param {Location} levelZeroDelta The geographic size of tiles in the lowest resolution level of this level set.
         * @param {Number} numLevels The number of levels in the level set.
         * @param {Number} tileWidth The height in pixels of images associated with tiles in this level set, or the number of sample
         * points in the longitudinal direction of elevation tiles associate with this level set.
         * @param {Number} tileHeight The height in pixels of images associated with tiles in this level set, or the number of sample
         * points in the latitudinal direction of elevation tiles associate with this level set.
         * @throws {ArgumentError} If the specified sector or level-zero-delta is null or undefined, the level zero
         * delta values are less than or equal to zero, or any of the number-of-levels, tile-width or tile-height
         * arguments are less than 1.
         */
        var LevelSet = function (sector, levelZeroDelta, numLevels, tileWidth, tileHeight) {
            if (!sector) {
                throw new ArgumentError(
                    Logger.logMessage(Logger.LEVEL_SEVERE, "LevelSet", "constructor", "missingSector"));
            }

            if (!levelZeroDelta) {
                throw new ArgumentError(
                    Logger.logMessage(Logger.LEVEL_SEVERE, "LevelSet", "constructor",
                        "The specified level zero delta is null or undefined"));
            }

            if (levelZeroDelta.latitude <= 0 || levelZeroDelta.longitude <= 0) {
                throw new ArgumentError(
                    Logger.logMessage(Logger.LEVEL_SEVERE, "LevelSet", "constructor",
                        "The specified level zero delta is less than or equal to zero."));
            }

            if (numLevels < 1) {
                throw new ArgumentError(
                    Logger.logMessage(Logger.LEVEL_SEVERE, "LevelSet", "constructor",
                        "The specified number of levels is less than one."));
            }

            if (tileWidth < 1 || tileHeight < 1) {
                throw new ArgumentError(
                    Logger.logMessage(Logger.LEVEL_SEVERE, "LevelSet", "constructor",
                        "The specified tile width or tile height is less than one."));
            }

            /**
             * The sector spanned by this level set.
             * @type {Sector}
             */
            this.sector = sector;

            /**
             * The geographic size of the lowest resolution (level 0) tiles in this level set.
             * @type {Location}
             */
            this.levelZeroDelta = levelZeroDelta;

            /**
             * The number of levels in this level set.
             * @type {Number}
             */
            this.numLevels = numLevels;

            /**
             *  The width in pixels of images associated with tiles in this level set, or the number of sample points
             *  in the longitudinal direction of elevation tiles associated with this level set.
             * @type {Number}
             */
            this.tileWidth = tileWidth;

            /**
             *  The height in pixels of images associated with tiles in this level set, or the number of sample points
             *  in the latitudinal direction of elevation tiles associated with this level set.
             * @type {Number}
             */
            this.tileHeight = tileHeight;
        };

        /**
         * Returns the {@link Level} for a specified level set.
         * @param {Number} levelNumber The number of the desired level.
         * @returns {Level} The requested level, or null if the level does not exist.
         */
        LevelSet.prototype.level = function(levelNumber) {
            // TODO
        };

        /**
         * Returns the level with a specified texel size.
         * This function returns the first level if the specified texel size is greater than the first level's texel
         * size, and returns the last level if the delta is less than the last level's texel size.
         * @param {Number} texelSize The size of pixels or elevation cells in the level, in radians per pixel or cell.
         */
        LevelSet.prototype.levelForTexelSize = function(texelSize) {
            // TODO
        };

        /**
         * Returns the first (lowest resolution) level of this level set.
         * @returns {Level} The first level of this level set.
         */
        LevelSet.prototype.firstLevel = function() {
            // TODO
        };

        /**
         * Returns the last (highest resolution) level of this level set.
         * @returns {Level} The last level of this level set.
         */
        LevelSet.prototype.lastLevel = function() {
            // TODO
        };

        return LevelSet;
    });