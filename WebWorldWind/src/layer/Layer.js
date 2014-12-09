/*
 * Copyright (C) 2014 United States Government as represented by the Administrator of the
 * National Aeronautics and Space Administration. All Rights Reserved.
 */
/**
 * @exports Layer
 * @version $Id$
 */
define([
        '../util/Logger'
    ],
    function (Logger) {
        "use strict";

        /**
         * Constructs a layer. This constructor is meant to be called by subclasses and not directly by an application.
         * @alias Layer
         * @constructor
         * @classdesc Provides an abstract base class for layer implementations. This class is not meant to be instantiated
         * directly.
         */
        var Layer = function (displayName) {

            /**
             * This layer's display name.
             */
            this.displayName = displayName ? displayName : "Layer";

            /**
             * Indicates whether this layer is displayed.
             * @type {boolean}
             * @default true
             */
            this.enabled = true;

            /**
             * Indicates whether this layer is pickable.
             * @type {boolean}
             * @default true
             */
            this.pickEnabled = true;

            /**
             * This layer's opacity, which may be overridden by layer contents. Opacity is in the range
             * [0, 1], with 1 indicating fully opaque.
             * @type {number}
             * @default 1
             */
            this.opacity = 1;

            /**
             * The altitude above which this layer is displayed, in meters.
             * @type {number}
             * @default -Number.MAX_VALUE
             */
            this.minActiveAltitude = -Number.MAX_VALUE;

            /**
             * The altitude below which this layer is displayed, in meters.
             * @type {Number}
             * @default Number.MAX_VALUE
             */
            this.maxActiveAltitude = Number.MAX_VALUE;

            /**
             * Indicates whether this layer should draw resources from the network when required.
             * @type {boolean}
             * @default true
             */
            this.networkRetrievalEnabled = true;

            /**
             * A collection of app-specified information for this layer. This information is not interpreted by
             * World Wind.
             * @type {{}}
             */
            this.userTags = {};
        };

        /**
         * Disposes of resources held by this layer.
         */
        Layer.prototype.dispose = function() {
            // Override in subclasses to clean up when called.
        };

        /**
         * Displays this layer. Subclasses should generally not override this method but should instead override the
         * [doRender]{@link Layer#doRender} method.
         * @param {DrawContext} dc The current draw context.
         */
        Layer.prototype.render = function (dc) {
            if (!this.enabled)
                return;

            if (dc.pickingMode && !this.pickEnabled)
                return;

            if (!this.isLayerActive(dc))
                return;

            if (!this.isLayerInView(dc))
                return;

            this.doRender(dc);
        };

        /**
         * Subclass method called to display this layer. Subclasses should implement this method rather than the
         * [render]{@link Layer#render} method, which determines enable, pick and active status and does not call
         * this doRender method if the layer should not be displayed.
         * @param {DrawContext} dc The current draw context.
         */
        Layer.prototype.doRender = function (dc) {
            // Default implementation does nothing.
        };

        /**
         * Indicates whether this layer is withing its active-altitude range.
         * @param {DrawContext} dc The current draw context.
         * @returns {boolean} <code>true</code> if this layer is within its active altitude range, otherwise
         * <code>false</code>.
         */
        Layer.prototype.isLayerActive = function (dc) {
            var eyePosition = dc.eyePosition;
            if (!eyePosition)
                return false;

            return eyePosition.altitude >= this.minActiveAltitude && eyePosition.altitude <= this.maxActiveAltitude;
       };

        /**
         * Indicates whether this layer is within the current view.
         * @param {DrawContext} dc The current draw context.
         * @returns {boolean} <code>true</code> if this layer is within the current view, otherwise
         * <code>false</code>.
         */
        Layer.prototype.isLayerInView = function (dc) {
            return true; // default implementation always returns true
        };

        return Layer;
    });