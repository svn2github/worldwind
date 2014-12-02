/*
 * Copyright (C) 2014 United States Government as represented by the Administrator of the
 * National Aeronautics and Space Administration. All Rights Reserved.
 */
/**
 * @exports LayerList
 * @version $Id$
 */
define([
        'src/layer/Layer',
        'src/util/Logger'
    ],
    function (Layer,
              Logger) {
        "use strict";

        /**
         * Constructs a layer list with a specified initial set of layers.
         * @alias LayerList
         * @constructor
         * @classdesc Represents a collection of layers.
         * @param {Layer[]} layers The list of layers to initially populate this layer list with. May by null or
         * undefined.
         */
        var LayerList = function (layers) {

            /**
             * This layer list's array of layers. This property is read-only. Use [addLayer]{@link LayerList#addLayer} to add
             * layers to this layer list, and [removeLayer]{@link LayerList#removeLayer} to remove layers from this layer list.
             * @type {Array}
             */
            this.layers = [];

            if (layers) {
                for (var i = 0, len = layers.length; i < len; i++) {
                    this.layers.push(layers[i]);
                }
            }
        };

        /**
         * Adds a specified layer to the end of this layer list.
         * @param {Layer} layer The layer to add. May be null or undefined, in which case this layer list is not modified.
         */
        LayerList.prototype.addLayer =  function(layer) {
            this.layers.push(layer);
        };

        /**
         * Removes the first instance of a specified layer from this layer list.
         * @param {Layer} layer The layer to remove. May be null or undefined, in which case this layer list is not
         * modified. This layer list is also not modified if the specified layer does not exist in the list.
         */
        LayerList.prototype.removeLayer = function(layer) {
            if (!layer)
                return;

            var index = -1;
            for (var i = 0, len = this.layers.length; i < len; i++) {
                if (this.layers[i] == layer) {
                    index = i;
                    break;
                }
            }

            if (index >= 0) {
                this.layers.splice(index, 1);
            }
        };

        return LayerList;
    });