/*
 * Copyright (C) 2014 United States Government as represented by the Administrator of the
 * National Aeronautics and Space Administration. All Rights Reserved.
 */
/**
 * @exports Level
 * @version $Id$
 */
define([
        'src/error/ArgumentError',
        'src/util/LevelSet', // TODO: This is a circular dependency. Try to eliminate the need for it.
        'src/geom/Location',
        'src/util/Logger',
        'src/geom/Sector'
    ],
    function (ArgumentError,
              LevelSet,
              Location,
              Logger,
              Sector) {
        "use strict";

        /**
         * Constructs a Level within a [LevelSet]{@link LevelSet}. Applications typically do not interact with this
         * class.
         * @alias Level
         * @constructor
         * @classdesc Represents a level in a tile pyramid.
         * @throws {ArgumentError} If either the specified tile delta or parent level set is null or undefined.
         */
        var Level = function (levelNumber, tileDelta, parent) {
            if (!tileDelta) {
                throw new ArgumentError(
                    Logger.logMessage(Logger.LEVEL_SEVERE, "Level", "constructor",
                        "The specified tile delta is null or undefined"));
            }

            if (!parent) {
                throw new ArgumentError(
                    Logger.logMessage(Logger.LEVEL_SEVERE, "Level", "constructor",
                        "The specified parent level set is null or undefined"));
            }

            /**
             * The level's ordinal in its parent level set.
             * @type {Number}
             */
            this.levelNumber = levelNumber;

            /**
             * The geographic size of tiles within this level.
             * @type {Location}
             */
            this.tileDelta = tileDelta;

            /**
             * The level set that this level is a member of.
             * @type {WWLevelSet}
             */
            this.parent = parent;

            /**
             * The size of pixels or elevation cells within this level, in radians per pixel or per cell.
             * @type {Number}
             */
            this.texelSize = 0;

            /**
             * The width in pixels or cells of the resource associated with tiles within this level.
             * @type {Number}
             */
            this.tileWidth = 0;

            /**
             * The height in pixels or cells of the resource associated with tiles within this level.
             * @type {Number}
             */
            this.tileHeight = 0;

            /**
             * The sector spanned by this level.
             * @type {Sector}
             */
            this.sector = null;
        };

        /**
         * Indicates whether this level is the lowest resolution level (level 0) within its parent's level set.
         * @returns {boolean} <code>true</code> If this tile is the lowest resolution in the parent level set,
         * otherwise <code>false</code>.
         */
        Level.prototype.isFirstLevel = function () {
            // TODO

            return false;
        };

        /**
         * Indicates whether this level is the highest resolution level within its parent's level set.
         * @returns {boolean} <code>true</code> If this tile is the highest resolution in the parent level set,
         * otherwise <code>false</code>.
         */
        Level.prototype.isLastLevel = function () {
            // TODO

            return false;
        };

        /**
         * Returns the level whose ordinal occurs immediately before this level's ordinal in the parent level set, or
         * null if this is the fist level.
         * @returns {Level} The previous level, or null if this is the first level.
         */
        Level.prototype.previousLevel = function () {
            // TODO

            return null;
        };

        /**
         * Returns the level whose ordinal occurs immediately after this level's ordinal in the parent level set, or
         * null if this is the last level.
         * @returns {Level} The next level, or null if this is the last level.
         */
        Level.prototype.nextLevel = function () {
            // TODO

            return null;
        };

        /**
         * Compare this level's ordinal to that of a specified level.
         * @param {Level} that The level to compare this one to.
         * @returns {Number} 0 if the two ordinals are equivalent. 1 if the specified level's ordinal is greater than
         * this level's ordinal. -1 if the specified level's ordinal is less than this level's ordinal.
         * @throws {ArgumentError} If the specified level is null or undefined.
         */
        Level.prototype.compare = function (that) {
            if (!that) {
                throw new ArgumentError(
                    Logger.logMessage(Logger.LEVEL_SEVERE, "Level", "compare",
                        "The specified level is null or undefined"));
            }
            // TODO

            return 0;
        };

        return Level;
    });