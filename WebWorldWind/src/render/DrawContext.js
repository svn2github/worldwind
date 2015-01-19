/*
 * Copyright (C) 2014 United States Government as represented by the Administrator of the
 * National Aeronautics and Space Administration. All Rights Reserved.
 */
/**
 * @exports DrawContext
 * @version $Id$
 */
define([
        '../error/ArgumentError',
        '../util/Color',
        '../util/FrameStatistics',
        '../globe/Globe',
        '../shaders/GpuProgram',
        '../cache/GpuResourceCache',
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
    function (ArgumentError,
              Color,
              FrameStatistics,
              Globe,
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
            this.clearColor = Color.MEDIUM_GRAY;

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

            /**
             * Indicates whether the frame is being drawn for picking.
             * @type {boolean}
             */
            this.pickingMode = false;

            /**
             * A "virtual" canvas for creating texture maps of SVG text.
             * @type {Canvas}
             */
            this.canvas2D = null;

            /**
             * A 2D context derived from the "virtual" canvas.
             */
            this.ctx2D = null;
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
            var eyePoint = this.navigatorState.eyePoint;

            this.globe.computePositionFromPoint(eyePoint[0], eyePoint[1], eyePoint[2], this.eyePosition);
            this.screenProjection.setToScreenProjection(this.navigatorState.viewport);
        };

        /**
         * Indicates whether terrain exists.
         * @returns {boolean} <code>true</code> if there is terrain, otherwise <code>false</code>.
         */
        DrawContext.prototype.hasTerrain = function () {
            return this.terrain && this.terrain.surfaceGeometry && (this.terrain.surfaceGeometry.length > 0);
        };

        /**
         * Binds a specified GPU program.
         * This function also makes the program the current program.
         * @param {WebGLRenderingContext} gl The current WebGL drawing context.
         * @param {GpuProgram} program The program to bind. May be null or undefined, in which case the currently
         * bound program is unbound.
         */
        DrawContext.prototype.bindProgram = function (gl, program) {
            if (program) {
                program.bind(gl);
            } else {
                gl.useProgram(null);
            }

            this.currentProgram = program;
        };

        /**
         * Binds a potentially cached GPU program, creating and caching it if it isn't already cached.
         * This function also makes the program the current program.
         * @param {WebGLRenderingContext} gl The current WebGL drawing context.
         * @param {function} programConstructor The constructor to use to create the program.
         * @returns {GpuProgram} The bound program.
         * @throws {ArgumentError} If the specified constructor is null or undefined.
         */
        DrawContext.prototype.findAndBindProgram = function (gl, programConstructor) {
            if (!programConstructor) {
                throw new ArgumentError(
                    Logger.logMessage(Logger.LEVEL_SEVERE, "DrawContext", "bindProgramForKey",
                        "The specified program constructor is null or undefined."));
            }

            var program = this.gpuResourceCache.programForKey(programConstructor);
            if (program) {
                this.bindProgram(gl, program);
            } else {
                try {
                    program = new programConstructor(gl);
                    this.bindProgram(gl, program);
                    this.gpuResourceCache.putResource(gl, programConstructor, program, WorldWind.GPU_PROGRAM, program.size);
                } catch (e) {
                    Logger.log(Logger.LEVEL_SEVERE, "Error attempting to create GPU program.")
                }
            }

            return program;
        };

        return DrawContext;
    }
)
;