/*
 * Copyright (C) 2014 United States Government as represented by the Administrator of the
 * National Aeronautics and Space Administration. All Rights Reserved.
 */
/**
 * @version $Id$
 */

requirejs(['../src/WorldWind',
        './LayerManager/LayerManager'],
    function (ww,
              LayerManager) {
        "use strict";

        WorldWind.Logger.setLoggingLevel(WorldWind.Logger.LEVEL_WARNING);

        var wwd = new WorldWind.WorldWindow("canvasOne");
        wwd.addLayer(new WorldWind.BMNGLandsatLayer());
        wwd.addLayer(new WorldWind.BingWMSLayer());

        var placemark = new WorldWind.Placemark(new WorldWind.Position(46, -123, 1e3)),
            placemarkAttributes = new WorldWind.PlacemarkAttributes(null),
            placemarkLayer = new WorldWind.RenderableLayer();

        placemarkAttributes.imageScale = 100;
        //placemarkAttributes.imagePath = "http://worldwindserver.net/webworldwind/images/AppIconPad64.png";
        placemark.attributes = placemarkAttributes;
        placemarkLayer.addRenderable(placemark);
        wwd.addLayer(placemarkLayer);

        wwd.redraw();

        var layerManger = new LayerManager('divLayerManager', wwd);
    });