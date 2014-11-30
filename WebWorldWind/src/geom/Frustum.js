/*
 * Copyright (C) 2014 United States Government as represented by the Administrator of the
 * National Aeronautics and Space Administration. All Rights Reserved.
 */
/**
 * @exports Frustum
 * @version $Id$
 */
define([
        'src/error/ArgumentError',
        'src/geom/Plane',
        'src/util/Logger'
    ],
    function (ArgumentError,
              Plane,
              Logger) {
        "use strict";

        /**
         * Constructs a frustum.
         * @alias Frustum
         * @constructor
         * @classdesc Represents a six-sided view frustum in Cartesian coordinates.
         * @param {Plane} left The frustum's left plane.
         * @param {Plane} right The frustum's right plane.
         * @param {Plane} bottom The frustum's bottom plane.
         * @param {Plane} top The frustum's top plane.
         * @param {Plane} near The frustum's near plane.
         * @param {Plane} far The frustum's far plane.
         * @throws {ArgumentError} If any specified plane is null or undefined.
         */
        var Frustum = function (left, right, bottom, top, near, far) {
            if (!left || !right || !bottom || !top || !near || !far) {
                throw new ArgumentError(
                    Logger.logMessage(Logger.LEVEL_SEVERE, "Frustum", "constructor", "missingPlane"));
            }
            this.left = left;
            this.right = right;
            this.bottom = bottom;
            this.top = top;
            this.near = near;
            this.far = far;
        };

        return Frustum;
    });