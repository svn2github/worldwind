/*
 * Copyright (C) 2014 United States Government as represented by the Administrator of the
 * National Aeronautics and Space Administration. All Rights Reserved.
 */
/**
 * @exports Tessellator
 * @version $Id$
 */
define([
        'src/error/ArgumentError',
        'src/globe/Globe',
        'src/util/Logger',
        'src/navigate/NavigatorState',
        'src/globe/Terrain',
        'src/globe/TerrainTile'
    ],
    function (ArgumentError,
              Globe,
              Logger,
              NavigatorState,
              Terrain,
              TerrainTile) {
        "use strict";

        /**
         * Constructs a Tessellator object for a specified globe.
         * @alias Tessellator
         * @constructor
         * @classdesc Represents a tessellator for a specified globe.
         */
        var Tessellator = function () {
        };

        /**
         * Tessellates the geometry of the globe associated with this terrain.
         * @param {Globe} globe The globe on which this tessellator operates.
         * @param {NavigatorState} navigatorState The navigator state to use when computing terrain.
         * @param {Number} verticalExaggeration The vertical exaggeration to apply to the computed terrain.
         * @returns {Terrain} The computed terrain, or null if terrain could not be computed.
         */
        Tessellator.prototype.tessellate = function (globe, navigatorState, verticalExaggeration) {
            if (!globe) {
                throw new ArgumentError(
                    Logger.logMessage(Logger.LEVEL_SEVERE, "Tessellator", "tessellate", "missingGlobe"));
            }

            if (!navigatorState) {
                throw new ArgumentError(
                    Logger.logMessage(Logger.LEVEL_SEVERE, "Tessellator", "tessellate", "missingNavigatorState"));
            }

            // TODO

            return null;
        };

        /**
         * Initializes rendering state to draw a succession of terrain tiles.
         */
        Tessellator.prototype.beginRendering = function () {
            // TODO
        };

        /**
         * Restores rendering state after drawing a succession of terrain tiles.
         */
        Tessellator.prototype.endRendering = function () {
            // TODO
        };

        /**
         * Initializes rendering state for drawing a specified terrain tile.
         * @param {TerrainTile} terrainTile The terrain tile subsequently drawn via this tessellator's render function.
         * @throws {ArgumentError} If the specified tile is null or undefined.
         */
        Tessellator.prototype.beginRenderingTile = function (terrainTile) {
            if (!terrainTile) {
                throw new ArgumentError(
                    Logger.logMessage(Logger.LEVEL_SEVERE, "Tessellator", "beginRenderingTile", "missingTile"));
            }

            // TODO
        };

        /**
         * Restores rendering state after drawing the most recent tile specified to
         * [beginRenderingTile{@link Tessellator#beginRenderingTile}.
         * @param {TerrainTile} terrainTile The terrain tile most recently rendered.
         * @throws {ArgumentError} If the specified tile is null or undefined.
         */
        Tessellator.prototype.endRenderingTile = function (terrainTile) {
            if (!terrainTile) {
                throw new ArgumentError(
                    Logger.logMessage(Logger.LEVEL_SEVERE, "Tessellator", "endRenderingTile", "missingTile"));
            }

            // TODO
        };

        /**
         * Renders a specified terrain tile.
         * @param {TerrainTile} terrainTile The terrain tile to render.
         * @throws {ArgumentError} If the specified tile is null or undefined.
         */
        Tessellator.prototype.renderTile = function (terrainTile) {
            if (!terrainTile) {
                throw new ArgumentError(
                    Logger.logMessage(Logger.LEVEL_SEVERE, "Tessellator", "renderTile", "missingTile"));
            }

            // TODO
        };

        return Tessellator;
    });