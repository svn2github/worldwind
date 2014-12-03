/*
 * Copyright (C) 2014 United States Government as represented by the Administrator of the
 * National Aeronautics and Space Administration. All Rights Reserved.
 */
/**
 * @exports GpuProgram
 * @version $Id$
 */
define([
        'src/error/ArgumentError',
        'src/util/Logger'
    ],
    function (ArgumentError,
              Logger) {
        "use strict";

        /**
         * Constructs a GPU program with specified source code for vertex and fragment shaders.
         * <p>
         * An WebGL context must be current when this method is called.
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
         *
         * @param {String} vertexShaderSource The source code for the vertex shader.
         * @param {String} fragmentShaderSource The source code for the fragment shader.
         * @throws {ArgumentError} If either source is null or undefined, the shaders cannot be compiled, or linking of
         * the compiled shaders into a program fails.
         */
        var GpuProgram = function (vertexShaderSource, fragmentShaderSource) {
            if (!vertexShaderSource || !fragmentShaderSource) {
                throw new ArgumentError(Logger.logMessage(Logger.LEVEL_SEVERE, "GpuProgram", "constructor",
                    "The specified shader source is null or undefined"));
            }

            // TODO
        };

        /**
         * Makes this program the current program in the current WebGL context. An WebGL context must be current when
         * this method is called.
         */
        GpuProgram.prototype.bind = function () {
            // TODO
        };

        /**
         * Releases this GPU program's WebGL program and associated shaders. Upon return this GPU program's WebGL
         * program ID is 0 as is that of the associated shaders.
         */
        GpuProgram.prototype.dispose = function () {
            // TODO
        };

        /**
         * Returns the GLSL attribute location of a specified attribute name.
         * @param {String} attributeName The name of the attribute whose location is determined.
         * @returns {Number} The WebGL attribute location of the specified attribute, or -1 if the attribute is not
         * found.
         * @throws {ArgumentError} If the specified attribute name is null, empty or undefined.
         */
        GpuProgram.prototype.attributeLocation = function (attributeName) {
            if (!attributeName || attributeName.length == 0) {
                throw new ArgumentError(Logger.logMessage(Logger.LEVEL_SEVERE, "GpuProgram", "attributeLocation",
                    "The specified attribute name is null, undefined or empty"));
            }

            // TODO

            return -1;
        };

        /**
         * Returns the GLSL uniform location of a specified uniform name.
         * @param {String} uniformName The name of the uniform variable whose location is determined.
         * @returns {Number} The WebGL uniform location of the specified uniform variable, or -1 if the uniform is not
         * found.
         * @throws {ArgumentError} If the specified uniform name is null, empty or undefined.
         */
        GpuProgram.prototype.uniformLocation = function (uniformName) {
            if (!uniformName || uniformName.length == 0) {
                throw new ArgumentError(Logger.logMessage(Logger.LEVEL_SEVERE, "GpuProgram", "uniformLocation",
                    "The specified uniform name is null, undefined or empty"));
            }

            // TODO

            return -1;
        };

        /**
         * Loads a specified matrix as the value of a GLSL 4x4 matrix uniform variable with the specified location index.
         * <p>
         * A WebGL context must be current when this method is called, and an WebGL program must be bound. The result of this
         * method is undefined if there is no current WebGL context or no current program.
         * <p>
         * This converts the matrix into column-major order prior to loading its components into the GLSL uniform variable, but
         * does not modify the specified matrix.
         *
         * @param {Matrix} matrix The matrix to load.
         * @param {Number} location The location of the uniform variable in the currently bound GLSL program.
         * @throws {ArgumentError} If the specified matrix is null or undefined.
         */
        GpuProgram.prototype.loadUniformMatrix = function (matrix, location) {
            if (!matrix) {
                throw new ArgumentError(Logger.logMessage(Logger.LEVEL_SEVERE, "GpuProgram", "loadUniformMatrix",
                    "missingMatrix"));
            }

            // TODO
        };

        /**
         * Loads a specified color as the value of a GLSL vec4 uniform variable with the specified location.
         * <p>
         * A WebGL context must be current when this method is called, and a WebGL program must be bound. The result of this
         * method is undefined if there is no current WebGL context or no current program.
         * <p>
         * This function multiplies the red, green and blue components by the alpha component prior to loading the color
         * in the GLSL uniform variable, but does not modify the specified color.
         *
         * @param {Color} color The color to load.
         * @param {Number} location The location of the uniform variable in the currently bound GLSL program.
         * @throws {ArgumentError} If the specified color is null or undefined.
         */
        GpuProgram.prototype.loadUniformColor = function (color, location) {
            // TODO
        };

        /**
         * Loads a specified floating-point value to a specified uniform location.
         * <p>
         * A WebGL context must be current when this method is called, and a WebGL program must be bound. The result of this
         * method is undefined if there is no current WebGL context or no current program.
         *
         * @param {Number} value The value to load.
         * @param {Number} location The uniform location to store the value to.
         */
        GpuProgram.prototype.loadUniformFloat = function (value, location) {
            // TODO
        };

        /**
         * Links a specified GLSL program. A WebGL context must be current when this function is called. This function
         * is not meant to be invoked by applications. It is invoked internally as needed.
         * @param {Number} program The WebGL program ID of the program to link.
         * @returns {Boolean} <code>true</code> if linking was successful, otherwise <code>false</code>.
         */
        GpuProgram.prototype.link = function (program) {
            // TODO

            return false;
        };

        return GpuProgram;
    });