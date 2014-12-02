/*
 * Copyright (C) 2014 United States Government as represented by the Administrator of the
 * National Aeronautics and Space Administration. All Rights Reserved.
 */
/**
 * @exports Tile
 * @version $Id$
 */
define([
        'src/util/Logger',
        'src/geom/Matrix',
        'src/util/Sector'
    ],
    function (Logger,
              Matrix,
              Sector) {
        "use strict";

        /**
         * Constructs a tile for a specified sector, level, row and column.
         * @alias Tile
         * @constructor
         * @classdesc Represents a tile of terrain or imagery.
         * @param {Sector} sector The sector represented by the tile.
         * @param {Number} level The tile's level in a tile pyramid.
         * @param {Number} row The tile's row in the specified level in a tile pyramid.
         * @param {Number} column The tile's column in the specified level in a tile pyramid.
         */
        var Tile = function (sector, level, row, column) {

            /**
             * The sector represented by this tile.
             * @type {Sector}
             */
            this.sector = sector;

            /**
             * The level at which this tile lies in a tile pyramid.
             * @type {Number}
             */
            this.level = level;

            /**
             * The row in this tile's level in which this tile lies in a tile pyramid.
             * @type {Number}
             */
            this.row = row;

            /**
             * The column in this tile's level in which this tile lies in a tile pyramid.
             * @type {Number}
             */
            this.column = column;

            this.extent = null;

            this.referencePoint = null;

            this.minElevation = 0;

            this.maxElevation = 0;

            this.tileWidth = 0;

            this.tileHeight = 0;

            this.texelSize = 0;

            this.transformationMatrix = new Matrix(1);
        };

        Tile.prototype.isEqual = function (that) {
            // TODO

            return false;
        };

        Tile.prototype.hash = function () {
            // TODO

            return 0;
        };

        Tile.prototype.subdivide = function(nextLevel, tileFactory) {
            // TODO
        };

        Tile.prototype.subdivideToCache = function(level, tileFactory, cache) {
            // TODO
        };

        Tile.prototype.mustSubdivide = function(dc, detailFactor) {
            // TODO
        };

        Tile.prototype.update = function(dc) {
            // TODO
        };

        Tile.computeRow = function (delta, latitude) {
            // TODO

            return 0;
        };

        Tile.computeColumn = function (delta, longitude) {
            // TODO

            return 0;
        };

        Tile.computeLastRow = function (delta, maxLatitude) {
            // TODO

            return 0;
        };

        Tile.computeLastColumn = function (delta, maxLongitude) {
            // TODO

            return 0;
        };

        Tile.computeSector = function (level, row, column) {
            // TODO

            return Sector.ZERO;
        };

        Tile.createTilesForLevel = function(level, tileFactor, tilesOut) {
            // TODO
        };

        return Tile;
    });