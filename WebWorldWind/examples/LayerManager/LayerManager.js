/*
 * Copyright (C) 2014 United States Government as represented by the Administrator of the
 * National Aeronautics and Space Administration. All Rights Reserved.
 */
/**
 * @version $Id$
 */
define(function () {
    var LayerManager = function (layerManagerName, worldWindow) {
        this.layerManagerName = layerManagerName;
        this.wwd = worldWindow;

        var layerManger = this;
        this.wwd.redrawCallbacks.push(function (wwd) {
            layerManger.update();
        });

        this.update();
    };

    LayerManager.prototype.update = function () {
        var layerManager = this,
            layerList = this.wwd.layers,
            lm = document.querySelector('#' + this.layerManagerName),
            ul = lm.querySelector('ul');

        // if !ul then create one
        if (!ul) {
            ul = document.createElement('ul');
            lm.appendChild(ul);
        }

        // get li nodes in ul
        var q = [],
            li,
            lis = document.querySelectorAll('li');
        for (var i = 0, liLength = lis.length; i < liLength; i++) {
            q.push(lis[i]);
        }

        // for each layer in the layer list
        for (var j = 0, llLength = layerList.layers.length; j < llLength; j++) {
            var layer = layerList.layers[j],
                isNewNode = false;

            // get or create a li element
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

            // set the li's text to the layer's display name
            if (li.firstChild) {
                li.firstChild.nodeValue = layer.displayName;
            } else {
                li.appendChild(document.createTextNode(layer.displayName));
            }

            // determine the layer's class and set that on the li
            if (layer.enabled) {
                li.className = layer.inCurrentFrame ? 'layerVisible' : 'layerEnabled';
            } else {
                li.className = 'layerDisabled';
            }

            if (isNewNode) {
                ul.appendChild(li);
            }
        }

        if (q.length > 0) {
            for (var k = 0, qLength = q.length; k < qLength; k++) {
                ul.removeChild(q[k]);
            }
        }
    };

    LayerManager.prototype.onClick = function (event) {
        var layerName = event.target.firstChild.nodeValue;;

        for (var i = 0, len = this.wwd.layers.layers.length; i < len; i++) {
            var layer = this.wwd.layers.layers[i];

            if (layer.displayName === layerName) {
                layer.enabled = !layer.enabled;
                this.update();
                this.wwd.redraw();
            }
        }
    };

    return LayerManager;
});