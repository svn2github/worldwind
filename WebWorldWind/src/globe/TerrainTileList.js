/*
 * Copyright (C) 2014 United States Government as represented by the Administrator of the
 * National Aeronautics and Space Administration. All Rights Reserved.
 */
/**
 * @exports TerrainTileList
 * @version $Id$
 */
define(['../error/ArgumentError',
        '../util/Logger'
    ],
    function (ArgumentError,
              Logger) {
        "use strict";

        /**
         * Constructs a terrain tile list, a container for terrain tiles that also has a tessellator and a sector
         * associated with it.
         * @alias TerrainTileList
         * @constructor
         * @classdesc Represents a portion of a globe's terrain.
         * @param {Tessellator} tessellator The tessellator that created this terrain tile list.
         *
         */
        var TerrainTileList = function TerrainTileList(tessellator) {
            if (!tessellator) {
                throw new ArgumentError(
                    Logger.logMessage(Logger.LEVEL_SEVERE, "TerrainTileList", "TerrainTileList", "missingTessellator"));
            }
            this.tessellator = tessellator;
            this.sector = undefined;
            this.tileArray = [];
        };

        Object.defineProperty(TerrainTileList.prototype, 'length', {
            get: function () {
                return this.tileArray.length
            }
        });

        TerrainTileList.prototype.addTile = function (tile) {
            if (!tile) {
                throw new ArgumentError(
                    Logger.logMessage(Logger.LEVEL_SEVERE, "TerrainTileList", "addTile", "missingTile"));
            }

            if (this.tileArray.indexOf(tile) == -1) {
                this.tileArray.push(tile);
            }
        };

        TerrainTileList.prototype.removeAllTiles = function () {
            this.tileArray = [];
        };

        return TerrainTileList;
    });