/*
 * Copyright (C) 2014 United States Government as represented by the Administrator of the
 * National Aeronautics and Space Administration. All Rights Reserved.
 */
/**
 * @exports PlacemarkAttributes
 * @version $Id$
 */
define([
        '../util/Color',
        '../util/Offset'
    ],
    function (Color,
              Offset) {
        "use strict";

        /**
         * Constructs a placemark attributes bundle.
         * The defaults indicate a placemark displayed as a white 1x1 square centered on the placemark's geographic position.
         * @alias PlacemarkAttributes
         * @constructor
         * @classdesc Holds attributes applied to [Placemark]{@link Placemark} shapes.
         * <p>
         * Placemarks may be drawn either as an image or as a square with a specified size. When the placemark attributes
         * have a valid image path the placemark's image is drawn as a screen rectangle in the image's original dimensions, scaled
         * by the image scale. Otherwise, the placemark is drawn as a screen square with width and height equal to image scale.
         * @param {PlacemarkAttributes} attributes Attributes to initialize this attributes instance to. May be null,
         * in which case the new instance contains default attributes.
         */
        var PlacemarkAttributes = function (attributes) {

            /**
             * The image color.
             * When this attribute bundle has a valid image path the placemark's image is multiplied by this image
             * color to achieve the final placemark color. Otherwise the placemark is drawn in this color.
             * @type {Color}
             * @default White (1, 1, 1, 1)
             */
            this.imageColor = (attributes && attributes.imageColor) ? attributes.imageColor : new Color(1, 1, 1, 1);

            /**
             * Indicates a location within the placemark's image or square that is placed at the placemark's geographic
             * position.
             * When this attribute bundle has a valid image path the offset is relative to the image dimensions. Otherwise, the
             * offset is relative to a square with width and height equal to imageScale. The offset has its origin at the image or
             * square's bottom-left corner and has axes that extend up and to the right from the origin point. May be null to
             * indicate that the image or square's bottom-left corner should be placed at the geographic position.
             * @type {Offset}
             * @default 0.5, 0.5, fractional
             */
            this.imageOffset = (attributes && attributes.imageOffset) ? attributes.imageOffset
                : new Offset(0.5, 0.5);

            /**
             * Indicates the amount to scale the placemark's image.
             * When this attribute bundle has a valid image path the scale is applied to the image's dimensions. Otherwise, the
             * scale indicates the dimensions of a square drawn at the point placemark's geographic position. Setting imageScale to
             * 0 causes the placemark to disappear.
             * @type {Number}
             * @default 1
             */
            this.imageScale = (attributes && attributes.imageScale) ? attributes.imageScale : 1;

            /**
             * The image URL.
             * @type {String}
             * @default null
             */
            this.imagePath = (attributes && attributes.imagePath) ? attributes.imagePath : null;
        };

        return PlacemarkAttributes;
    });