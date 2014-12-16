/*
 * Copyright (C) 2014 United States Government as represented by the Administrator of the
 * National Aeronautics and Space Administration. All Rights Reserved.
 */
/**
 * @exports SurfaceImage
 * @version $Id$
 */
define([
        '../error/ArgumentError',
        '../util/Logger',
        '../event/RedrawEvent',
        '../render/SurfaceTile',
        '../render/Texture'
    ],
    function (ArgumentError,
              Logger,
              RedrawEvent,
              SurfaceTile,
              Texture) {
        "use strict";

        /**
         * Constructs a surface image shape for a specified sector and image path.
         * @alias SurfaceImage
         * @constructor
         * @augments SurfaceTile
         * @classdesc Represents an image drawn on the terrain.
         * @param {Sector} sector The sector spanned by this surface image.
         * @param {String} imagePath The image path of the image to draw on the terrain.
         * @throws {ArgumentError} If either the specified sector or image path is null or undefined.
         */
        var SurfaceImage = function (sector, imagePath) {
            if (!sector) {
                throw new ArgumentError(Logger.logMessage(Logger.LEVEL_SEVERE, "SurfaceImage", "constructor",
                    "missingSector"));
            }

            if (!imagePath) {
                throw new ArgumentError(Logger.logMessage(Logger.LEVEL_SEVERE, "SurfaceImage", "constructor",
                    "missingPath"));
            }

            SurfaceTile.call(this, sector);

            /**
             * The path to the image.
             * @type {String}
             */
            this.imagePath = imagePath;

            /**
             * This surface image's opacity.
             * @type {number}
             */
            this.opacity = 1;

            /**
             * This surface image's display name;
             * @type {string}
             */
            this.displayName = "Surface Image";
        };

        SurfaceImage.prototype = Object.create(SurfaceTile.prototype);

        SurfaceImage.prototype.bind = function (dc) {
            var texture = dc.gpuResourceCache.textureForKey(this.imagePath);
            if (texture) {
                return texture.bind(dc);
            }

            var image = new Image(),
                imagePath = this.imagePath,
                cache = dc.gpuResourceCache,
                gl = dc.currentGlContext;

            image.onload = function () {
                var texture = new Texture(gl, image);
                cache.putResource(gl, imagePath, texture, WorldWind.GPU_TEXTURE, texture.size);

                // Send an event to request a redraw.
                dc.canvas.dispatchEvent(new CustomEvent(RedrawEvent.EVENT_TYPE));
            };
            image.crossOrigin = 'anonymous';
            image.src = this.imagePath;
        };

        SurfaceImage.prototype.applyInternalTransform = function (dc, matrix) {
            // No need to apply the transform.
        };

        /**
         * Displays this surface image. Called by the layer containing this surface image.
         * @param {DrawContext} dc The current draw context.
         */
        SurfaceImage.prototype.render = function (dc) {
            dc.surfaceTileRenderer.renderTiles(dc, [this], this.opacity);
        };

        return SurfaceImage;
    });