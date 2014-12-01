/*
 * Copyright (C) 2014 United States Government as represented by the Administrator of the
 * National Aeronautics and Space Administration. All Rights Reserved.
 */
/**
 * @exports NavigatorState
 * @version $Id$
 */
define([
        'src/util/Logger',
        'src/geom/Matrix',
        'src/geom/Rectangle',
        'src/geom/Vec3'
    ],
    function (Logger,
              Matrix,
              Rectangle,
              Vec3) {
        "use strict";

        var NavigatorState = function () {

            this.eyePoint = new Vec3(0, 0, 0);

            this.viewport = new Rectangle(0, 0, 0, 0);

            this.modelview = Matrix.fromIdentity();

            this.projection = Matrix.fromIdentity();

            this.modelviewProjection = Matrix.fromIdentity();
        };

        return NavigatorState;
    });