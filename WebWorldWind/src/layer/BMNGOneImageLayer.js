/*
 * Copyright (C) 2014 United States Government as represented by the Administrator of the
 * National Aeronautics and Space Administration. All Rights Reserved.
 */
/**
 * @exports BMNGOneImageLayer
 * @version $Id$
 */
define([
        '../layer/RenderableLayer',
        '../geom/Sector',
        '../shapes/SurfaceImage'
    ],
    function (RenderableLayer,
              Sector,
              SurfaceImage) {
        "use strict";

        /**
         * Constructs a Blue Marble image layer that spans the entire globe.
         * @alias BMNGOneImageLayer
         * @constructor
         * @classdesc Displays a Blue Marble image layer that spans the entire globe with a single image.
         */
        var BMNGOneImageLayer = function () {
            RenderableLayer.call(this, "Blue Marble Image");

            var surfaceImage = new SurfaceImage(Sector.FULL_SPHERE,
                "../src/resources/BMNG_world.topo.bathy.200405.3.2048x1024.jpg");

            this.addRenderable(surfaceImage);

            this.pickEnabled = false;
        };

        BMNGOneImageLayer.prototype = Object.create(RenderableLayer.prototype);

        return BMNGOneImageLayer;
    });