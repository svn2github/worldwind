/*
 * Copyright (C) 2014 United States Government as represented by the Administrator of the
 * National Aeronautics and Space Administration. All Rights Reserved.
 */
/**
 * @exports BasicProgram
 * @version $Id$
 */
define([
        '../error/ArgumentError',
        '../util/Color',
        '../shaders/GpuProgram',
        '../util/Logger',
        '../geom/Matrix'
    ],
    function (ArgumentError,
              Color,
              GpuProgram,
              Logger,
              Matrix) {
        "use strict";

        /**
         * Constructs a new program.
         * Initializes, compiles and links this GLSL program with the source code for its vertex and fragment shaders.
         * <p>
         * This method creates WebGL shaders for the program's shader sources and attaches them to a new GLSL program. This
         * method then compiles the shaders and then links the program if compilation is successful. Use the bind method to make the
         * program current during rendering.
         *
         * @alias BasicProgram
         * @constructor
         * @augments GpuProgram
         * @classdesc BasicProgram is a GLSL program that draws geometry in a solid color.
         * @param {WebGLRenderingContext} gl The current WebGL context.
         * @throws {ArgumentError} If the shaders cannot be compiled, or linking of
         * the compiled shaders into a program fails.
         */
        var BasicProgram = function (gl) {
            var vertexShaderSource =
                    'attribute vec4 vertexPoint;\n' +
                    'uniform mat4 mvpMatrix;\n' +
                    'void main() {gl_Position = mvpMatrix * vertexPoint;}',
                fragmentShaderSource =
                    'precision mediump float;\n' +
                    'uniform vec4 color;\n' +
                    'void main() {gl_FragColor = color;}';

            // Call to the superclass, which performs shader program compiling and linking.
            GpuProgram.call(this, gl, vertexShaderSource, fragmentShaderSource);

            /**
             * The WebGL location for this program's 'vertexPoint' attribute.
             * @type {Number}
             */
            this.vertexPointLocation = this.attributeLocation(gl, "vertexPoint");

            /**
             * The WebGL location for this program's 'mvpMatrix' uniform.
             * @type {WebGLUniformLocation}
             */
            this.mvpMatrixLocation = this.uniformLocation(gl, "mvpMatrix");

            /**
             * The WebGL location for this program's 'color' uniform.
             * @type {WebGLUniformLocation}
             */
            this.colorLocation = this.uniformLocation(gl, "color");
        };

        // Inherit from GpuProgram.
        BasicProgram.prototype = Object.create(GpuProgram.prototype);

        /**
         * Loads the specified matrix as the value of this program's 'mvpMatrix' uniform variable.
         *
         * @param {WebGLRenderingContext} gl The current WebGL context.
         * @param {Matrix} matrix The matrix to load.
         * @throws {ArgumentError} If the specified matrix is null or undefined.
         */
        BasicProgram.prototype.loadModelviewProjection = function (gl, matrix) {
            if (!matrix) {
                throw new ArgumentError(
                    Logger.logMessage(Logger.LEVEL_SEVERE, "BasicProgram", "loadModelviewProjection", "missingMatrix"));
            }

            GpuProgram.loadUniformMatrix(gl, matrix, this.mvpMatrixLocation);
        };

        /**
         * Loads the specified color as the value of this program's 'color' uniform variable.
         *
         * @param {WebGLRenderingContext} gl The current WebGL context.
         * @param {Color} color The color to load.
         * @throws {ArgumentError} If the specified color is null or undefined.
         */
        BasicProgram.prototype.loadColor = function (gl, color) {
            if (!color) {
                throw new ArgumentError(
                    Logger.logMessage(Logger.LEVEL_SEVERE, "BasicProgram", "loadColor", "missingColor"));
            }

            GpuProgram.loadUniformColor(gl, color, this.colorLocation);
        };

        /**
         * Loads the specified pick color as the value of this program's 'color' uniform variable.
         *
         * @param {WebGLRenderingContext} gl The current WebGL context.
         * @param {Number} pickColor The color to load, expressed as a Number.
         */
        BasicProgram.prototype.loadPickColor = function (gl, pickColor) {
            GpuProgram.loadUniformPickColor(gl, pickColor, this.colorLocation);
        };

        return BasicProgram;
    });