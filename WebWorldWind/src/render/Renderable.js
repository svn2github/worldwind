/*
 * Copyright (C) 2014 United States Government as represented by the Administrator of the
 * National Aeronautics and Space Administration. All Rights Reserved.
 */
/**
 * @exports Renderable
 * @version $Id$
 */
define([
        '../util/Logger',
        '../error/UnsupportedOperationError'
    ],
    function (Logger,
              UnsupportedOperationError) {
        "use strict";

        /**
         * Constructs a base renderable.
         * @alias Renderable
         * @constructor
         * @classdesc Represents a shape or other object that can be rendered. This is an abstract class and is not
         * meant to be instantiated directly.
         */
        var Renderable = function () {

            /**
             * The display name of the renderable.
             * @type {string}
             */
            this.displayName = "Renderable";

            /**
             * Indicates whether this renderable is displayed.
             * @type {boolean}
             */
            this.enabled = true;
        };

        Renderable.prototype.render = function (dc) {
            throw new UnsupportedOperationError(
                Logger.logMessage(Logger.LEVEL_SEVERE, "Renderable", "render", "abstractInvocation"));
        };

        return Renderable;
    });