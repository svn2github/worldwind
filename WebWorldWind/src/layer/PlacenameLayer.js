/*
 * Copyright (C) 2014 United States Government as represented by the Administrator of the
 * National Aeronautics and Space Administration. All Rights Reserved.
 */
/**
 * @exports PlacenameLayer
 * @version $Id$
 */
define([
        '../error/ArgumentError',
        '../util/Logger',
        '../layer/RenderableLayer',
        '../render/UserFacingText'
    ],
    function (ArgumentError,
              Logger,
              RenderableLayer,
              UserFacingText) {
    "use strict";

    /**
     * Constructs a layer that draws place names which are UserFacingText.
     * @alias PlacenameLayer
     * @constructor
     * @augments RenderableLayer
     * @classdesc Provides a layer that draws placenames which are UserFacingText.
     */
    var PlacenameLayer = function() {
        RenderableLayer.call(this, "Place Name Layer");

        this.placenames = [];
    };

    PlacenameLayer.prototype = Object.create(RenderableLayer.prototype);

    /**
     * Removes all place names from this layer. Does not call dispose on those place names.
     */
    RenderableLayer.prototype.dispose = function () {
        this.removeAllPlacenames();
    };

    /**
     * Adds a place name to this layer.
     * @param {UserFacingText} placename The place name to add.
     * @throws {ArgumentError} If the specified place name is null or undefined.
     */
    PlacenameLayer.prototype.addPlacename = function(placename) {
        if (!placename) {
            throw new ArgumentError(Logger.logMessage(Logger.LEVEL_SEVERE, "PlacenameLayer", "addPlacename",
                "missingPlacename"));
        }

        this.placenames.push(placename);
    };

    /**
     * Adds an array of place names to this layer.
     * @param {UserFacingText[]} placenames The place names to add.
     * @throws {ArgumentError} If the specified place name array is null or undefined.
     */
    PlacenameLayer.prototype.addPlacenames = function(placenames) {
        for (var idx = 0, len = placenames.length; idx < len; idx += 1) {
            this.addPlacename(placenames[idx]);
        }
    };

    /**
     * Removes a place name from this layer.
     * @param {UserFacingText} placename The place name to remove.
     * @throws {ArgumentError} If the specified place name is null or undefined.
     */
    PlacenameLayer.prototype.removePlacename = function(placename) {
        var idx = this.placenames.indexOf(placename);
        if (idx >= 0) {
            this.placenames.slice(idx, 1);
        }
    };

    /**
     * Removes all place names from this layer.
     */
    PlacenameLayer.prototype.removeAllPlacenames = function() {
        this.placenames.slice(0, this.placenames.length);
    };

    PlacenameLayer.prototype.doRender = function(dc) {
        for (var idx = 0, len = this.placenames.length; idx < len; idx += 1) {
            this.placenames[idx].render(dc);
        }
    };

    return PlacenameLayer;
});