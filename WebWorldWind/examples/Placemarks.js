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
        //wwd.addLayer(new WorldWind.BMNGLandsatLayer());
        //wwd.addLayer(new WorldWind.BingWMSLayer());

        var images = [
            "plain-black.png",
            "plain-blue.png",
            "plain-brown.png",
            "plain-gray.png",
            "plain-green.png",
            "plain-orange.png",
            "plain-purple.png",
            "plain-red.png",
            "plain-teal.png",
            "plain-white.png",
            "plain-yellow.png",
            "castshadow-black.png",
            "castshadow-blue.png",
            "castshadow-brown.png",
            "castshadow-gray.png",
            "castshadow-green.png",
            "castshadow-orange.png",
            "castshadow-purple.png",
            "castshadow-red.png",
            "castshadow-teal.png",
            "castshadow-white.png"
        ];

        var pinLibrary =  "http://worldwindserver.net/webworldwind/images/pushpins/",
            placemark,
            placemarkAttributes = new WorldWind.PlacemarkAttributes(null),
            placemarkLayer = new WorldWind.RenderableLayer(),
            latitude = 46,
            longitude = -122;

        placemarkAttributes.imageScale = 1;
        placemarkAttributes.imageColor = WorldWind.Color.WHITE;

        for (var i = 0, len = images.length; i < len; i++) {
            placemark = new WorldWind.Placemark(new WorldWind.Position(latitude, longitude + i, 1e3));
            placemarkAttributes = new WorldWind.PlacemarkAttributes(placemarkAttributes);
            placemarkAttributes.imagePath = pinLibrary + images[i];
            placemark.attributes = placemarkAttributes;
            placemarkLayer.addRenderable(placemark);
        }

        placemarkLayer.displayName = "Placemarks";
        wwd.addLayer(placemarkLayer);

        wwd.redraw();

        var layerManger = new LayerManager('divLayerManager', wwd);

        var onTimeout = function () {
            var pickList = wwd.pick(new WorldWind.Vec2(190, 216));
            for (var i = 0, len = pickList.objects.length; i < len; i++) {
                console.log(pickList.objects[i].userObject.attributes.imagePath);
            }

            window.setTimeout(onTimeout, 2000);
        };
        window.setTimeout(onTimeout, 2000);
    });