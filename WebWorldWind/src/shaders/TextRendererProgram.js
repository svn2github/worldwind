/*
 * Copyright (C) 2014 United States Government as represented by the Administrator of the
 * National Aeronautics and Space Administration. All Rights Reserved.
 */
/**
 * @exports TextRendererProgram
 * @version $Id: TextRendererProgram.js 2658 2015-01-19 23:51:58Z danm $
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
         * Constructs a new text-renderer program.
         * Initializes, compiles and links this GLSL program with the source code for its vertex and fragment shaders.
         * <p>
         * This method creates WebGL shaders for the program's shader sources and attaches them to a new GLSL program. This
         * method then compiles the shaders and links the program if compilation is successful. Use the bind method to make the
         * program current during rendering.
         *
         * @alias TextRendererProgram
         * @constructor
         * @augments GpuProgram
         * @classdesc A GLSL program that draws text.
         * Application's typically do not interact with this class.
         * @param {WebGLRenderingContext} gl The current WebGL context.
         */
        var TextRendererProgram = function(gl) {
            var vertexShaderSource =
                    'attribute vec4 vertexPoint;\n' +
                    'attribute vec4 vertexTexCoord;\n' +
                    'uniform mat4 mvpMatrix;\n' +
                    'uniform mat4 texSamplerMatrix;\n' +
                    'varying vec2 texSamplerCoord;\n' +
                    'void main() {\n' +
                    'gl_Position = mvpMatrix * vertexPoint;\n' +
                        /* Transform the vertex texture coordinate into sampler texture coordinates. */
                    'texSamplerCoord = (texSamplerMatrix * vertexTexCoord).st;\n' +
                    '}',
                fragmentShaderSource =
                    'precision mediump float;\n' +
                        /* Uniform sampler indicating the texture 2D unit (0, 1, 2, etc.) to use when sampling texture color. */
                    'uniform sampler2D texSampler;\n' +
                    'varying vec2 texSamplerCoord;\n' +
                        /*
                         * OpenGL ES Shading Language v1.00 fragment shader for SurfaceTileRendererProgram. Writes the value of the texture 2D
                         * object bound to texSampler at the current transformed texture coordinate, multiplied by the uniform opacity. Writes
                         * transparent black (0, 0, 0, 0) if the transformed texture coordinate indicates a texel outside of the texture data's
                         * standard range of [0,1].
                         */
                    'void main(void) {\n' +
                        /* Return either the sampled texture2D color multiplied by opacity or transparent black. */
                    'gl_FragColor = texture2D(texSampler, texSamplerCoord);\n' +
                    '}';

            // Call to the superclass, which performs shader program compiling and linking.
            GpuProgram.call(this, gl, vertexShaderSource, fragmentShaderSource);
            // Capture the attribute and uniform locations.

            /**
             * This program's vertex point location.
             * @type {Number}
             */
            this.vertexPointLocation = this.attributeLocation(gl, "vertexPoint");

            /**
             * This program's texture coordinate location.
             * @type {Number}
             */
            this.vertexTexCoordLocation = this.attributeLocation(gl, "vertexTexCoord");

            /**
             * This program's modelview-projection matrix location.
             * @type {WebGLUniformLocation}
             */
            this.mvpMatrixLocation = this.uniformLocation(gl, "mvpMatrix");

            // The rest of these are strictly internal and intentionally not documented.
            this.texSamplerMatrixLocation = this.uniformLocation(gl, "texSamplerMatrix");
            this.texSamplerLocation = this.uniformLocation(gl, "texSampler");

            /**
             * The WebGL location for this program's 'vertexTexCoord' attribute.
             * @type {Number}
             */
            this.vertexPointLocation = -1;
        };

        TextRendererProgram.prototype = Object.create(GpuProgram.prototype);

        /**
         * Loads the specified matrix as the value of this program's 'mvpMatrix' uniform variable.
         *
         * @param {WebGLRenderingContext} gl The current WebGL context.
         * @param {Matrix} matrix The matrix to load.
         * @throws {ArgumentError} If the specified matrix is null or undefined.
         */
        TextRendererProgram.prototype.loadModelviewProjection = function (gl, matrix) {
            if (!matrix) {
                throw new ArgumentError(
                    Logger.logMessage(Logger.LEVEL_SEVERE, "TextRendererProgram", "loadModelviewProjection",
                        "missingMatrix"));
            }

            GpuProgram.loadUniformMatrix(gl, matrix, this.mvpMatrixLocation);
        };

        /**
         * Loads the specified matrix as the value of this program's 'texSamplerMatrix' uniform variable.
         *
         * @param {WebGLRenderingContext} gl The current WebGL context.
         * @param {Matrix} matrix The matrix to load.
         * @throws {ArgumentError} If the specified matrix is null or undefined.
         */
        TextRendererProgram.prototype.loadTexSamplerMatrix = function (gl, matrix) {
            if (!matrix) {
                throw new ArgumentError(
                    Logger.logMessage(Logger.LEVEL_SEVERE, "TextRendererProgram", "loadTexSamplerMatrix",
                        "missingMatrix"));
            }

            GpuProgram.loadUniformMatrix(gl, matrix, this.texSamplerMatrixLocation);
        };

        /**
         * Loads the specified texture unit ID as the value of this program's 'texSampler' uniform variable.
         * The specified unit ID must be one of the GL_TEXTUREi WebGL enumerations, where i ranges from 0 to
         * GL_MAX_COMBINED_TEXTURE_IMAGE_UNITS - 1.
         *
         * @param {WebGLRenderingContext} gl The current WebGL context.
         * @param {number} unit The unit ID to load.
         */
        TextRendererProgram.prototype.loadTexSampler = function (gl, unit) {
            gl.uniform1i(this.texSamplerLocation, unit - WebGLRenderingContext.TEXTURE0);
        };

        return TextRendererProgram;
    }
);