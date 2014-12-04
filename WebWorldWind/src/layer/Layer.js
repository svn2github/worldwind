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
         * @classdesc Provides a base class for layer implementations. This class is not meant to be instantiated
         * directly.
         */
        var Layer = function () {
        };

        return Layer;
    });