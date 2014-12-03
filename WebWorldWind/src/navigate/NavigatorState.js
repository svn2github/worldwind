/*
 * Copyright (C) 2014 United States Government as represented by the Administrator of the
 * National Aeronautics and Space Administration. All Rights Reserved.
 */
/**
 * @exports NavigatorState
 * @version $Id$
 */
define([
        'src/error/ArgumentError',
        'src/geom/Frustum',
        'src/util/Logger',
        'src/geom/Matrix',
        'src/geom/Rectangle',
        'src/geom/Vec2',
        'src/geom/Vec3'
    ],
    function (ArgumentError,
              Frustum,
              Logger,
              Matrix,
              Rectangle,
              Vec2,
              Vec3) {
        "use strict";

        /**
         * Constructs navigator state. This constructor is meant to be called by navigators when their current state
         * is requested.
         * @alias NavigatorState
         * @constructor
         * @classdesc Represents the state of a navigator.
         * <p>
         * Properties of NavigatorState objects are meant to be
         * read-only because they are values captured from a {@link Navigator} upon request. Setting the properties
         * on NavigatorState instances has no effect on the Navigator from which they came.
         */
        var NavigatorState = function () {

            /**
             * The navigator's Cartesian eye point relative to the globe's center.
             * @type {Vec3}
             */
            this.eyePoint = null;

            /**
             * The navigator's viewport, in screen coordinates.
             * @type {Rectangle}
             */
            this.viewport = null;

            /**
             * The navigator's model-view matrix.
             * @type {Matrix}
             */
            this.modelview = null;

            /**
             * The navigator's projection matrix.
             * @type {Matrix}
             */
            this.projection = null;

            /**
             * The concatenation of the navigator's model-view and projection matrices.
             * @type {Matrix}
             */
            this.modelviewProjection = null;

            /**
             * The navigator's forward ray in model coordinates. The forward ray originates at the eye point and
             * and is directed along the eye's forward vector. This vector is effectively going into the screen from
             * the screen's center.
             * @type {Vec3}
             */
            this.forwardRay = null;

            /**
             * The navigator's view frustum in model coordinates.
             * The frustum originates at the eyePoint and extends outward along the forward vector. The navigator's near distance and
             * far distance identify the minimum and maximum distance, respectively, at which an object in the scene is visible.
             * @type {Frustum}
             */
            this.frustumInModelCoordinates = null;

            /**
             * Indicates the number of degrees clockwise from north to which the view is directed.
             * @type {Number}
             */
            this.heading = 0;

            /**
             * The number of degrees the globe is tilted relative to its surface being parallel to the screen. Values are
             * typically in the range 0 to 90 but may vary from that depending on the navigator in use.
             * @type {Number}
             */
            this.tilt = 0;
        };

        /**
         * Transforms the specified modelPoint from model coordinates to OpenGL screen coordinates.
         * <p>
         * The resultant screen point is in the OpenGL screen coordinate system of the WorldWindView, with its origin in the
         * bottom-left corner and axes that extend up and to the right from the origin point.
         * <p>
         * This function stores the transformed point in the result parameter, and returns <code>true</code> or <code>false</code>
         * to indicate whether or not the
         * transformation is successful. This returns <code>false</code> if this navigator state's modelview or projection matrices are
         * malformed, or if the specified model point is clipped by the near clipping plane or the far clipping plane.
         * <p>
         * This performs the same computations as the OpenGL vertex transformation pipeline, but is not guaranteed to result in
         * the exact same floating point values.
         *
         * @param {Vec3} modelPoint The model coordinate point to project.
         * @param {Vec3} result A pre-allocated vector in which to return the projected point.
         * @returns {boolean} <code>true</code> If the transformation is successful, otherwise <code>false</code>.
         * @throws {ArgumentError} If either the specified point or result argument is null or undefined.
         */
        NavigatorState.prototype.project = function (modelPoint, result) {
            if (!modelPoint) {
                throw new ArgumentError(Logger.logMessage(Logger.LEVEL_SEVERE, "NavigatorState", "project",
                    "missingPoint"));
            }

            if (!result) {
                throw new ArgumentError(Logger.logMessage(Logger.LEVEL_SEVERE, "NavigatorState", "project",
                    "missingResult"));
            }

            // TODO

            return false;
        };
        /**
         * Transforms the specified modelPoint from model coordinates to OpenGL screen coordinates, applying an offset to the
         * modelPoint's projected depth value.
         * <p>
         * The resultant screen point is in the OpenGL screen coordinate system of the WorldWindView, with its origin in the
         * bottom-left corner and axes that extend up and to the right from the origin point.
         * <p>
         * This stores the transformed point in the screenPoint parameter, and returns <code>true</code> or <code>false</code>
         * to indicate whether or not the
         * transformation is successful. This returns <code>false</code> if this navigator state's modelview or projection matrices are
         * malformed, or if the modelPoint is clipped by the near clipping plane or the far clipping plane, ignoring the depth
         * offset.
         * <p>
         * The depth offset may be any real number and is typically used to move the screenPoint slightly closer to the user's
         * eye in order to give it visual priority over nearby points. An offset of zero has no effect. An offset less than zero
         * brings the screenPoint closer to the eye, while an offset greater than zero pushes the screenPoint away from the eye.
         * <p>
         * This performs the same computations as the OpenGL vertex transformation pipeline, but is not guaranteed to result in
         * the exact same floating point values. Applying a non-zero depth offset has no effect on on whether the modelPoint is
         * clipped by this method or by OpenGL. Clipping is performed on the original modelPoint ignoring the depth offset, and
         * the final depth value after applying the offset is clamped to the range [0,1].
         *
         * @param {Vec3} modelPoint The model coordinate point to project.
         * @param {Number} depthOffset The amount of offset to apply.
         * @param {Vec3} result A pre-allocated vector in which to return the projected point.
         * @returns {boolean} <code>true</code> If the transformation is successful, otherwise <code>false</code>.
         * @throws {ArgumentError} If either the specified point or result argument is null or undefined.
         */
        NavigatorState.prototype.projectWithDepth = function (modelPoint, depthOffset, result) {
            if (!modelPoint) {
                throw new ArgumentError(Logger.logMessage(Logger.LEVEL_SEVERE, "NavigatorState", "projectWithDepth",
                    "missingPoint"));
            }

            if (!result) {
                throw new ArgumentError(Logger.logMessage(Logger.LEVEL_SEVERE, "NavigatorState", "projectWithDepth",
                    "missingResult"));
            }

            // TODO

            return false;
        };

        /**
         * Transforms the specified screen point from OpenGL screen coordinates to model coordinates.
         *
         * The screen point is understood to be in the OpenGL screen coordinate system of the WorldWindView, with its origin in
         * the bottom-left corner and axes that extend up and to the right from the origin point.
         *
         * This stores the transformed point in the modelPoint parameter, and returns <code>true</code> or <code>false</code>
         * to indicate whether the
         * transformation is successful. This returns <code>false</code> if this navigator state's modelview or projection matrices are
         * malformed, or if the screenPoint is clipped by the near clipping plane or the far clipping plane.
         *
         * This performs the same computations as the OpenGL vertex transformation pipeline, but is not guaranteed to result in
         * the exact same floating point values.
         *
         * @param {Vec3} screenPoint The screen coordinate point to un-project.
         * @param {Vec3} result A pre-allocated vector in which to return the unprojected point.
         * @returns {boolean} <code>true</code> If the transformation is successful, otherwise <code>false</code>.
         * @throws {ArgumentError} If either the specified point or result argument is null or undefined.
         */
        NavigatorState.prototype.unProject = function (screenPoint, result) {
            if (!screenPoint) {
                throw new ArgumentError(Logger.logMessage(Logger.LEVEL_SEVERE, "NavigatorState", "unProject",
                    "missingPoint"));
            }

            if (!result) {
                throw new ArgumentError(Logger.logMessage(Logger.LEVEL_SEVERE, "NavigatorState", "unProject",
                    "missingResult"));
            }
            // TODO

            return false;
        };

        /**
         * Converts an OpenGL screen point to window coordinates.
         *
         * The specified point is understood to be in the OpenGL screen coordinate of the {@link WorldWindow},
         * with its origin in the
         * bottom-left corner and axes that extend up and to the right from the origin point.
         *
         * The returned point is in the window coordinate system of the {@link WorldWindow}, with its origin in the
         * top-left corner and axes that extend down and to the right from the origin point.
         *
         * @param {Vec2} screenPoint The screen point to convert.
         * @param {Vec2} result A pre-allocated {@link Vec2} in which to return the computed point.
         * @returns {Vec2} The specified result parameter set to the computed point.
         * @throws {ArgumentError} If either argument is null or undefined.
         */
        NavigatorState.prototype.convertPointToWindow = function (screenPoint, result) {
            if (!screenPoint) {
                throw new ArgumentError(Logger.logMessage(Logger.LEVEL_SEVERE, "NavigatorState", "convertPointToWindow",
                    "missingPoint"));
            }

            if (!result) {
                throw new ArgumentError(Logger.logMessage(Logger.LEVEL_SEVERE, "NavigatorState", "convertPointToWindow",
                    "missingResult"));
            }
            // TODO

            return result;
        };

        /**
         * Converts a window-coordinate point to OpenGL screen coordinates.
         *
         * The specified point is understood to be in the window coordinate system of the {@link WorldWindow}, with its origin in the
         * top-left corner and axes that extend down and to the right from the origin point.
         *
         * The returned point is in the OpenGL screen coordinate system of the {@link WorldWindow}, with its origin in the bottom-left
         * corner and axes that extend up and to the right from the origin point.
         *
         * @param {Vec2} point The window-coordinate point to convert.
         * @param {Vec2} result A pre-allocated {@link Vec2} in which to return the computed point.
         * @returns {Vec2} The specified result parameter set to the computed point.
         * @throws {ArgumentError} If either argument is null or undefined.
         */
        NavigatorState.prototype.convertPointToViewport = function (point, result) {
            if (!screenPoint) {
                throw new ArgumentError(Logger.logMessage(Logger.LEVEL_SEVERE, "NavigatorState", "convertPointToViewport",
                    "missingPoint"));
            }

            if (!result) {
                throw new ArgumentError(Logger.logMessage(Logger.LEVEL_SEVERE, "NavigatorState", "convertPointToViewport",
                    "missingResult"));
            }
            // TODO

            return result;
        };

        /**
         * Computes a ray originating at the navigator's eyePoint and extending through the specified point in window
         * coordinates.
         *
         * The specified point is understood to be in the window coordinate system of the {@link WorldWindow}, with its origin in the
         * top-left corner and axes that extend down and to the right from the origin point.
         *
         * The results of this method are undefined if the specified point is outside of the {@link WorldWindow}'s bounds.
         *
         * @param {Vec2} screenPoint The point to convert.
         * @param {Line} result A pre-allocated {@link Line} in which to return the computed ray.
         * @returns {Line} The result argument set to the origin and direction of the computed ray.
         */
        NavigatorState.prototype.rayFromScreenPoint = function (screenPoint, result) {
            if (!screenPoint) {
                throw new ArgumentError(Logger.logMessage(Logger.LEVEL_SEVERE, "NavigatorState", "rayFromScreenPoint",
                    "missingPoint"));
            }

            if (!result) {
                throw new ArgumentError(Logger.logMessage(Logger.LEVEL_SEVERE, "NavigatorState", "rayFromScreenPoint",
                    "missingResult"));
            }
            // TODO

            return result;
        };

        /**
         * Computes the approximate size of a pixel at a specified distance from the navigator's eyePoint.
         *
         * This method assumes the model of a screen composed of rectangular pixels, where pixel coordinates demote infinitely
         * thin space between pixels. The units of the returned size are in model coordinates per pixel (usually meters per
         * pixel). This returns 0 if the specified distance is zero. The returned size is undefined if the distance is less than
         * zero.
         *
         * @param {Number} distance The distance from the eye point at which to determine pixel size, in model coordinates.
         * @returns {Number} The approximate pixel size at the specified distance from the eye point, in model coordinates per pixel.
         */
        NavigatorState.prototype.pixelSizeAtDistance = function (distance) {
            // TODO

            return 0;
        };

        return NavigatorState;
    });