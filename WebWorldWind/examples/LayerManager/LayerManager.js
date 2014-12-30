/*
 * Copyright (C) 2014 United States Government as represented by the Administrator of the
 * National Aeronautics and Space Administration. All Rights Reserved.
 */
/**
 * @exports LayerManager
 * @version $Id$
 */
define(function () {
    "use strict";

    /**
     * Constructs a layer manager for a specified {@link WorldWindow}.
     * @alias LayerManager
     * @constructor
     * @classdesc Provides a layer manager to interactively control layer visibility for a World Window.
     * @param {String} layerManagerName The name of the layer manager div in the HTML document. This layer manager
     * will populate that element with an unordered list containing list items for each layer in the specified
     * World Window's layer list. To keep the layer manager in synch with the World Window, the application must call
     * this layer manager's [update]{@link LayerManager#update} method when the contents of the World Window's layer
     * list changes. The application should also call [update]{@link LayerManager#update} after each frame in order
     * to keep the layer visibility indicator in synch with the rendered frame.
     * @param {WorldWindow} worldWindow The World Window to associated this layer manager with.
     */
    var LayerManager = function (layerManagerName, worldWindow) {
        this.layerManagerName = layerManagerName;
        this.wwd = worldWindow;

        // Add a redraw callback in order to update the layer visibility state for each frame.
        var layerManger = this;
        this.wwd.redrawCallbacks.push(function (wwd) {
            layerManger.update();
        });

        // Initially populate the layer manager.
        this.update();
    };

    /**
     * Synchronizes this layer manager with its associated World Window. This method should be called whenever the
     * World Window's layer list changes as well as after each rendering frame.
     */
    LayerManager.prototype.update = function () {
        var layerManager = this,
            layerList = this.wwd.layers,
            lm = document.querySelector('#' + this.layerManagerName),
            ul = lm.querySelector('ul');

        // If !ul then create one. This occurs the first time this method is called.
        if (!ul) {
            ul = document.createElement('ul');
            lm.appendChild(ul);
        }

        // Get all the li nodes in the ul.
        var q = [], // queue to contain existing li's for reuse.
            li,
            lis = document.querySelectorAll('li');
        for (var i = 0, liLength = lis.length; i < liLength; i++) {
            q.push(lis[i]);
        }

        // For each layer in the layer list:
        for (var j = 0, llLength = layerList.length; j < llLength; j++) {
            var layer = layerList[j],
                isNewNode = false;

            // Get or create an li element.
            if (q.length > 0) {
                li = q[0];
                q.splice(0, 1);
            } else {
                li = document.createElement('li');
                li.addEventListener('click', function (event) {
                    layerManager.onClick(event);
                });
                isNewNode = true;
            }

            // Set the li's text to the layer's display name.
            if (li.firstChild) {
                li.firstChild.nodeValue = layer.displayName;
            } else {
                li.appendChild(document.createTextNode(layer.displayName));
            }

            // Determine the layer's class and set that on the li.
            if (layer.enabled) {
                li.className = layer.inCurrentFrame ? 'layerVisible' : 'layerEnabled';
            } else {
                li.className = 'layerDisabled';
            }

            if (isNewNode) {
                ul.appendChild(li);
            }
        }

        // Remove unused existing li's.
        if (q.length > 0) {
            for (var k = 0, qLength = q.length; k < qLength; k++) {
                ul.removeChild(q[k]);
            }
        }
    };

    /**
     * Event handler for click events on this layer manager's list items.
     * @param {Event} event The click event that occurred.
     */
    LayerManager.prototype.onClick = function (event) {
        var layerName = event.target.firstChild.nodeValue;

        // Update the layer state for each layer in the current layer list.
        for (var i = 0, len = this.wwd.layers.length; i < len; i++) {
            var layer = this.wwd.layers[i];
            if (layer.displayName === layerName) {
                layer.enabled = !layer.enabled;
                this.update();
                this.wwd.redraw();
            }
        }
    };

    return LayerManager;
});