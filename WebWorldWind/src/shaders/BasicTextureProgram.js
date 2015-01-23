/*
 * Copyright (C) 2014 United States Government as represented by the Administrator of the
 * National Aeronautics and Space Administration. All Rights Reserved.
 */
/**
 * @exports BasicTextureProgram
 * @version $Id$
 */
define([
        '../error/ArgumentError',
        '../util/Color',
        '../shaders/GpuProgram',
        '../util/Logger'
    ],
    function (ArgumentError,
              Color,
              GpuProgram,
              Logger) {
        "use strict";

        /**
         * Constructs a new program.
         * Initializes, compiles and links this GLSL program with the source code for its vertex and fragment shaders.
         * <p>
         * This method creates WebGL shaders for the program's shader sources and attaches them to a new GLSL program. This
         * method then compiles the shaders and then links the program if compilation is successful. Use the bind method to make the
         * program current during rendering.
         *
         * @alias BasicTextureProgram
         * @constructor
         * @augments GpuProgram
         * @classdesc BasicTextureProgram is a GLSL program that draws textured geometry.
         * @param {WebGLRenderingContext} gl The current WebGL context.
         * @throws {ArgumentError} If the shaders cannot be compiled, or if linking of
         * the compiled shaders into a program fails.
         */
        var BasicTextureProgram = function (gl) {
            var vertexShaderSource =
                    'attribute vec4 vertexPoint;\n' +
                    'attribute vec4 vertexTexCoord;\n' +
                    'uniform mat4 mvpMatrix;\n' +
                    'uniform mat4 texCoordMatrix;\n' +
                    'varying vec2 texCoord;\n' +
                    'void main() {gl_Position = mvpMatrix * vertexPoint;\n' +
                    'texCoord = (texCoordMatrix * vertexTexCoord).st;}',
                fragmentShaderSource =
                    'precision mediump float;\n' +
                    'uniform float opacity;\n' +
                    'uniform vec4 color;\n' +
                    'uniform bool enableTexture;\n' +
                    'uniform sampler2D textureSampler;\n' +
                    'varying vec2 texCoord;\n' +
                    'void main() {vec4 textureColor = texture2D(textureSampler, texCoord) * color;\n' +
                    'gl_FragColor = mix(color, textureColor, float(enableTexture)) * opacity;}';

            // Call to the superclass, which performs shader program compiling and linking.
            GpuProgram.call(this, gl, vertexShaderSource, fragmentShaderSource);

            /**
             * The WebGL location for this program's 'vertexPoint' attribute.
             * @type {Number}
             */
            this.vertexPointLocation = this.attributeLocation(gl, "vertexPoint");

            /**
             * The WebGL location for this program's 'vertexTexCoord' attribute.
             * @type {Number}
             */
            this.vertexTexCoordLocation = this.attributeLocation(gl, "vertexTexCoord");

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

            /**
             * The WebGL location for this program's 'enableTexture' uniform.
             * @type {WebGLUniformLocation}
             */
            this.textureEnabledLocation = this.uniformLocation(gl, "enableTexture");

            /**
             * The WebGL location for this program's 'textureSampler' uniform.
             * @type {WebGLUniformLocation}
             */
            this.textureUnitLocation = this.uniformLocation(gl, "textureSampler");

            /**
             * The WebGL location for this program's 'texCoordMatrix' uniform.
             * @type {WebGLUniformLocation}
             */
            this.textureMatrixLocation = this.uniformLocation(gl, "texCoordMatrix");

            /**
             * The WebGL location for this program's 'opacity' uniform.
             * @type {WebGLUniformLocation}
             */
            this.opacityLocation = this.uniformLocation(gl, "opacity");
        };

        // Inherit from GpuProgram.
        BasicTextureProgram.prototype = Object.create(GpuProgram.prototype);

        /**
         * Loads the specified matrix as the value of this program's 'mvpMatrix' uniform variable.
         *
         * @param {WebGLRenderingContext} gl The current WebGL context.
         * @param {Matrix} matrix The matrix to load.
         * @throws {ArgumentError} If the specified matrix is null or undefined.
         */
        BasicTextureProgram.prototype.loadModelviewProjection = function (gl, matrix) {
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
        BasicTextureProgram.prototype.loadColor = function (gl, color) {
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
        BasicTextureProgram.prototype.loadPickColor = function (gl, pickColor) {
            GpuProgram.loadUniformPickColor(gl, pickColor, this.colorLocation);
        };

        /**
         * Loads the specified boolean as the value of this program's 'enableTexture' uniform variable.
         * @param {WebGLRenderingContext} gl The current WebGL context.
         * @param {Boolean} enable <code>true</code> to enable texturing, <code>false</code> to disable texturing.
         */
        BasicTextureProgram.prototype.loadTextureEnabled = function (gl, enable) {
            GpuProgram.loadUniformInteger(gl, enable ? 1 : 0, this.textureEnabledLocation);
        };

        /**
         * Loads the specified boolean as the value of this program's 'textureSampler' uniform variable.
         * @param {WebGLRenderingContext} gl The current WebGL context.
         * @param {Number} unit The texture unit.
         */
        BasicTextureProgram.prototype.loadTextureUnit = function (gl, unit) {
            GpuProgram.loadUniformInteger(gl, unit - WebGLRenderingContext.TEXTURE0, this.textureUnitLocation);
        };

        /**
         * Loads the specified matrix as the value of this program's 'texCoordMatrix' uniform variable.
         * @param {WebGLRenderingContext} gl The current WebGL context.
         * @param {Matrix} matrix The texture coordinate matrix.
         */
        BasicTextureProgram.prototype.loadTextureMatrix = function (gl, matrix) {
            GpuProgram.loadUniformMatrix(gl, matrix, this.textureMatrixLocation);
        };

        /**
         * Loads the specified number as the value of this program's 'opacity' uniform variable.
         * @param {WebGLRenderingContext} gl The current WebGL context.
         * @param {Number} opacity The opacity in the range [0, 1].
         */
        BasicTextureProgram.prototype.loadOpacity = function (gl, opacity) {
            GpuProgram.loadUniformFloat(gl, opacity, this.opacityLocation);
        };

        return BasicTextureProgram;
    });