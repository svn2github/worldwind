/*
 * Copyright (C) 2014 United States Government as represented by the Administrator of the
 * National Aeronautics and Space Administration. All Rights Reserved.
 */
/**
 * @exports UserFacingText
 * @version $Id$
 */
define([
        '../error/ArgumentError',
        '../render/DrawContext',
        '../util/Logger',
        '../geom/Matrix',
        '../error/NotYetImplementedError',
        '../render/renderable',
        '../shaders/UserFacingTextProgram',
        '../geom/Vec3'
    ],
    function (ArgumentError,
              DrawContext,
              Logger,
              Matrix,
              NotYetImplementedError,
              Renderable,
              UserFacingTextProgram,
              Vec3) {
        "use strict";

        /**
         * Constructs user facing text that enables text to be placed at a geographical position.
         * @param {Position} position The position for the text.
         * @param {string} text The text to be displayed.
         * @alias UserFacingText
         * @constructor
         * @augments {Renderable}
         * @classdesc Provides a mechanism for placing a text at a geographical position.
         */
        var UserFacingText = function(text, position) {
            if (!text) {
                throw new ArgumentError(Logger.logMessage(Logger.LEVEL_SEVERE, "UserFacingText", "constructor",
                    "missingText"));
            }
            if (!position) {
                throw new ArgumentError(Logger.logMessage(Logger.LEVEL_SEVERE, "UserFacingText", "constructor",
                    "missingPosition"));
            }

            Renderable.call(this);

            this.text = text;
            this.position = position;

            /**
             * The size of a texture map in pixels.
             * @type {number}
             */
            this.size = -1;

            /**
             * The width of the text in pixels.
             * @type {number}
             */
            this.width = -1;

            /**
             * The height of the text in pixels.
             * @type {number}
             */
            this.height = -1;

            /**
             * Cache keys for retrieving previously constructed VBOs.
             * @type {string}
             */
            this.geometryVboCacheKey = "text_geometry";
            this.texCoordVboCacheKey = "text_texCoord";
            this.indicesVboCacheKey = "text_indices";
    
            /**
             * The number in indices in the mesh to draw the text.
             * @type {number}
             */
            this.numIndices = 4;

            /**
             * The position of the center of the text in normalized screen units.
             * @type {number}
             */
            this.x = 0;
            this.y = 0;

            /**
             * The texture map created to display the text.
             * @type {Texture}
             */
            this.texture = null;
    
            this.isVisible = true;
    
            // Scratch values to avoid constantly recreating these matrices.
            this.mvpMatrix = Matrix.fromIdentity();
            this.texSamplerMatrix = Matrix.fromIdentity();
            this.vec3Scratch = new Vec3(0, 0, 0);
        };
    
        UserFacingText.prototype.render = function(dc) {
            if (!this.enabled) {
                return;
            }

            var gl = dc.currentGlContext;
    
            this.updatePosition(dc);
    
            if (!this.isVisible) {
                return;
            }
    
            this.applyState(dc);
    
            gl.drawElements(
                WebGLRenderingContext.TRIANGLE_STRIP,
                this.numIndices,
                WebGLRenderingContext.UNSIGNED_SHORT,
                0);
    
            gl.bindBuffer(WebGLRenderingContext.ARRAY_BUFFER, null);
            gl.bindBuffer(WebGLRenderingContext.ELEMENT_ARRAY_BUFFER, null);
    
            dc.bindProgram(gl, null);
        };
    
        UserFacingText.prototype.applyState = function (dc) {
            var gl = dc.currentGlContext,
                program = dc.findAndBindProgram(gl, UserFacingTextProgram);

            if (!this.texture) {
                this.texture = this.createTexture(dc);
            }
            gl.bindTexture(WebGLRenderingContext.TEXTURE_2D, this.texture);
    
            program.loadTexSampler(gl, WebGLRenderingContext.TEXTURE0);
    
            var vertexPointLocation = program.attributeLocation(gl, "vertexPoint");
            this.bindGeometryVbo(dc);
            gl.vertexAttribPointer(vertexPointLocation, 3, WebGLRenderingContext.FLOAT, false, 0, 0);
            gl.enableVertexAttribArray(vertexPointLocation);
    
            var vertexTexCoordLocation = program.attributeLocation(gl, "vertexTexCoord");
            this.bindTextureVbo(dc);
            gl.vertexAttribPointer(vertexTexCoordLocation, 2, WebGLRenderingContext.FLOAT, false, 0, 0);
            gl.enableVertexAttribArray(vertexTexCoordLocation);

            this.bindIndicesVbo(dc);

            program.loadModelviewProjection(gl, this.mvpMatrix);
            program.loadTexSamplerMatrix(gl, this.texSamplerMatrix);
    
            gl.disable(WebGLRenderingContext.CULL_FACE);
            gl.disable(WebGLRenderingContext.DEPTH_TEST);
        };
    
        UserFacingText.prototype.createTexture = function(dc) {
            var gl = dc.currentGlContext,
                canvas2D = dc.canvas2D,
                ctx2D = dc.ctx2D;
    
            this.height = 32;
            var fontString = this.height.toString() + "px Sans-Serif";
    
            ctx2D.font = fontString;
    
            this.width = ctx2D.measureText(this.text).width;
            this.size = this.getPowerOfTwo(this.width);
    
            canvas2D.width = this.size;
            canvas2D.height = this.size;
    
            ctx2D.font = fontString;
            ctx2D.fillStyle = "#ffffff";
            ctx2D.strokeStyle = "#000000";
            ctx2D.strokeWidth = 8.0;
            ctx2D.textAlign = "center";
            ctx2D.textBaseline = "middle";
    
            // Draw white text with a black outline to make it visible on any field.
            // TODO: I'm not seeing any effect from the stroke.
            ctx2D.fontWeight = 900;
            ctx2D.strokeText(this.text, this.size / 2, this.size / 2);
    
            ctx2D.fontWeight = 500;
            ctx2D.fillText(this.text, this.size / 2, this.size / 2);
    
            gl.pixelStorei(WebGLRenderingContext.UNPACK_FLIP_Y_WEBGL, true);
    
            var texture = gl.createTexture();
            gl.bindTexture(WebGLRenderingContext.TEXTURE_2D, texture);
            gl.texImage2D(WebGLRenderingContext.TEXTURE_2D, 0, WebGLRenderingContext.RGBA, WebGLRenderingContext.RGBA, WebGLRenderingContext.UNSIGNED_BYTE, canvas2D);
            gl.texParameteri(WebGLRenderingContext.TEXTURE_2D, WebGLRenderingContext.TEXTURE_MAG_FILTER, WebGLRenderingContext.LINEAR);
            gl.texParameteri(WebGLRenderingContext.TEXTURE_2D, WebGLRenderingContext.TEXTURE_MIN_FILTER, WebGLRenderingContext.LINEAR_MIPMAP_NEAREST);
            gl.generateMipmap(WebGLRenderingContext.TEXTURE_2D);
            gl.bindTexture(WebGLRenderingContext.TEXTURE_2D, null);
    
            gl.pixelStorei(WebGLRenderingContext.UNPACK_FLIP_Y_WEBGL, false);
    
            return texture;
        };
    
        UserFacingText.prototype.bindGeometryVbo = function(dc) {
            var gl = dc.currentGlContext,
                gpuResourceCache = dc.gpuResourceCache,
                vbo = gpuResourceCache.resourceForKey(this.geometryVboCacheKey),
                points;
    
            if (!vbo) {
                points = new Float32Array([
                    0.0, 0.0, 0.0,
                    1.0, 0.0, 0.0,
                    0.0, 1.0, 0.0,
                    1.0, 1.0, 0.0
                ]);
                vbo = gl.createBuffer();
                gl.bindBuffer(WebGLRenderingContext.ARRAY_BUFFER, vbo);
                gl.bufferData(WebGLRenderingContext.ARRAY_BUFFER, points, WebGLRenderingContext.STATIC_DRAW);
                dc.frameStatistics.incrementVboLoadCount(1);
                gpuResourceCache.putResource(gl, this.geometryVboCacheKey, vbo, WorldWind.GPU_BUFFER, points.length * 4);
            }
            else {
                gl.bindBuffer(WebGLRenderingContext.ARRAY_BUFFER, vbo);
            }
        };
    
        UserFacingText.prototype.bindTextureVbo = function(dc) {
            var gl = dc.currentGlContext,
                gpuResourceCache = dc.gpuResourceCache,
                vbo = gpuResourceCache.resourceForKey(this.texCoordVboCacheKey),
                texCoords;
    
            if (!vbo) {
                texCoords = new Float32Array([
                    0.0, 0.0,
                    1.0, 0.0,
                    0.0, 1.0,
                    1.0, 1.0
                ]);
                vbo = gl.createBuffer();
                gl.bindBuffer(WebGLRenderingContext.ARRAY_BUFFER, vbo);
                gl.bufferData(WebGLRenderingContext.ARRAY_BUFFER, texCoords, WebGLRenderingContext.STATIC_DRAW);
                dc.frameStatistics.incrementVboLoadCount(1);
                gpuResourceCache.putResource(gl, this.texCoordVboCacheKey, vbo, WorldWind.GPU_BUFFER, texCoords.length * 4);
            }
            else {
                gl.bindBuffer(WebGLRenderingContext.ARRAY_BUFFER, vbo);
            }
        };
    
        UserFacingText.prototype.bindIndicesVbo = function(dc) {
            var gl = dc.currentGlContext,
                gpuResourceCache = dc.gpuResourceCache,
                vbo = gpuResourceCache.resourceForKey(this.indicesVboCacheKey),
                indices;
    
            if (!vbo) {
                indices = new Uint16Array([
                    0, 1, 2, 3
                ]);
                vbo = gl.createBuffer();
                gl.bindBuffer(WebGLRenderingContext.ELEMENT_ARRAY_BUFFER, vbo);
                gl.bufferData(WebGLRenderingContext.ELEMENT_ARRAY_BUFFER, indices, WebGLRenderingContext.STATIC_DRAW);
                dc.frameStatistics.incrementVboLoadCount(1);
                gpuResourceCache.putResource(gl, this.indicesVboCacheKey, vbo, WorldWind.GPU_BUFFER, indices.length * 2);
            }
            else {
                gl.bindBuffer(WebGLRenderingContext.ELEMENT_ARRAY_BUFFER, vbo);
            }
        };
    
        UserFacingText.prototype.updatePosition = function(dc) {
            this.vec3Scratch = dc.globe.computePointFromPosition(this.position.latitude,
                this.position.longitude,
                this.position.altitude,
                this.vec3Scratch);
    
            // Compute normalized screen position.
            this.vec3Scratch.multiplyByMatrix(dc.navigatorState.modelviewProjection);
    
            // Update visibility based on normalized screen position.
            this.isVisible = (Math.abs(this.vec3Scratch[0]) <= 1) &&
                (Math.abs(this.vec3Scratch[1]) <= 1) &&
                this.vec3Scratch[2] > 0 &&
                this.vec3Scratch[2] < 1;
    
            this.x = this.vec3Scratch[0];
            this.y = this.vec3Scratch[1];
    
            // Update MVP transformation to correctly map a unit square.
            var viewport = dc.navigatorState.viewport,
                xScale = this.size / viewport.width,
                yScale = this.size / viewport.height,
                xOffset = this.x - 0.5 * this.size / viewport.width,
                yOffset = this.y - 0.5 * this.size / viewport.height;
            this.mvpMatrix.set(
                xScale, 0, 0, xOffset,
                0, yScale, 0, yOffset,
                0, 0, 1, 0,
                0, 0, 0, 1
            );
        };

        UserFacingText.prototype.getPowerOfTwo = function(value) {
            var pow = 1;
            while (pow < value) {
                pow *= 2;
            }
            return pow;
        };

        return UserFacingText;
});