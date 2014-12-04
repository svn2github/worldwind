/*
 * Copyright (C) 2014 United States Government as represented by the Administrator of the
 * National Aeronautics and Space Administration. All Rights Reserved.
 */
/**
 * @exports DrawContext
 * @version $Id$
 */
define([
        '../util/Color',
        '../util/FrameStatistics',
        '../globe/Globe',
        '../shaders/GpuProgram',
        '../render/GpuResourceCache',
        '../layer/LayerList',
        '../navigate/NavigatorState',
        '../layer/Layer',
        '../util/Logger',
        '../geom/Matrix',
        '../geom/Position',
        '../geom/Rectangle',
        '../geom/Sector',
        '../render/SurfaceTileRenderer',
        '../globe/Terrain',
        '../globe/Tessellator'
    ],
    function (Color,
              FrameStatistics,
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
            /**
             * The starting time of the current frame, in milliseconds.
             * @type {Number}
             */
            this.timestamp = new Date().getTime();

            /**
             * The globe being rendered.
             * @type {Globe}
             */
            this.globe = null;

            /**
             * The layer being rendered.
             * @type {Layer}
             */
            this.currentLayer = null;

            /**
             * The current state of the associated navigator.
             * @type {NavigatorState}
             */
            this.navigatorState = null;

            /**
             * The terrain for the current frame.
             * @type {Terrain}
             */
            this.terrain = null;

            /**
             * The maximum geographic area currently in view.
             * @type {Sector}
             */
            this.visibleSector = null;

            /**
             * The current GPU program.
             * @type {GpuProgram}
             */
            this.currentProgram = null;

            /**
             * The current vertical exaggeration.
             * @type {Number}
             */
            this.verticalExaggeration = 1;

            /**
             * The surface-tile-renderer to use for drawing surface tiles.
             * @type {SurfaceTileRenderer}
             */
            this.surfaceTileRenderer = new SurfaceTileRenderer();

            /**
             * The GPU resource cache, which tracks WebGL resources.
             * @type {GpuResourceCache}
             */
            this.gpuResourceCache = new GpuResourceCache();

            /**
             * The current eye position.
             * @type {Position}
             */
            this.eyePosition = new Position(0, 0, 0);

            /**
             * The current screen projection matrix.
             * @type {Matrix}
             */
            this.screenProjection = Matrix.fromIdentity();

            /**
             * The current clear color, expressed as an array of Number in the order red, green, blue, alpha.
             * @type {Color}
             * @default red = 0, green = 0, blue = 0, alpha = 1
             */
            this.clearColor = new Color(1, 0, 0, 1);

            /**
             * Frame statistics.
             * @type {FrameStatistics}
             */
            this.frameStatistics = new FrameStatistics();

            /**
             * The current WebGL context.
             * @type {WebGLRenderingContext}
             */
            this.currentGlContext = null;
        };

        /**
         * Prepare this draw context for the drawing of a new frame.
         */
        DrawContext.prototype.reset = function () {
            var oldTimeStamp = this.timestamp;
            this.timestamp = new Date().getTime();
            if (this.timestamp === oldTimeStamp)
                ++this.timestamp;
        };

        /**
         * Computes any values necessary to render the upcoming frame. Called after all draw context state for the
         * frame has been set.
         */
        DrawContext.prototype.update = function () {
            //var eyePoint = this.navigatorState.eyePoint;
            //
            //this.globe.computePositionFromPoint(eyePoint[0], eyePoint[1], eyePoint[2], this.eyePosition);
            //this.screenProjection.setToScreenProjection(this.navigatorState.viewport);
        };

        return DrawContext;
    }
)
;