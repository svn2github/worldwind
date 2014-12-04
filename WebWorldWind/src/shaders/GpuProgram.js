/*
 * Copyright (C) 2014 United States Government as represented by the Administrator of the
 * National Aeronautics and Space Administration. All Rights Reserved.
 */
/**
 * @exports GpuProgram
 * @version $Id$
 */
define([
        '../error/ArgumentError',
        '../util/Color',
        '../util/Logger',
        '../error/NotYetImplementedError'
    ],
    function (ArgumentError,
              Color,
              Logger,
              NotYetImplementedError) {
        "use strict";

        /**
         * Constructs a GPU program with specified source code for vertex and fragment shaders.
         * <p>
         * This constructor creates WebGL shaders for the specified shader sources and attaches them to a new GLSL program. The
         * method compiles the shaders and links the program if compilation is successful. Use the [bind]{@link GpuProgram#bind}
         * method to make the program current during rendering.
         *
         * @alias GpuProgram
         * @constructor
         * @classdesc
         * Represents an OpenGL shading language (GLSL) shader program and provides methods for identifying and accessing shader
         * variables. Shader programs are created by instances of this class and made current when the instance's bind
         * method is invoked.
         * <p>
         * This is an abstract class and not intended to be created directly.
         *
         * @param {WebGLRenderingContext} gl The current WebGL context.
         * @param {String} vertexShaderSource The source code for the vertex shader.
         * @param {String} fragmentShaderSource The source code for the fragment shader.
         * @throws {ArgumentError} If either source is null or undefined, the shaders cannot be compiled, or linking of
         * the compiled shaders into a program fails.
         */
        var GpuProgram = function (gl, vertexShaderSource, fragmentShaderSource) {
            if (!vertexShaderSource || !fragmentShaderSource) {
                throw new ArgumentError(Logger.logMessage(Logger.LEVEL_SEVERE, "GpuProgram", "constructor",
                    "The specified shader source is null or undefined"));
            }

            // TODO
            throw new NotYetImplementedError(
                Logger.logMessage(Logger.LEVEL_SEVERE, "GpuProgram", "constructor", "notYetImplemented"));
        };

        /**
         * Makes this program the current program in the specified WebGL context.
         *
         * @param {WebGLRenderingContext} gl The current WebGL context.
         */
        GpuProgram.prototype.bind = function (gl) {
            // TODO
            throw new NotYetImplementedError(
                Logger.logMessage(Logger.LEVEL_SEVERE, "GpuProgram", "bind", "notYetImplemented"));
        };

        /**
         * Releases this GPU program's WebGL program and associated shaders. Upon return this GPU program's WebGL
         * program ID is 0 as is that of the associated shaders.
         *
         * @param {WebGLRenderingContext} gl The current WebGL context.
         */
        GpuProgram.prototype.dispose = function (gl) {
            // TODO
            throw new NotYetImplementedError(
                Logger.logMessage(Logger.LEVEL_SEVERE, "GpuProgram", "dispose", "notYetImplemented"));
        };

        /**
         * Returns the GLSL attribute location of a specified attribute name.
         *
         * @param {WebGLRenderingContext} gl The current WebGL context.
         * @param {String} attributeName The name of the attribute whose location is determined.
         * @returns {Number} The WebGL attribute location of the specified attribute, or -1 if the attribute is not
         * found.
         * @throws {ArgumentError} If the specified attribute name is null, empty or undefined.
         */
        GpuProgram.prototype.attributeLocation = function (gl, attributeName) {
            if (!attributeName || attributeName.length == 0) {
                throw new ArgumentError(Logger.logMessage(Logger.LEVEL_SEVERE, "GpuProgram", "attributeLocation",
                    "The specified attribute name is null, undefined or empty"));
            }

            // TODO
            throw new NotYetImplementedError(
                Logger.logMessage(Logger.LEVEL_SEVERE, "GpuProgram", "attributeLocation", "notYetImplemented"));

            return -1;
        };

        /**
         * Returns the GLSL uniform location of a specified uniform name.
         *
         * @param {WebGLRenderingContext} gl The current WebGL context.
         * @param {String} uniformName The name of the uniform variable whose location is determined.
         * @returns {Number} The WebGL uniform location of the specified uniform variable, or -1 if the uniform is not
         * found.
         * @throws {ArgumentError} If the specified uniform name is null, empty or undefined.
         */
        GpuProgram.prototype.uniformLocation = function (gl, uniformName) {
            if (!uniformName || uniformName.length == 0) {
                throw new ArgumentError(Logger.logMessage(Logger.LEVEL_SEVERE, "GpuProgram", "uniformLocation",
                    "The specified uniform name is null, undefined or empty"));
            }

            // TODO
            throw new NotYetImplementedError(
                Logger.logMessage(Logger.LEVEL_SEVERE, "GpuProgram", "uniformLocation", "notYetImplemented"));

            return -1;
        };

        /**
         * Loads a specified matrix as the value of a GLSL 4x4 matrix uniform variable with the specified location.
         * <p>
         * This functions converts the matrix into column-major order prior to loading its components into the GLSL
         * uniform variable, but does not modify the specified matrix.
         *
         *
         * @param {WebGLRenderingContext} gl The current WebGL context.
         * @param {Matrix} matrix The matrix to load.
         * @param {Number} location The location of the uniform variable in the currently bound GLSL program.
         * @throws {ArgumentError} If the specified matrix is null or undefined.
         */
        GpuProgram.prototype.loadUniformMatrix = function (gl, matrix, location) {
            if (!matrix) {
                throw new ArgumentError(Logger.logMessage(Logger.LEVEL_SEVERE, "GpuProgram", "loadUniformMatrix",
                    "missingMatrix"));
            }

            // TODO
            throw new NotYetImplementedError(
                Logger.logMessage(Logger.LEVEL_SEVERE, "GpuProgram", "loadUniformMatrix", "notYetImplemented"));
        };

        /**
         * Loads a specified color as the value of a GLSL vec4 uniform variable with the specified location.
         * <p>
         * This function multiplies the red, green and blue components by the alpha component prior to loading the color
         * in the GLSL uniform variable, but does not modify the specified color.
         *
         * @param {WebGLRenderingContext} gl The current WebGL context.
         * @param {Color} color The color to load.
         * @param {Number} location The location of the uniform variable in the currently bound GLSL program.
         * @throws {ArgumentError} If the specified color is null or undefined.
         */
        GpuProgram.prototype.loadUniformColor = function (gl, color, location) {
            // TODO
            throw new NotYetImplementedError(
                Logger.logMessage(Logger.LEVEL_SEVERE, "GpuProgram", "loadUniformColor", "notYetImplemented"));
        };

        /**
         * Loads a specified floating-point value to a specified uniform location.
         *
         * @param {WebGLRenderingContext} gl The current WebGL context.
         * @param {Number} value The value to load.
         * @param {Number} location The uniform location to store the value to.
         */
        GpuProgram.prototype.loadUniformFloat = function (gl, value, location) {
            // TODO
            throw new NotYetImplementedError(
                Logger.logMessage(Logger.LEVEL_SEVERE, "GpuProgram", "loadUniformFloat", "notYetImplemented"));
        };

        /**
         * Links a specified GLSL program.
         *
         * @param {Number} program The WebGL program ID of the program to link.
         * @returns {Boolean} <code>true</code> if linking was successful, otherwise <code>false</code>.
         */
        GpuProgram.prototype.link = function (program) {
            // TODO
            throw new NotYetImplementedError(
                Logger.logMessage(Logger.LEVEL_SEVERE, "GpuProgram", "link", "notYetImplemented"));

            return false;
        };

        return GpuProgram;
    });