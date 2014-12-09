/*
 * Copyright (C) 2014 United States Government as represented by the Administrator of the
 * National Aeronautics and Space Administration. All Rights Reserved.
 */
/**
 * @exports RenderableLayer
 * @version $Id$
 */
define([
        '../error/ArgumentError',
        '../layer/Layer',
        '../util/Logger',
    ],
    function (ArgumentError,
              Layer,
              Logger) {
        "use strict";

        /**
         * Constructs a layer that draws shapes and other renderables.
         * @alias RenderableLayer
         * @constructor
         * @augments Layer
         * @classdesc Provides a layer that draws shapes and other renderables.
         */
        var RenderableLayer = function (displayName) {
            Layer.call(this, displayName);

            this.renderables = [];
        };

        RenderableLayer.prototype = Object.create(Layer.prototype);

        /**
         * Removes all renderables from this layer. Does not call dispose on those renderables.
         */
        RenderableLayer.prototype.dispose = function () {
            this.removeAllRenderables();
        };

        /**
         * Adds a renderable to this layer.
         * @param {Renderable} renderable The renderable to add.
         * @throws {ArgumentError} If the specified renderable is null or undefined.
         */
        RenderableLayer.prototype.addRenderable = function (renderable) {
            if (!renderable) {
                throw new ArgumentError(Logger.logMessage(Logger.LEVEL_SEVERE, "RenderableLayer", "addRenderable",
                    "missingRenderable"));
            }

            this.renderables.push(renderable);
        };

        /**
         * Adds an array of renderables to this layer.
         * @param {Renderable[]} renderables The renderables to add.
         * @throws {ArgumentError} If the specified renderables array is null or undefined.
         */
        RenderableLayer.prototype.addRenderables = function (renderables) {
            for (var i = 0, len = renderables.length; i < len; i++) {
                this.addRenderable(renderables[i]);
            }
        };

        /**
         * Removes a renderable from this layer.
         * @param {Renderable} renderable The renderable to remove.
         * @throws {ArgumentError} If the specified renderable is null or undefined.
         */
        RenderableLayer.prototype.removeRenderable = function (renderable) {
            var index = this.renderables.indexOf(renderable);
            if (index >= 0) {
                this.renderables.slice(index, 1);
            }
        };

        /**
         * Removes all renderables from this layer.
         */
        RenderableLayer.prototype.removeAllRenderables = function () {
            this.renderables.slice(0, this.renderables.length);
        };

        RenderableLayer.prototype.doRender = function (dc) {
            for (var i = 0, len = this.renderables.length; i < len; i++) {
                this.renderables[i].render(dc);
            }
        };

        return RenderableLayer;
    });