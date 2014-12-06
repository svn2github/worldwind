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

            this.displayName = displayName ? displayName : "Layer";

            this.enabled = true;

            this.pickEnabled = true;

            this.opacity = 1;

            this.minActiveAltitude = -Number.MAX_VALUE;

            this.maxActiveAltitude = Number.MAX_VALUE;

            this.networkRetrievalEnabled = true;

            this.userTags = {};
        };

        Layer.prototype.dispose = function() {
            // Override in subclasses to clean up when called.
        };

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

        Layer.prototype.doRender = function (dc) {
            // Default implementation does nothing.
        };

        Layer.prototype.isLayerActive = function (dc) {
            var eyePosition = dc.eyePosition;
            if (!eyePosition)
                return false;

            return eyePosition.altitude >= this.minActiveAltitude && eyePosition.altitude <= this.maxActiveAltitude;
       };

        Layer.prototype.isLayerInView = function (dc) {
            return true; // default implementation always returns true
        };

        return Layer;
    });