/*
 * Copyright (C) 2014 United States Government as represented by the Administrator of the
 * National Aeronautics and Space Administration. All Rights Reserved.
 */
/**
 * @exports DrawContext
 * @version $Id$
 */
define([
        'src/util/FrameStatistics',
        'src/globe/Globe',
        'src/render/GpuProgram',
        'src/render/GpuResourceCache',
        'src/layer/LayerList',
        'src/navigate/NavigatorState',
        'src/layer/Layer',
        'src/util/Logger',
        'src/geom/Matrix',
        'src/geom/Position',
        'src/geom/Rectangle',
        'src/geom/Sector',
        'src/render/SurfaceTileRenderer',
        'src/globe/Terrain',
        'src/globe/Tessellator'
    ],
    function (FrameStatistics,
              Globe,
              LayerList,
              GpuProgram,
              GpuResourceCache,
              NavigatorState,
              Layer,
              Logger,
              Matrix,
              Position,
              Rectangle,
              Sector,
              SurfaceTileRenderer,
              Terrain,
              Tessellator) {
        "use strict";

        /**
         * Constructs a DrawContext.
         * @alias DrawContext
         * @constructor
         * @classdesc Provides current state during rendering. The current draw context is passed to most rendering
         * methods in order to make those methods aware of current state.
         */
        var DrawContext = function () {
            this.timestamp = new Date().getTime();

            this.globe = null;

            this.layerList = null;

            this.currentLayer = null;

            this.navigatorState = null;

            this.terrain = null;

            this.visibleSector = null;

            this.currentProgram = null;

            this.verticalExaggeration = 1;

            this.surfaceTileRenderer = new SurfaceTileRenderer();

            this.gpuResourceCache = new GpuResourceCache();

            this.eyePosition = new Position(0, 0, 0);

            this.screenProjection = Matrix.fromIdentity();

            this.clearColor = 0;

            this.frameStatistics = new FrameStatistics();
        };

        DrawContext.prototype.reset = function () {
            var oldTimeStamp = this.timestamp;
            this.timestamp = new Date().getTime();
            if (this.timestamp === oldTimeStamp)
                ++this.timestamp;
        };

        DrawContext.prototype.update = function () {
            var eyePoint = this.navigatorState.eyePoint;

            this.globe.computePositionFromPoint(eyePoint[0], eyePoint[1], eyePoint[2], this.eyePosition);
            this.screenProjection.setToScreenProjection(this.navigatorState.viewport);
        };

        return DrawContext;
    }
)
;