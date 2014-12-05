/*
 * Copyright (C) 2014 United States Government as represented by the Administrator of the
 * National Aeronautics and Space Administration. All Rights Reserved.
 */
/**
 * @exports Texture
 * @version $Id$
 */
define([
        '../util/Logger'
    ],
    function (Logger) {
        "use strict";

        /**
         * Constructs a GPU resource cache for a specified size and low-water value in bytes.
         * @alias Texture
         * @constructor
         * @classdesc Represents a WebGL texture.
         */
        var Texture = function() {

            this.originalImageWidth = 0;

            this.originalImageHeight = 0;

            this.imageWidth = 0;

            this.imageHeight = 0;
        };

        return Texture;
    });