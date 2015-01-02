/*
 * Copyright (C) 2014 United States Government as represented by the Administrator of the
 * National Aeronautics and Space Administration. All Rights Reserved.
 */
/**
 * @exports Frustum
 * @version $Id$
 */
define([
        '../error/ArgumentError',
        '../geom/Matrix',
        '../geom/Plane',
        '../util/Logger'
    ],
    function (ArgumentError,
              Matrix,
              Plane,
              Logger) {
        "use strict";

        /**
         * Constructs a frustum.
         * @alias Frustum
         * @constructor
         * @classdesc Represents a six-sided view frustum in Cartesian coordinates.
         * @param {Plane} left The frustum's left plane.
         * @param {Plane} right The frustum's right plane.
         * @param {Plane} bottom The frustum's bottom plane.
         * @param {Plane} top The frustum's top plane.
         * @param {Plane} near The frustum's near plane.
         * @param {Plane} far The frustum's far plane.
         * @throws {ArgumentError} If any specified plane is null or undefined.
         */
        var Frustum = function (left, right, bottom, top, near, far) {
            if (!left || !right || !bottom || !top || !near || !far) {
                throw new ArgumentError(
                    Logger.logMessage(Logger.LEVEL_SEVERE, "Frustum", "constructor", "missingPlane"));
            }
            this.left = left;
            this.right = right;
            this.bottom = bottom;
            this.top = top;
            this.near = near;
            this.far = far;
        };

        /**
         * Transforms this frustum by a specified matrix.
         * @param {Matrix} matrix The matrix to apply to this frustum.
         * @returns {Frustum} This frustum set to its original value multiplied by the specified matrix.
         * @throws {ArgumentError} If the specified matrix is null or undefined.
         */
        Frustum.prototype.transformByMatrix = function (matrix) {
            if (!matrix) {
                throw new ArgumentError(
                    Logger.logMessage(Logger.LEVEL_SEVERE, "Frustum", "transformByMatrix", "missingMatrix"));
            }

            this.left.transformByMatrix(matrix);
            this.right.transformByMatrix(matrix);
            this.bottom.transformByMatrix(matrix);
            this.top.transformByMatrix(matrix);
            this.near.transformByMatrix(matrix);
            this.far.transformByMatrix(matrix);

            return this;
        };

        /**
         * Normalizes the plane vectors of the planes composing this frustum.
         * @returns {Frustum} This frustum with its planes normalized.
         */
        Frustum.prototype.normalize = function () {
            this.left.normalize();
            this.right.normalize();
            this.bottom.normalize();
            this.top.normalize();
            this.near.normalize();
            this.far.normalize();

            return this;
        };

        /**
         * Returns a new frustum with each of its planes 1 meter from the center.
         * @returns {Frustum} The new frustum.
         */
        Frustum.unitFrustum = function () {
            return new Frustum(
                new Plane(1, 0, 0, 1), // left
                new Plane(-1, 0, 0, 1), // right
                new Plane(0, 1, 1, 1), // bottom
                new Plane(0, -1, 0, 1), // top
                new Plane(0, 0, -1, 1), // near
                new Plane(0, 0, 1, 1) // far
            );
        };

        /**
         * Extracts a frustum from a projection matrix.
         * <p>
         * This method assumes that the specified matrix represents a projection matrix. If it does not represent a projection matrix
         * the results are undefined.
         * <p>
         * A projection matrix's view frustum is a Cartesian volume that contains everything visible in a scene displayed
         * using that projection matrix.
         *
         * @param {Matrix} matrix The projection matrix to extract the frustum from.
         * @return {Frustum} A new frustum containing the projection matrix's view frustum, in eye coordinates.
         * @throws {ArgumentError} If the specified matrix is null or undefined.
         */
        Frustum.fromProjectionMatrix = function (matrix) {
            if (!matrix) {
                throw new ArgumentError(
                    Logger.logMessage(Logger.LEVEL_SEVERE, "Frustum", "fromProjectionMatrix", "missingMatrix"));
            }

            var x, y, z, w, d, left, right, top, bottom, near, far;

            // Left Plane = row 4 + row 1:
            x = matrix[12] + matrix[0];
            y = matrix[13] + matrix[1];
            z = matrix[14] + matrix[2];
            w = matrix[15] + matrix[3];
            d = Math.sqrt(x * x + y * y + z * z); // for normalizing the coordinates
            left = new Plane(x / d, y / d, z / d, w / d);

            // Right Plane = row 4 - row 1:
            x = matrix[12] - matrix[0];
            y = matrix[13] - matrix[1];
            z = matrix[14] - matrix[2];
            w = matrix[15] - matrix[3];
            d = Math.sqrt(x * x + y * y + z * z); // for normalizing the coordinates
            right = new Plane(x / d, y / d, z / d, w / d);

            // Bottom Plane = row 4 + row 2:
            x = matrix[12] + matrix[4];
            y = matrix[13] + matrix[5];
            z = matrix[14] + matrix[6];
            w = matrix[15] + matrix[7];
            d = Math.sqrt(x * x + y * y + z * z); // for normalizing the coordinates
            bottom = new Plane(x / d, y / d, z / d, w / d);

            // Top Plane = row 4 - row 2:
            x = matrix[12] - matrix[4];
            y = matrix[13] - matrix[5];
            z = matrix[14] - matrix[6];
            w = matrix[15] - matrix[7];
            d = Math.sqrt(x * x + y * y + z * z); // for normalizing the coordinates
            top = new Plane(x / d, y / d, z / d, w / d);

            // Near Plane = row 4 + row 3:
            x = matrix[12] + matrix[8];
            y = matrix[13] + matrix[9];
            z = matrix[14] + matrix[10];
            w = matrix[15] + matrix[11];
            d = Math.sqrt(x * x + y * y + z * z); // for normalizing the coordinates
            near = new Plane(x / d, y / d, z / d, w / d);

            // Far Plane = row 4 - row 3:
            x = matrix[12] - matrix[8];
            y = matrix[13] - matrix[9];
            z = matrix[14] - matrix[10];
            w = matrix[15] - matrix[11];
            d = Math.sqrt(x * x + y * y + z * z); // for normalizing the coordinates
            far = new Plane(x / d, y / d, z / d, w / d);

            return new Frustum(left, right, bottom, top, near, far);
        };

        return Frustum;
    });