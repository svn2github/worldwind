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
        '../render/SurfaceTileRenderer'
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
              SurfaceTileRenderer) {
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

            this.orderedRenderables = [];
        };

        /**
         * Prepare this draw context for the drawing of a new frame.
         */
        DrawContext.prototype.reset = function () {
            var oldTimeStamp = this.timestamp;
            this.timestamp = new Date().getTime();
            if (this.timestamp === oldTimeStamp)
                ++this.timestamp;

            this.orderedRenderables = []; // clears the ordered renderables array
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

        /**
         * Adds an ordered renderable to this draw context's ordered renderable list.
         * @param {OrderedRenderable} orderedRenderable The ordered renderable to add. May be null, in which case the
         * current ordered renderable list remains unchanged.
         */
        DrawContext.prototype.addOrderedRenderable = function (orderedRenderable) {
            if (orderedRenderable) {
                orderedRenderable.insertionTime = Date.now();
                this.orderedRenderables.push(orderedRenderable);
            }
        };

        /**
         * Adds an ordered renderable to the end of this draw context's ordered renderable list.
         * @param {OrderedRenderable} orderedRenderable The ordered renderable to add. May be null, in which case the
         * current ordered renderable list remains unchanged.
         */
        DrawContext.prototype.addOrderedRenderableToBack = function (orderedRenderable) {
            if (orderedRenderable) {
                orderedRenderable.insertionTime = Date.now();
                orderedRenderable.eyeDistance = Number.MAX_VALUE;
                this.orderedRenderables.push(orderedRenderable);
            }
        };

        /**
         * Returns the ordered renderable at the head of the ordered renderable list without removing it from the list.
         * @returns {OrderedRenderable} The first ordered renderable in this draw context's ordered renderable list, or
         * null if the ordered renderable list is empty.
         */
        DrawContext.prototype.peekOrderedRenderable = function () {
            if (this.orderedRenderables.length > 0) {
                return this.orderedRenderables[this.orderedRenderables.length - 1];
            } else {
                return null;
            }
        };

        /**
         * Returns the ordered renderable at the head of the ordered renderable list and removes it from the list.
         * @returns {OrderedRenderable} The first ordered renderable in this draw context's ordered renderable list, or
         * null if the ordered renderable list is empty.
         */
        DrawContext.prototype.popOrderedRenderable = function () {
            if (this.orderedRenderables.length > 0) {
                return this.orderedRenderables.pop();
            } else {
                return null;
            }
        };

        /**
         * Sorts the ordered renderable list from nearest to the eye point to farthest from the eye point.
         */
        DrawContext.prototype.sortOrderedRenderables = function () {
            // Sort the ordered renderables by eye distance from front to back and then by insertion time. The ordered
            // renderable peek and pop access the back of the ordered renderable list, thereby causing ordered renderables to
            // be processed from back to front.

            this.orderedRenderables.sort(function(orA, orB) {
                var eA = orA.eyeDistance,
                    eB = orB.eyeDistance;

                if (eA < eB) { // orA is closer to the eye than orB; sort orA before orB
                    return -1;
                } else if (eA > eB) { // orA is farther from the eye than orB; sort orB before orA
                    return 1;
                } else { // orA and orB are the same distance from the eye; sort them based on insertion time
                    var tA = orA.insertionTime,
                        tB = orB.insertionTime;

                    if (tA > tB) {
                        return -1;
                    } else if (tA < tB) {
                        return 1;
                    } else {
                        return 0;
                    }
                }
            });
        };

        return DrawContext;
    }
)
;