/*
 * Copyright (C) 2014 United States Government as represented by the Administrator of the
 * National Aeronautics and Space Administration. All Rights Reserved.
 */
/**
 * @exports Placemark
 * @version $Id$
 */
define([
        '../error/ArgumentError',
        '../shaders/BasicTextureProgram',
        '../util/Logger',
        '../geom/Matrix',
        '../pick/PickedObject',
        '../pick/PickSupport',
        '../shapes/PlacemarkAttributes',
        '../render/Renderable',
        '../geom/Vec2',
        '../geom/Vec3',
        '../util/WWMath'
    ],
    function (ArgumentError,
              BasicTextureProgram,
              Logger,
              Matrix,
              PickedObject,
              PickSupport,
              PlacemarkAttributes,
              Renderable,
              Vec2,
              Vec3,
              WWMath) {
        "use strict";

        /**
         * Constructs a placemark.
         * @alias Placemark
         * @constructor
         * @augments Renderable
         * @classdesc Represents a Placemark shape. A placemark displays an image, a label and a leader line connecting
         * the image to the placemark's geographical location. All three of these items are optional.
         * <p>
         * Placemarks may be drawn with either an image or as single-color square with a specified size. When the placemark attributes
         * have a valid image path the placemark's image is drawn as a rectangle in the image's original dimensions, scaled
         * by the image scale attribute. Otherwise, the placemark is drawn as a square with width and height equal to the
         * value of the image scale attribute, in pixels.
         * @param {Position} position The placemark's geographic position.
         */
        var Placemark = function (position) {
            if (!position) {
                throw new ArgumentError(
                    Logger.logMessage(Logger.LEVEL_SEVERE, "Placemark", "constructor", "missingPosition"));
            }

            Renderable.call(this);

            /**
             * The placemark's display name and label text.
             * @type {string}
             * @default Placemark
             */
            this.displayName = "Placemark";

            /**
             * The placemark's attributes. If null and this placemark is not highlighted, this placemark is not
             * drawn.
             * @type {PlacemarkAttributes}
             * @default see [PlacemarkAttributes]{@link PlacemarkAttributes)
             */
            this.attributes = new PlacemarkAttributes(null);

            /**
             * The attributes used when this placemark's 'highlighted' flag is <code>true</code>. If null and the
             * highlighted flag is true, this placemark's normal attributes are used. If they, too, are null, this
             * placemark is not drawn.
             * @type {null}
             * @default null
             */
            this.highlightAttributes = null;

            /**
             * Indicates whether this placemark uses its highlight attributes rather than its normal attributes.
             * @type {boolean}
             * @default false
             */
            this.highlighted = false;

            /**
             * Indicates whether this placemark is drawn.
             * @type {boolean}
             * @default true
             */
            this.enabled = true;

            /**
             * This placemark's geographic position.
             * @type {Position}
             */
            this.position = position;

            /**
             * This placemark's altitude mode. May be one of
             * [WorldWind.ABSOLUTE]{@link WorldWind#ABSOLUTE},
             * [WorldWind.RELATIVE_TO_GROUND]{@link WorldWind#RELATIVE_TO_GROUND},
             * or [WorldWind.CLAMP_TO_GROUND]{@link WorldWind#CLAMP_TO_GROUND}.
             * @type WorldWind.ABSOLUTE
             */
            this.altitudeMode = WorldWind.ABSOLUTE;

            /**
             * Indicates the object to return as the owner of this placemark when picked.
             * @type {Object}
             * @default null
             */
            this.pickDelegate = null;

            // Internal use only. Intentionally not documented.
            this.activeAttributes = null;

            // Internal use only. Intentionally not documented.
            this.activeTexture = null;

            // Internal use only. Intentionally not documented.
            this.placePoint = new Vec3(0, 0, 0);

            // Internal use only. Intentionally not documented.
            this.imageTransform = Matrix.fromIdentity();

            // Internal use only. Intentionally not documented.
            this.texCoordMatrix = Matrix.fromIdentity();

            // Internal use only. Intentionally not documented.
            this.imageBounds = null;

            // Internal use only. Intentionally not documented.
            this.layer = null;

            // Internal use only. Intentionally not documented.
            this.depthOffset = -0.003;
        };

        // Internal use only. Intentionally not documented.
        Placemark.point = new Vec3(0, 0, 0); // scratch variable

        // Internal use only. Intentionally not documented.
        Placemark.glPickPoint = new Vec3(0, 0, 0); // scratch variable

        // Internal use only. Intentionally not documented.
        Placemark.matrix = Matrix.fromIdentity(); // scratch variable

        // Internal use only. Intentionally not documented.
        Placemark.pickSupport = new PickSupport(); // scratch variable

        Placemark.prototype = Object.create(Renderable.prototype);

        /**
         * Renders this placemark. This method is typically not called by applications but is called by
         * [RenderableLayer]{@link RenderableLayer} during rendering. When called while the draw context is not in
         * ordered rendering mode it merely enques an ordered renderable for subsequent drawing. When called while
         * the draw context is in ordered rendering mode it draws this placemark.
         * @param {DrawContext} dc The current draw context.
         */
        Placemark.prototype.render = function (dc) {
            if (!this.enabled) {
                return;
            }

            if (dc.orderedRenderingMode) {
                this.drawOrderedPlacemark(dc);

                if (dc.pickingMode) {
                    Placemark.pickSupport.resolvePick(dc);
                }

                return;
            }

            // Else make and enque the ordered renderable.

            var orderedPlacemark = this.makeOrderedRenderable(dc);
            if (!orderedPlacemark) {
                return;
            }

            if (!orderedPlacemark.isVisible(dc)) {
                return;
            }

            orderedPlacemark.layer = dc.currentLayer;

            dc.addOrderedRenderable(orderedPlacemark);
        };

        // Internal. Intentionally not documented.
        Placemark.prototype.makeOrderedRenderable = function (dc) {
            var w, h, s,
                offset;

            this.determineActiveAttributes(dc);
            if (!this.activeAttributes) {
                return null;
            }

            // Compute the placemark's model point and corresponding distance to the eye point.
            dc.terrain.surfacePointForMode(this.position.latitude, this.position.longitude, this.position.altitude,
                this.altitudeMode, this.placePoint);

            this.eyeDistance = dc.navigatorState.eyePoint.distanceTo(this.placePoint);

            // Compute the placemark's screen point in the OpenGL coordinate system of the WorldWindow by projecting its model
            // coordinate point onto the viewport. Apply a depth offset in order to cause the placemark to appear above nearby
            // terrain. When a placemark is displayed near the terrain portions of its geometry are often behind the terrain,
            // yet as a screen element the placemark is expected to be visible. We adjust its depth values rather than moving
            // the placemark itself to avoid obscuring its actual position.
            if (!dc.navigatorState.projectWithDepth(this.placePoint, this.depthOffset, Placemark.point)) {
                return null;
            }

            // Compute the placemark's transform matrix and texture coordinate matrix according to its screen point, image size,
            // image offset and image scale. The image offset is defined with its origin at the image's bottom-left corner and
            // axes that extend up and to the right from the origin point. When the placemark has no active texture the image
            // scale defines the image size and no other scaling is applied.
            if (this.activeTexture) {
                w = this.activeTexture.originalImageWidth;
                h = this.activeTexture.originalImageHeight;
                s = this.activeAttributes.imageScale;
                offset = this.activeAttributes.imageOffset.offsetForSize(w, h);

                this.imageTransform.setTranslation(
                    Placemark.point[0] - offset[0] * s,
                    Placemark.point[1] - offset[1] * s,
                    Placemark.point[2]);

                this.imageTransform.setScale(w * s, h * s, 1);

                this.texCoordMatrix.setToIdentity();
                this.texCoordMatrix.multiplyByTextureTransform(this.activeTexture);
            } else {
                s = this.activeAttributes.imageScale;
                offset = this.activeAttributes.imageOffset.offsetForSize(s, s);

                this.imageTransform.setTranslation(
                    Placemark.point[0] - offset[0],
                    Placemark.point[1] - offset[1],
                    Placemark.point[2]);

                this.imageTransform.setScale(s, s, 1);

                this.texCoordMatrix.setToIdentity();
            }

            this.imageBounds = WWMath.boundingRectForUnitQuad(this.imageTransform);

            return this;
        };

        // Internal. Intentionally not documented.
        Placemark.prototype.determineActiveAttributes = function (dc) {
            if (this.highlighted && this.highlightAttributes) {
                this.activeAttributes = this.highlightAttributes;
            } else {
                this.activeAttributes = this.attributes;
            }

            if (this.activeAttributes && this.activeAttributes.imagePath) {
                this.activeTexture = dc.gpuResourceCache.textureForKey(this.activeAttributes.imagePath);

                if (!this.activeTexture) {
                    dc.gpuResourceCache.retrieveTexture(dc.currentGlContext, this.activeAttributes.imagePath);
                }
            }
        };

        // Internal. Intentionally not documented.
        Placemark.prototype.isVisible = function (dc) {
            if (dc.pickingMode) {
                // Convert the pick point to OpenGL screen coordinates.
                dc.navigatorState.convertPointToViewport(dc.pickPoint, Placemark.glPickPoint);
                return this.imageBounds.containsPoint(Placemark.glPickPoint);
            } else {
                return this.imageBounds.intersects(dc.navigatorState.viewport);
            }
        };

        // Internal. Intentionally not documented.
        Placemark.prototype.drawOrderedPlacemark = function (dc) {
            this.beginDrawing(dc);

            try {
                this.doDrawOrderedPlacemark(dc);
                this.drawBatchOrderedPlacemarks(dc);
            } finally {
                this.endDrawing(dc);
            }
        };

        // Internal. Intentionally not documented.
        Placemark.prototype.drawBatchOrderedPlacemarks = function (dc) {
            // Draw any subsequent placemarks in the ordered renderable queue, removing each from the queue as it's
            // processed. This avoids the overhead of setting up and tearing down OpenGL state for each placemark.

            var or;

            while ((or = dc.peekOrderedRenderable()) && or.doDrawOrderedPlacemark) {
                dc.popOrderedRenderable(); // remove it from the queue

                try {
                    or.doDrawOrderedPlacemark(dc)
                } catch (e) {
                    Logger.logMessage(Logger.LEVEL_WARNING, 'Placemark', 'drawBatchOrderedPlacemarks',
                        "Error occurred while rendering placemark using batching: " + e.message);
                }
                // Keep going. Render the rest of the ordered renderables.
            }
        };

        // Internal. Intentionally not documented.
        Placemark.prototype.beginDrawing = function (dc) {
            var gl = dc.currentGlContext,
                program;

            dc.findAndBindProgram(gl, BasicTextureProgram);

            // Configure GL to use the draw context's unit quad VBO for both model coordinates and texture coordinates.
            program = dc.currentProgram;
            gl.bindBuffer(WebGLRenderingContext.ARRAY_BUFFER, dc.unitQuadBuffer());
            gl.vertexAttribPointer(program.vertexPointLocation, 2, WebGLRenderingContext.FLOAT, false, 0, 0);
            gl.vertexAttribPointer(program.vertexTexCoordLocation, 2, WebGLRenderingContext.FLOAT, false, 0, 0);
            gl.enableVertexAttribArray(program.vertexPointLocation);
            gl.enableVertexAttribArray(program.vertexTexCoordLocation);

            // Tell the program which texture unit to use.
            program.loadTextureUnit(gl, WebGLRenderingContext.TEXTURE0);

            // Turn off texturing if in picking mode.
            if (dc.pickingMode) {
                program.loadTextureEnabled(false);
            }

            // Suppress depth-buffer writes.
            gl.depthMask(false);

            // The currentTexture field is used to avoid re-specifying textures unnecessarily. Clear it to start.
            Placemark.currentTexture = null;
        };

        // Internal. Intentionally not documented.
        Placemark.prototype.endDrawing = function (dc) {
            var gl = dc.currentGlContext,
                program = dc.currentProgram;

            // Clear the vertex attribute state.
            gl.disableVertexAttribArray(program.vertexPointLocation);
            gl.disableVertexAttribArray(program.vertexTexCoordLocation);

            // Clear GL bindings.
            dc.bindProgram(gl, null);
            gl.bindBuffer(WebGLRenderingContext.ARRAY_BUFFER, null);
            gl.bindTexture(WebGLRenderingContext.TEXTURE_2D, null);
            gl.depthMask(true);

            // Avoid keeping a dangling reference to the current texture.
            Placemark.currentTexture = null;
        };

        // Internal. Intentionally not documented.
        Placemark.prototype.doDrawOrderedPlacemark = function (dc) {
            var gl = dc.currentGlContext,
                program = dc.currentProgram,
                color,
                textureBound;

            // Compute and specify the MVP matrix.
            Placemark.matrix.setToMatrix(dc.screenProjection);
            Placemark.matrix.multiplyMatrix(this.imageTransform);
            program.loadModelviewProjection(gl, Placemark.matrix);
            program.loadTextureMatrix(gl, this.texCoordMatrix);

            // Set the pick color for picking or the color, opacity and texture if not picking.
            if (dc.pickEnabled) {
                color = dc.uniquePickColor();
                Placemark.pickSupport.addPickableObject(this.createPickedObject(dc, color));
                program.loadPickColor(gl, color);
            } else {
                program.loadColor(gl, this.activeAttributes.imageColor);
                program.loadOpacity(gl, this.layer.opacity);

                if (!this.activeTexture) {
                    program.loadTextureEnabled(gl, false); // TODO: is this clause necessary?
                } else if (Placemark.currentTexture != this.activeTexture) { // avoid unnecessary texture state changes
                    textureBound = this.activeTexture.bind(dc); // returns false if active texture is null or cannot be bound
                    program.loadTextureEnabled(gl, textureBound);
                    Placemark.currentTexture = this.activeTexture;
                }
            }

            // Draw the placemark's quad.
            gl.drawArrays(WebGLRenderingContext.TRIANGLE_STRIP, 0, 4);
        };

        // Internal. Intentionally not documented.
        Placemark.prototype.createPickedObject = function (dc, colorCode) {
            return new PickedObject(colorCode, dc.pickPoint, this.pickDelegate ? this.pickDelegate : this,
                this.position, this.layer);
        };

        return Placemark;
    });