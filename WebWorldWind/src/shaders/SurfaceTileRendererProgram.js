/*
 * Copyright (C) 2014 United States Government as represented by the Administrator of the
 * National Aeronautics and Space Administration. All Rights Reserved.
 */
/**
 * @exports SurfaceTileRendererProgram
 * @version $Id$
 */
define([
        '../error/ArgumentError',
        '../util/Color',
        '../shaders/GpuProgram',
        '../util/Logger',
        '../geom/Matrix',
        '../error/NotYetImplementedError'
    ],
    function (ArgumentError,
              Color,
              GpuProgram,
              Logger,
              Matrix,
              NotYetImplementedError) {
        "use strict";

        /**
         * Constructs a new surface-tile-renderer program.
         * Initializes, compiles and links this GLSL program with the source code for its vertex and fragment shaders.
         * <p>
         * This method creates WebGL shaders for the program's shader sources and attaches them to a new GLSL program. This
         * method then compiles the shaders and links the program if compilation is successful. Use the bind method to make the
         * program current during rendering.
         *
         * @alias SurfaceTileRendererProgram
         * @constructor
         * @augments GpuProgram
         * @classdesc A GLSL program that draws textured geometry on the globe's terrain.
         * Application's typically do not interact with this class.
         * @param {WebGLRenderingContext} gl The current WebGL context.
         */
        var SurfaceTileRendererProgram = function (gl) {
            GpuProgram.call(this, gl, null, null); // TODO

            /**
             * The WebGL location for this program's 'vertexPoint' attribute.
             * @type {Number}
             */
            this.vertexPointLocation = -1;

            /**
             * The WebGL location for this program's 'vertexTexCoord' attribute.
             * @type {Number}
             */
            this.vertexPointLocation = -1;
        };

        SurfaceTileRendererProgram.prototype = Object.create(GpuProgram.prototype);

        /**
         * Loads the specified matrix as the value of this program's 'mvpMatrix' uniform variable.
         *
         * @param {WebGLRenderingContext} gl The current WebGL context.
         * @param {Matrix} matrix The matrix to load.
         * @throws {ArgumentError} If the specified matrix is null or undefined.
         */
        SurfaceTileRendererProgram.prototype.loadModelviewProjection = function (gl, matrix) {
            if (!matrix) {
                throw new ArgumentError(
                    Logger.logMessage(Logger.LEVEL_SEVERE, "SurfaceTileRendererProgram", "loadModelviewProjection",
                        "missingMatrix"));
            }

            // TODO
            throw new NotYetImplementedError(
                Logger.logMessage(Logger.LEVEL_SEVERE, "SurfaceTileRendererProgram", "loadModelviewProjection",
                    "notYetImplemented"));
        };

        /**
         * Loads the specified matrix as the value of this program's 'texSamplerMatrix' uniform variable.
         *
         * @param {WebGLRenderingContext} gl The current WebGL context.
         * @param {Matrix} matrix The matrix to load.
         * @throws {ArgumentError} If the specified matrix is null or undefined.
         */
        SurfaceTileRendererProgram.prototype.loadTexSamplerMatrix = function (gl, matrix) {
            if (!matrix) {
                throw new ArgumentError(
                    Logger.logMessage(Logger.LEVEL_SEVERE, "SurfaceTileRendererProgram", "loadTexSamplerMatrix",
                        "missingMatrix"));
            }

            // TODO
            throw new NotYetImplementedError(
                Logger.logMessage(Logger.LEVEL_SEVERE, "SurfaceTileRendererProgram", "loadTexSamplerMatrix",
                    "notYetImplemented"));
        };

        /**
         * Loads the specified matrix as the value of this program's 'loadTexMaskMatrix' uniform variable.
         *
         * @param {WebGLRenderingContext} gl The current WebGL context.
         * @param {Matrix} matrix The matrix to load.
         * @throws {ArgumentError} If the specified matrix is null or undefined.
         */
        SurfaceTileRendererProgram.prototype.loadTexMaskMatrix = function (gl, matrix) {
            if (!matrix) {
                throw new ArgumentError(
                    Logger.logMessage(Logger.LEVEL_SEVERE, "SurfaceTileRendererProgram", "loadTexMaskMatrix",
                        "missingMatrix"));
            }

            // TODO
            throw new NotYetImplementedError(
                Logger.logMessage(Logger.LEVEL_SEVERE, "SurfaceTileRendererProgram", "loadTexMaskMatrix",
                    "notYetImplemented"));
        };

        /**
         * Loads the specified texture unit ID as the value of this program's 'texSampler' uniform variable.
         * The specified unit ID must be one of the GL_TEXTUREi WebGL enumerations, where i ranges from 0 to
         * GL_MAX_COMBINED_TEXTURE_IMAGE_UNITS - 1.
         *
         * @param {WebGLRenderingContext} gl The current WebGL context.
         * @param {number} unit The unit ID to load.
         */
        SurfaceTileRendererProgram.prototype.texSampler = function (gl, unit) {
            // TODO
            throw new NotYetImplementedError(
                Logger.logMessage(Logger.LEVEL_SEVERE, "SurfaceTileRendererProgram", "texSampler",
                    "notYetImplemented"));
        };

        /**
         * Loads the specified value as the value of this program's 'opacity' uniform variable.
         *
         * @param {WebGLRenderingContext} gl The current WebGL context.
         * @param {number} opacity The opacity to load.
         */
        SurfaceTileRendererProgram.prototype.loadOpacity = function (gl, opacity) {
            // TODO
            throw new NotYetImplementedError(
                Logger.logMessage(Logger.LEVEL_SEVERE, "SurfaceTileRendererProgram", "loadOpacity",
                    "notYetImplemented"));
        };

        return SurfaceTileRendererProgram;
    });