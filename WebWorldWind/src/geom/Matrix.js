/*
 * Copyright (C) 2014 United States Government as represented by the Administrator of the
 * National Aeronautics and Space Administration. All Rights Reserved.
 */

define([
        '../util/Logger',
        '../error/ArgumentError',
        'Vec3',
        'Angle',
        '../globe/EllipsoidalGlobe'
    ],
    function (Logger, 
              ArgumentError, 
              Vec3,
              Angle,
              Globe) {
        "use strict";

        /**
         * Transformation matrix.
         * @alias Matrix
         * @param {Number} m11 matrix element at row 1, column 1
         * @param {Number} m12 matrix element at row 1, column 2
         * @param {Number} m13 matrix element at row 1, column 3
         * @param {Number} m14 matrix element at row 1, column 4
         * @param {Number} m21 matrix element at row 2, column 1
         * @param {Number} m22 matrix element at row 2, column 2
         * @param {Number} m23 matrix element at row 2, column 3
         * @param {Number} m24 matrix element at row 2, column 4
         * @param {Number} m31 matrix element at row 3, column 1
         * @param {Number} m32 matrix element at row 3, column 2
         * @param {Number} m33 matrix element at row 3, column 3
         * @param {Number} m34 matrix element at row 3, column 4
         * @param {Number} m41 matrix element at row 4, column 1
         * @param {Number} m42 matrix element at row 4, column 2
         * @param {Number} m43 matrix element at row 4, column 3
         * @param {Number} m44 matrix element at row 4, column 4
         * @param {Boolean} isOrthonormalTransform denotes that transformation matrix is orthonormal
         * @constructor
         */
        function Matrix(m11, m12, m13, m14,
                        m21, m22, m23, m24,
                        m31, m32, m33, m34,
                        m41, m42, m43, m44,
                        isOrthonormalTransform) {
            this.m11 = m11;
            this.m12 = m12;
            this.m13 = m13;
            this.m14 = m14;
            this.m21 = m21;
            this.m22 = m22;
            this.m23 = m23;
            this.m24 = m24;
            this.m31 = m31;
            this.m32 = m32;
            this.m33 = m33;
            this.m34 = m34;
            this.m41 = m41;
            this.m42 = m42;
            this.m43 = m43;
            this.m44 = m44;
            this.isOrthonormalTransform = isOrthonormalTransform;
        }

        Matrix.NUM_ELEMENTS = 16;

        Matrix.EPSILON = 1.0e-6;

        /**
         * Create an identity matrix scale by "value" 
         * @param {Number} value diagonal of matrix
         * @returns {Matrix}
         */
        Matrix.fromNumber = function (value) {
            return new Matrix(
                value, 0, 0, 0,
                0, value, 0, 0,
                0, 0, value, 0,
                0, 0, 0, value,
                true
            );
        };

        /**
         * Create a matrix form a subset of an array.
         *
         * @param {Array} compArray data for source of matrix
         * @param {Number} offset index to initial data element
         * @param {Boolean} rowMajor determine whether to transpose matrix
         * @returns {Matrix}
         */
        Matrix.fromArray = function (compArray, offset, rowMajor) {
            var msg;
            if (!(compArray instanceof Array)) {
                msg = "Matrix.fromArray: " + "generic.ArrayExpected - " + "compArray";
                Logger.log(Logger.LEVEL_SEVERE, msg);
                throw new ArgumentError(msg);
            }
            if ((compArray.length - offset) < Matrix.NUM_ELEMENTS) {
                msg = "Matrix.fromArray: " + "generic.ArrayInvalidLength - " + "compArray";
                Logger.log(Logger.LEVEL_SEVERE, msg);
                throw new ArgumentError(msg);
            }

            if (rowMajor) {
                return new Matrix(
                    // Row 1
                    compArray[0 + offset],
                    compArray[1 + offset],
                    compArray[2 + offset],
                    compArray[3 + offset],
                    // Row 2
                    compArray[4 + offset],
                    compArray[5 + offset],
                    compArray[6 + offset],
                    compArray[7 + offset],
                    // Row 3
                    compArray[8 + offset],
                    compArray[9 + offset],
                    compArray[10 + offset],
                    compArray[11 + offset],
                    // Row 4
                    compArray[12 + offset],
                    compArray[13 + offset],
                    compArray[14 + offset],
                    compArray[15 + offset],

                    true
                );
            }
            else {
                return new Matrix(
                    // Row 1
                    compArray[0 + offset],
                    compArray[4 + offset],
                    compArray[8 + offset],
                    compArray[12 + offset],
                    // Row 2
                    compArray[1 + offset],
                    compArray[5 + offset],
                    compArray[9 + offset],
                    compArray[13 + offset],
                    // Row 3
                    compArray[2 + offset],
                    compArray[6 + offset],
                    compArray[10 + offset],
                    compArray[14 + offset],
                    // Row 4
                    compArray[3 + offset],
                    compArray[7 + offset],
                    compArray[11 + offset],
                    compArray[15 + offset],

                    true
                );
            }
        };

        /**
         * Store a matrix to a subset of an array.
         *
         * @param {Array} compArray array to write matrix to
         * @param {Number} offset index of first element of array
         * @param {Boolean} rowMajor determine whether to transpose matrix
         * @returns {Array}
         */
        Matrix.prototype.toArray = function (compArray, offset, rowMajor) {
            var msg;
            if (!(compArray instanceof Array)) {
                msg = "Matrix.toArray: " + "generic.ArrayExpected - " + "compArray";
                Logger.log(Logger.LEVEL_SEVERE, msg);
                throw new ArgumentError(msg);
            }
            if ((compArray.length - offset) < Matrix.NUM_ELEMENTS) {
                msg = "Matrix.toArray: " + "generic.ArrayInvalidLength - " + "compArray";
                Logger.log(Logger.LEVEL_SEVERE, msg);
                throw new ArgumentError(msg);
            }

            if (rowMajor) {
                // Row 1
                //noinspection PointlessArithmeticExpression
                compArray[0 + offset] = this.m11;
                compArray[1 + offset] = this.m12;
                compArray[2 + offset] = this.m13;
                compArray[3 + offset] = this.m14;
                // Row 2
                compArray[4 + offset] = this.m21;
                compArray[5 + offset] = this.m22;
                compArray[6 + offset] = this.m23;
                compArray[7 + offset] = this.m24;
                // Row 3
                compArray[8 + offset] = this.m31;
                compArray[9 + offset] = this.m32;
                compArray[10 + offset] = this.m33;
                compArray[11 + offset] = this.m34;
                // Row 4
                compArray[12 + offset] = this.m41;
                compArray[13 + offset] = this.m42;
                compArray[14 + offset] = this.m43;
                compArray[15 + offset] = this.m44;
            }
            else {
                // Row 1
                //noinspection PointlessArithmeticExpression
                compArray[0 + offset] = this.m11;
                compArray[4 + offset] = this.m12;
                compArray[8 + offset] = this.m13;
                compArray[12 + offset] = this.m14;
                // Row 2
                compArray[1 + offset] = this.m21;
                compArray[5 + offset] = this.m22;
                compArray[9 + offset] = this.m23;
                compArray[13 + offset] = this.m24;
                // Row 3
                compArray[2 + offset] = this.m31;
                compArray[6 + offset] = this.m32;
                compArray[10 + offset] = this.m33;
                compArray[14 + offset] = this.m34;
                // Row 4
                compArray[3 + offset] = this.m41;
                compArray[7 + offset] = this.m42;
                compArray[11 + offset] = this.m43;
                compArray[15 + offset] = this.m44;
            }

            return compArray;
        };

        /**
         * Returns a Cartesian transform <code>Matrix</code> that maps a local orientation to model coordinates. The
         * orientation is specified by an array of three <code>axes</code>. The <code>axes</code> array must contain three
         * non-null vectors, which are interpreted in the following order: x-axis, y-axis, z-axis. This ensures that the
         * axes in the returned <code>Matrix</code> have unit length and are orthogonal to each other.
         *
         * @param {Array} axes an array of three non-null vectors defining a local orientation in the following order:
         *                  x-axis,
         *                  y-axis,
         *                  z-axis.
         * @returns {Matrix} a <code>Matrix</code> that transforms local to global coordinates.
         * @throws ArgumentError
         *          if <code>axes</code> is not an <code>Array</code>,
         *          if <code>axes</code> contains less than three elements, or
         *          if any of the first three elements in <code>axes</code> is not a <code>Vec3</code>.
         */
        Matrix.fromAxes = function (axes) {
            var msg;
            if (!(axes instanceof Array)) {
                msg = "Matrix.fromAxes: " + "generic.ArrayExpected - " + "axes";
                Logger.log(Logger.LEVEL_SEVERE, msg);
                throw new ArgumentError(msg);
            }

            if (axes.length < 3) {
                msg = "Matrix.fromAxes: " + "generic.ArrayInvalidLength - " + "axes";
                Logger.log(Logger.LEVEL_SEVERE, msg);
                throw new ArgumentError(msg);
            }

            if (!(axes[0] instanceof Vec3) || !(axes[1] instanceof Vec3) || !(axes[2] instanceof Vec3)) {
                msg = "Matrix.fromAxes: " + "generic.Vec3Expected - " + "axes[0], axes[1], or axes[2]";
                Logger.log(Logger.LEVEL_SEVERE, msg);
                throw new ArgumentError(msg);
            }

            var s = axes[0].normalize(),
                f = s.cross(axes[1]).normalize(),
                u = f.cross(s).normalize();

            return new Matrix(
                s.x, u.x, f.x, 0.0,
                s.y, u.y, f.y, 0.0,
                s.z, u.z, f.z, 0.0,
                0.0, 0.0, 0.0, 1.0,
                true);
        };

        // TODO: re-enable after dealing with polymorphism
        //public static Matrix fromAxisAngle(Angle angle, Vec3 axis)
        //{
        //    if (angle == null)
        //    {
        //        msg = "generic.AngleExpected";
        //        Logger.log(Logger.LEVEL_SEVERE, msg);
        //        throw new ArgumentError(msg);
        //    }
        //    if (axis == null)
        //    {
        //        msg = "nullValue.Vec3IsNull");
        //        Logger.log(Logger.LEVEL_SEVERE, msg);
        //        throw new ArgumentError(msg);
        //    }
        //
        //    return fromAxisAngle(angle, axis.x, axis.y, axis.z, true);
        //}

        // TODO: re-enable after dealing with polymorphism
        //public static Matrix fromAxisAngle(Angle angle, double axisX, double axisY, double axisZ)
        //{
        //    if (angle == null)
        //    {
        //        msg = "generic.AngleExpected";
        //        Logger.log(Logger.LEVEL_SEVERE, msg);
        //        throw new ArgumentError(msg);
        //    }
        //    return fromAxisAngle(angle, axisX, axisY, axisZ, true);
        //}

        /**
         * Create a rotation transformation transformation matrix from an axis and an angle.
         *
         * @param {Number} angle rotation angle in degrees
         * @param {Number} axisX x component of rotation axis
         * @param {Number} axisY y component of rotation axis
         * @param {Number} axisZ z component of rotation axis
         * @param {Boolean} normalize denotes that the axis might not be normalized 
         * @returns {Matrix} a rotation matrix
         */
        Matrix.fromAxisAngle = function (angle, axisX, axisY, axisZ, normalize) {
            if (normalize) {
                var length = Math.sqrt((axisX * axisX) + (axisY * axisY) + (axisZ * axisZ));
                if (!isZero(length) && (length != 1.0)) {
                    axisX /= length;
                    axisY /= length;
                    axisZ /= length;
                }
            }

            var c = Math.cos(Angle.DEGREES_TO_RADIANS * angle),
                s = Math.sin(Angle.DEGREES_TO_RADIANS * angle),
                one_minus_c = 1 - c;

            return new Matrix(
                // Row 1
                c + (one_minus_c * axisX * axisX),
                (one_minus_c * axisX * axisY) - (s * axisZ),
                (one_minus_c * axisX * axisZ) + (s * axisY),
                0.0,
                // Row 2
                (one_minus_c * axisX * axisY) + (s * axisZ),
                c + (one_minus_c * axisY * axisY),
                (one_minus_c * axisY * axisZ) - (s * axisX),
                0.0,
                // Row 3
                (one_minus_c * axisX * axisZ) - (s * axisY),
                (one_minus_c * axisY * axisZ) + (s * axisX),
                c + (one_minus_c * axisZ * axisZ),
                0.0,
                // Row 4
                0.0, 0.0, 0.0, 1.0,
                // Rotation matrices are orthogonal, 3D transforms.
                true);
        };

        // TODO: re-enable after dealing with polymorphism
        //public static Matrix fromQuaternion(Quaternion quaternion)
        //{
        //    if (quaternion == null)
        //    {
        //        msg = "nullValue.QuaternionIsNull");
        //        Logger.log(Logger.LEVEL_SEVERE, msg);
        //        throw new ArgumentError(msg);
        //    }
        //
        //    return fromQuaternion(quaternion.x, quaternion.y, quaternion.z, quaternion.w, true);
        //}

        /**
         * Create a rotation transformation matrix from a quaternion.
         *
         * @param {Number} x x component of quaternion
         * @param {Number} y y component of quaternion
         * @param {Number} z z component of quaternion
         * @param {Number} w w component of quaternion
         * @param {Boolean} normalize denotes that the quaternion might not be normalized
         * @returns {Matrix} a rotation matrix
         */
        Matrix.fromQuaternion = function (x, y, z, w, normalize) {
            if (normalize) {
                var length = Math.sqrt((x * x) + (y * y) + (z * z) + (w * w));
                if (!isZero(length) && (length != 1)) {
                    x /= length;
                    y /= length;
                    z /= length;
                    w /= length;
                }
            }

            return new Matrix(
                // Row 1
                1.0 - (2.0 * y * y) - (2.0 * z * z),
                (2.0 * x * y) - (2.0 * z * w),
                (2.0 * x * z) + (2.0 * y * w),
                0.0,
                // Row 2
                (2.0 * x * y) + (2.0 * z * w),
                1.0 - (2.0 * x * x) - (2.0 * z * z),
                (2.0 * y * z) - (2.0 * x * w),
                0.0,
                // Row 3
                (2.0 * x * z) - (2.0 * y * w),
                (2.0 * y * z) + (2.0 * x * w),
                1.0 - (2.0 * x * x) - (2.0 * y * y),
                0.0,
                // Row 4
                0.0, 0.0, 0.0, 1.0,
                // Rotation matrices are orthogonal, 3D transforms.
                true);
        };

        /**
         * Create a rotation transformation matrix from Euler angles.
         *
         * @param {Number} xAngle rotation about x axis in degrees
         * @param {Number} yAngle rotation about y axis in degrees
         * @param {Number} zAngle rotation about z axis in degrees
         * @returns {Matrix} a rotation matrix
         */
        Matrix.fromRotationXYZ = function (xAngle, yAngle, zAngle) {
            var cx = Math.cos(Angle.DEGREES_TO_RADIANS * xAngle),
                sx = Math.sin(Angle.DEGREES_TO_RADIANS * xAngle),
                cy = Math.cos(Angle.DEGREES_TO_RADIANS * yAngle),
                sy = Math.sin(Angle.DEGREES_TO_RADIANS * yAngle),
                cz = Math.cos(Angle.DEGREES_TO_RADIANS * zAngle),
                sz = Math.sin(Angle.DEGREES_TO_RADIANS * zAngle);

            return new Matrix(
                cy * cz, -cy * sz, sy, 0.0,
                (sx * sy * cz) + (cx * sz), -(sx * sy * sz) + (cx * cz), -sx * cy, 0.0,
                -(cx * sy * cz) + (sx * sz), (cx * sy * sz) + (sx * cz), cx * cy, 0.0,
                0.0, 0.0, 0.0, 1.0,
                // Rotation matrices are orthogonal, 3D transforms.
                true);
        };

        /**
         * Create a rotation transformation matrix about the x axis.
         *
         * @param {Number} angle rotation angle in degrees
         * @returns {Matrix} a rotation matrix
         */
        Matrix.fromRotationX = function (angle) {
            var c = Math.cos(Angle.DEGREES_TO_RADIANS * angle),
                s = Math.sin(Angle.DEGREES_TO_RADIANS * angle);

            return new Matrix(
                1.0, 0.0, 0.0, 0.0,
                0.0, c, -s, 0.0,
                0.0, s, c, 0.0,
                0.0, 0.0, 0.0, 1.0,
                // Rotation matrices are orthogonal, 3D transforms.
                true);
        };

        /**
         * Create a rotation transformation matrix about the y axis.
         *
         * @param {Number} angle rotation angle in degrees
         * @returns {Matrix} a rotation matrix
         */
        Matrix.fromRotationY = function (angle) {
            var c = Math.cos(Angle.DEGREES_TO_RADIANS * angle),
                s = Math.sin(Angle.DEGREES_TO_RADIANS * angle);

            return new Matrix(
                c, 0.0, s, 0.0,
                0.0, 1.0, 0.0, 0.0,
                -s, 0.0, c, 0.0,
                0.0, 0.0, 0.0, 1.0,
                // Rotation matrices are orthogonal, 3D transforms.
                true);
        };

        /**
         * Create a rotation transformation matrix about the z axis.
         *
         * @param {Number} angle rotation angle in degrees
         * @returns {Matrix} a rotation matrix
         */
        Matrix.fromRotationZ = function (angle) {
            var c = Math.cos(Angle.DEGREES_TO_RADIANS * angle),
                s = Math.sin(Angle.DEGREES_TO_RADIANS * angle);

            return new Matrix(
                c, -s, 0.0, 0.0,
                s, c, 0.0, 0.0,
                0.0, 0.0, 1.0, 0.0,
                0.0, 0.0, 0.0, 1.0,
                // Rotation matrices are orthogonal, 3D transforms.
                true);
        };

        // TODO: re-enable after dealing with polymorphism
        //public static Matrix fromScale(double scale)
        //{
        //    return fromScale(scale, scale, scale);
        //}

        // TODO: re-enable after dealing with polymorphism
        //public static Matrix fromScale(Vec3 scale)
        //{
        //    if (scale == null)
        //    {
        //        msg = "nullValue.Vec3IsNull");
        //        Logger.log(Logger.LEVEL_SEVERE, msg);
        //        throw new ArgumentError(msg);
        //    }
        //
        //    return fromScale(scale.x, scale.y, scale.z);
        //}

        /**
         * Create a scale transformation matrix.
         *
         * @param {Number} scaleX scale factor along the x axis
         * @param {Number} scaleY scale factor along the y axis
         * @param {Number} scaleZ scale factor along the z axis
         * @returns {Matrix} a scale matrix
         */
        Matrix.fromScale = function (scaleX, scaleY, scaleZ) {
            return new Matrix(
                scaleX, 0.0, 0.0, 0.0,
                0.0, scaleY, 0.0, 0.0,
                0.0, 0.0, scaleZ, 0.0,
                0.0, 0.0, 0.0, 1.0,
                // Scale matrices are non-orthogonal, 3D transforms.
                false);
        };

        // TODO: re-enable after dealing with polymorphism
        //public static Matrix fromTranslation(Vec3 translation)
        //{
        //    if (translation == null)
        //    {
        //        msg = "nullValue.Vec3IsNull");
        //        Logger.log(Logger.LEVEL_SEVERE, msg);
        //        throw new ArgumentError(msg);
        //    }
        //
        //    return fromTranslation(translation.x, translation.y, translation.z);
        //}

        /**
         * Create a translation transformation matrix.
         *
         * @param {Number} x x component of translation
         * @param {Number} y y component of translation
         * @param {Number} z z component of translation
         * @returns {Matrix} a translation matrix
         */
        Matrix.fromTranslation = function (x, y, z) {
            return new Matrix(
                1.0, 0.0, 0.0, x,
                0.0, 1.0, 0.0, y,
                0.0, 0.0, 1.0, z,
                0.0, 0.0, 0.0, 1.0,
                // Translation matrices are orthogonal, 3D transforms.
                true);
        };

        /**
         * Create a skew matrix.
         *
         * @param {Number} angleTheta in degrees
         * @param {Number} anglePhi in degrees
         * @returns {Matrix} a skew matrix
         */
        Matrix.fromSkew = function (angleTheta, anglePhi) {
            // from http://faculty.juniata.edu/rhodes/graphics/projectionmat.htm

            var cotTheta = 1.0e6,
                cotPhi = 1.0e6;

            if (angleTheta * Angle.DEGREES_TO_RADIANS < Matrix.EPSILON && 
                anglePhi * Angle.DEGREES_TO_RADIANS < Matrix.EPSILON) {
                cotTheta = 0;
                cotPhi = 0;
            }
            else {
                if (Math.abs(Math.tan(angleTheta * Angle.DEGREES_TO_RADIANS)) > Matrix.EPSILON)
                    cotTheta = 1 / Math.tan(angleTheta * Angle.DEGREES_TO_RADIANS);
                if (Math.abs(Math.tan(anglePhi * Angle.DEGREES_TO_RADIANS)) > Matrix.EPSILON)
                    cotPhi = 1 / Math.tan(anglePhi * Angle.DEGREES_TO_RADIANS);
            }

            return new Matrix(
                1.0, 0.0, -cotTheta, 0,
                0.0, 1.0, -cotPhi, 0,
                0.0, 0.0, 1.0, 0,
                0.0, 0.0, 0.0, 1.0,
                false);
        };

        /**
         * Returns a Cartesian transform <code>Matrix</code> that maps a local origin and orientation to model coordinates.
         * The transform is specified by a local <code>origin</code> and an array of three <code>axes</code>. The
         * <code>axes</code> array must contain three non-null vectors, which are interpreted in the following order:
         * x-axis, y-axis, z-axis. This ensures that the axes in the returned <code>Matrix</code> have unit length and are
         * orthogonal to each other.
         *
         * @param {Vec3} origin the origin of the local coordinate system.
         * @param {Array} axes   an array must of three non-null vectors defining a local orientation in the following order:
         *                      x-axis, y-axis, z-axis.
         *
         * @return {Matrix} a <code>Matrix</code> that transforms local coordinates to world coordinates.
         *
         * @throws ArgumentError 
         *      if <code>origin</code> is not a <code>Vec3</code>, 
         *      if <code>axes</code> is not an <code>Array</code>, 
         *      if <code>axes</code> contains less than three elements, or 
         *      if  any of the first three elements in <code>axes</code> are not <code>Vec3</code>.
         */
        Matrix.fromLocalOrientation = function (origin, axes) {
            var msg;
            if (!(origin instanceof Vec3)) {
                msg = "Matrix.fromLocalOrientation: " + "generic.Vec3Expected - " + "origin";
                Logger.log(Logger.LEVEL_SEVERE, msg);
                throw new ArgumentError(msg);
            }

            if (!(axes instanceof Array)) {
                msg = "Matrix.fromLocalOrientation: " + "generic.ArrayExpected - " + "axes";
                Logger.log(Logger.LEVEL_SEVERE, msg);
                throw new ArgumentError(msg);
            }

            if (axes.length < 3) {
                msg = "Matrix.fromLocalOrientation: " + "generic.ArrayInvalidLength - " + "axes";
                Logger.log(Logger.LEVEL_SEVERE, msg);
                throw new ArgumentError(msg);
            }

            if (!(axes[0] instanceof Vec3) || !(axes[1] instanceof Vec3) || !(axes[2] instanceof Vec3)) {
                msg = "Matrix.fromLocalOrientation: " + "generic.Vec3Expected - " + "axes[0], axes[1], or axes[2]";
                Logger.log(Logger.LEVEL_SEVERE, msg);
                throw new ArgumentError(msg);
            }

            return Matrix.fromTranslation(origin.x, origin.y, origin.z).multiply(Matrix.fromAxes(axes));
        };

        /**
         * Returns a viewing matrix in model coordinates defined by the specified View eye point, reference point indicating
         * the center of the scene, and up vector. The eye point, center point, and up vector are in model coordinates. The
         * returned viewing matrix maps the reference center point to the negative Z axis, and the eye point to the origin,
         * and the up vector to the positive Y axis. When this matrix is used to define an OGL viewing transform along with
         * a typical projection matrix such as {@link #fromPerspective(Angle, double, double, double, double)} , this maps
         * the center of the scene to the center of the viewport, and maps the up vector to the viewoport's positive Y axis
         * (the up vector points up in the viewport). The eye point and reference center point must not be coincident, and
         * the up vector must not be parallel to the line of sight (the vector from the eye point to the reference center
         * point).
         *
         * @param {Vec3} eye    the eye point, in model coordinates.
         * @param {Vec3} center the scene's reference center point, in model coordinates.
         * @param {Vec3} up     the direction of the up vector, in model coordinates.
         *
         * @return {Matrix} a viewing matrix in model coordinates defined by the specified eye point, reference center point, and up
         *         vector.
         *
         * @throws ArgumentError 
         *      if any of the eye point, reference center point, or up vector are not <code>Vec3</code>, 
         *      if the eye point and reference center point are coincident, or 
         *      if the up vector and the line of sight are parallel.
         */
        Matrix.fromViewLookAt = function (eye, center, up) {
            var msg;
            if (!(eye instanceof Vec3) || !(center instanceof Vec3) || !(up instanceof Vec3)) {
                msg = "Matrix.fromViewLookAt: " + "generic.Vec3Expected - " + "eye, center, or up";
                Logger.log(Logger.LEVEL_SEVERE, msg);
                throw new ArgumentError(msg);
            }

            if (eye.distanceTo(center) <= Matrix.EPSILON) {
                msg = "Matrix.fromViewLookAt: " + "Geom.EyeAndCenterInvalid - " + eye.toString() + center.toString();
                Logger.log(Logger.LEVEL_SEVERE, msg);
                throw new ArgumentError(msg);
            }

            var forward = center.subtract(eye),
                f = forward.normalize(),
                s = f.cross(up).normalize();

            // TODO: this is suspect since s.getLength() for a normalized vector should be 1
            if (s.getLength() <= Matrix.EPSILON) {
                msg = "Matrix.fromViewLookAt: " + "Geom.UpAndLineOfSightInvalid - " + up.toString() + forward.toString();
                Logger.log(Logger.LEVEL_SEVERE, msg);
                throw new ArgumentError(msg);
            }

            var u = s.cross(forward).normalize();

            var mAxes = new Matrix(
                s.x, s.y, s.z, 0.0,
                u.x, u.y, u.z, 0.0,
                -f.x, -f.y, -f.z, 0.0,
                0.0, 0.0, 0.0, 1.0,
                true);

            var mEye = Matrix.fromTranslation(-eye.x, -eye.y, -eye.z);

            return mAxes.multiply(mEye);
        };

        /**
         * Returns a local origin transform matrix in model coordinates defined by the specified eye point, reference point
         * indicating the center of the local scene, and up vector. The eye point, center point, and up vector are in model
         * coordinates. The returned viewing matrix maps the the positive Z axis to the reference center point, the origin
         * to the eye point, and the positive Y axis to the up vector. The eye point and reference center point must not be
         * coincident, and the up vector must not be parallel to the line of sight (the vector from the eye point to the
         * reference center point).
         *
         * @param {Vec3} eye    the eye point, in model coordinates.
         * @param {Vec3} center the scene's reference center point, in model coordinates.
         * @param {Vec3} up     the direction of the up vector, in model coordinates.
         *
         * @return {Matrix} a viewing matrix in model coordinates defined by 
         *          the specified eye point, 
         *          reference center point, and 
         *          up vector.
         *
         * @throws ArgumentError 
         *          if any of the eye point, reference center point, or up vector are not <code>Vec3</code>, 
         *          if the eye point and reference center point are coincident, or 
         *          if the up vector and the line of sight are parallel.
         */
        Matrix.fromModelLookAt = function (eye, center, up) {
            var msg;
            if (!(eye instanceof Vec3) || !(center instanceof Vec3) || !(up instanceof Vec3)) {
                msg = "Matrix.fromModelLookAt: " + "generic.Vec3Expected - " + "eye, center, or up";
                Logger.log(Logger.LEVEL_SEVERE, msg);
                throw new ArgumentError(msg);
            }

            if (eye.distanceTo(center) <= Matrix.EPSILON) {
                msg = "Matrix.fromModelLookAt: " + "Geom.EyeAndCenterInvalid - " + eye.toString() + center.toString();
                Logger.log(Logger.LEVEL_SEVERE, msg);
                throw new ArgumentError(msg);
            }

            var forward = center.subtract(eye),
                f = forward.normalize(),
                s = up.cross(f).normalize();

            // TODO: this is suspect, since s.getLength() for a normalized vector should be 1
            if (s.getLength() <= Matrix.EPSILON) {
                msg = "Matrix.fromModelLookAt: " + "Geom.UpAndLineOfSightInvalid: " + up.toString() + forward.toString();
                Logger.log(Logger.LEVEL_SEVERE, msg);
                throw new ArgumentError(msg);
            }

            var u = f.cross(s).normalize();

            var mAxes = new Matrix(
                s.x, u.x, f.x, 0.0,
                s.y, u.y, f.y, 0.0,
                s.z, u.z, f.z, 0.0,
                0.0, 0.0, 0.0, 1.0,
                true);

            var mEye = Matrix.fromTranslation(eye.x, eye.y, eye.z);

            return mEye.multiply(mAxes);
        };

        /**
         * Create a perspective projection matrix.
         *
         * @param {Number} horizontalFieldOfView horizontal field of view in degrees
         * @param {Number} viewportWidth width of viewport
         * @param {Number} viewportHeight height of viewport
         * @param {Number} near distance to near clipping plane
         * @param {Number} far distance to far clipping plane
         * @returns {Matrix} a projection matrix
         * @throws ArgumentError
         *          if any argument is outside the range of valid values (this depends on the specific parameter)
         */
        Matrix.fromPerspective = function (/* Angle */ horizontalFieldOfView, viewportWidth, viewportHeight, near, far) {
            var msg;

            var fovX = horizontalFieldOfView;
            if (fovX <= 0.0 || fovX > 180.0) {
                msg = "Matrix.fromPerspective: " + "generic.ArgumentOutOfRange - " + "horizontalFieldOfView=" + fovX.toString();
                Logger.log(Logger.LEVEL_SEVERE, msg);
                throw new ArgumentError(msg);
            }
            if (viewportWidth <= 0.0) {
                msg = "Matrix.fromPerspective: " + "generic.ArgumentOutOfRange - " + "viewportWidth=" + viewportWidth.toString();
                Logger.log(Logger.LEVEL_SEVERE, msg);
                throw new ArgumentError(msg);
            }
            if (viewportHeight <= 0.0) {
                msg = "Matrix.fromPerspective: " + "generic.ArgumentOutOfRange - " + "viewportHeight=" + viewportHeight.toString();
                Logger.log(Logger.LEVEL_SEVERE, msg);
                throw new ArgumentError(msg);
            }
            if (near <= 0.0) {
                msg = "Matrix.fromPerspective: " + "generic.ArgumentOutOfRange - " + "near=" + near.toString();
                Logger.log(Logger.LEVEL_SEVERE, msg);
                throw new ArgumentError(msg);
            }
            if (far <= 0.0) {
                msg = "Matrix.fromPerspective: " + "generic.ArgumentOutOfRange - " + "far=" + far.toString();
                Logger.log(Logger.LEVEL_SEVERE, msg);
                throw new ArgumentError(msg);
            }
            if (far <= near) {
                msg = "Matrix.fromPerspective: " + "generic.ArgumentOutOfRange - " + "far=" + far.toString() + ",near=" + near.toString();
                Logger.log(Logger.LEVEL_SEVERE, msg);
                throw new ArgumentError(msg);
            }

            var f = 1.0 / Math.tan(0.5 * horizontalFieldOfView * Angle.DEGREES_TO_RADIANS);
            // We are using *horizontal* field-of-view here. This results in a different matrix than documented in sources
            // using vertical field-of-view.
            return new Matrix(
                f, 0.0, 0.0, 0.0,
                0.0, (f * viewportWidth) / viewportHeight, 0.0, 0.0,
                0.0, 0.0, -(far + near) / (far - near), -(2.0 * far * near) / (far - near),
                0.0, 0.0, -1.0, 0.0);
        };

        // TODO: re-enable after dealing with polymorphism
        //Matrix.fromPerspective = function(double width, double height, double near, double far)
        //{
        //    if (width <= 0.0)
        //    {
        //        msg = "generic.ArgumentOutOfRange", width);
        //        Logger.log(Logger.LEVEL_SEVERE, msg);
        //        throw new ArgumentError(msg);
        //    }
        //    if (height <= 0.0)
        //    {
        //        msg = "generic.ArgumentOutOfRange", height);
        //        Logger.log(Logger.LEVEL_SEVERE, msg);
        //        throw new ArgumentError(msg);
        //    }
        //    if (near <= 0.0)
        //    {
        //        msg = "generic.ArgumentOutOfRange", near);
        //        Logger.log(Logger.LEVEL_SEVERE, msg);
        //        throw new ArgumentError(msg);
        //    }
        //    if (far <= 0.0)
        //    {
        //        msg = "generic.ArgumentOutOfRange", far);
        //        Logger.log(Logger.LEVEL_SEVERE, msg);
        //        throw new ArgumentError(msg);
        //    }
        //    if (far <= near)
        //    {
        //        msg = "generic.ArgumentOutOfRange", far);
        //        Logger.log(Logger.LEVEL_SEVERE, msg);
        //        throw new ArgumentError(msg);
        //    }
        //
        //    return new Matrix(
        //        2.0 / width, 0.0, 0.0, 0.0,
        //        0.0, (2.0 * near) / height, 0.0, 0.0,
        //        0.0, 0.0, -(far + near) / (far - near), -(2.0 * far * near) / (far - near),
        //        0.0, 0.0, -1.0, 0.0);
        //};

        /**
         * Create an orthographic projection matrix.
         *
         * @param {Number} width width if the enclosing space
         * @param {Number} height height of the enclosing space
         * @param {Number} near distance to the near clipping plane
         * @param {Number} far distance to the far clipping plane
         * @returns {Matrix} a projection matrix
         * @throws ArgumentError
         *      if any arguments are outside the range of valid values (this depends on the specific parameter)
         */
        Matrix.fromOrthographic = function (width, height, near, far) {
            var msg;
            if (width <= 0.0) {
                msg = "Matrix.fromOrthographic: " + "generic.ArgumentOutOfRange - " + "width";
                Logger.log(Logger.LEVEL_SEVERE, msg);
                throw new ArgumentError(msg);
            }
            if (height <= 0.0) {
                msg = "Matrix.fromOrthographic: " + "generic.ArgumentOutOfRange - " + "height";
                Logger.log(Logger.LEVEL_SEVERE, msg);
                throw new ArgumentError(msg);
            }
            if (near <= 0.0) {
                msg = "Matrix.fromOrthographic: " + "generic.ArgumentOutOfRange - " + "near";
                Logger.log(Logger.LEVEL_SEVERE, msg);
                throw new ArgumentError(msg);
            }
            if (far <= 0.0) {
                msg = "Matrix.fromOrthographic: " + "generic.ArgumentOutOfRange - " + "far";
                Logger.log(Logger.LEVEL_SEVERE, msg);
                throw new ArgumentError(msg);
            }
            if (far <= near) {
                msg = "Matrix.fromOrthographic: " + "generic.ArgumentOutOfRange - " + "far";
                Logger.log(Logger.LEVEL_SEVERE, msg);
                throw new ArgumentError(msg);
            }

            return new Matrix(
                2.0 / width, 0.0, 0.0, 0.0,
                0.0, 2.0 / height, 0.0, 0.0,
                0.0, 0.0, -2.0 / (far - near), -(far + near) / (far - near),
                0.0, 0.0, 0.0, 1.0);
        };

        /**
         * Create a 2D orthographic projection matrix.
         *
         * @param {Number} width of the enclosing space
         * @param {Number} height height of the enclosing space
         * @returns {Matrix} a projection matrix
         */
        Matrix.fromOrthographic2D = function (width, height) {
            var msg;
            if (width <= 0.0) {
                msg = "Matrix.fromOrthographic2D: " + "generic.ArgumentOutOfRange - " + "width";
                Logger.log(Logger.LEVEL_SEVERE, msg);
                throw new ArgumentError(msg);
            }
            if (height <= 0.0) {
                msg = "Matrix.fromOrthographic2D: " + "generic.ArgumentOutOfRange - " + "height";
                Logger.log(Logger.LEVEL_SEVERE, msg);
                throw new ArgumentError(msg);
            }

            return new Matrix(
                2.0 / width, 0.0, 0.0, 0.0,
                0.0, 2.0 / height, 0.0, 0.0,
                0.0, 0.0, -1.0, 0.0,
                0.0, 0.0, 0.0, 1.0);
        };

        // TODO: re-enable after dealing with polymorphism
        ///**
        // * Computes a <code>Matrix</code> that will map a aligned 2D grid coordinates to geographic coordinates in degrees.
        // * It is assumed that the destination grid is parallel with lines of latitude and longitude, and has its origin in
        // * the upper left hand corner.
        // *
        // * @param sector      the grid sector.
        // * @param imageWidth  the grid width.
        // * @param imageHeight the grid height.
        // *
        // * @return <code>Matrix</code> that will map from grid coordinates to geographic coordinates in degrees.
        // *
        // * @throws IllegalArgumentException if <code>sector</code> is null, or if either <code>width</code> or
        // *                                  <code>height</code> are less than 1.
        // */
        //Matrix.fromImageToGeographic = function(imageWidth, imageHeight, /* Sector */ sector)
        //{
        //    // TODO: re-enable validation
        //    //if (imageWidth < 1 || imageHeight < 1)
        //    //{
        //    //    String message = "generic.InvalidImageSize", imageWidth, imageHeight);
        //    //    Logger.log(Logger.LEVEL_SEVERE, message);
        //    //    throw new ArgumentError(message);
        //    //}
        //    //if (sector == null)
        //    //{
        //    //    String message = "nullValue.SectorIsNull");
        //    //    Logger.log(Logger.LEVEL_SEVERE, message);
        //    //    throw new ArgumentError(message);
        //    //}
        //
        //    // Transform from grid coordinates to geographic coordinates. Since the grid is parallel with lines of latitude
        //    // and longitude, this is a simple scale and translation.
        //
        //    var sx = sector.getDeltaLonDegrees() / imageWidth,
        //        sy = -sector.getDeltaLatDegrees() / imageHeight,
        //        tx = sector.getMinLongitude().degrees,
        //        ty = sector.getMaxLatitude().degrees;
        //
        //    return new Matrix(
        //        sx, 0.0, tx, 0.0,
        //        0.0, sy, ty, 0.0,
        //        0.0, 0.0, 1.0, 0.0,
        //        0.0, 0.0, 0.0, 0.0);
        //}

        // TODO: re-enable after dealing with polymorphism
        //public static Matrix fromImageToGeographic(AVList worldFileParams)
        //{
        //    if (worldFileParams == null)
        //    {
        //        String message = "nullValue.ParamsIsNull");
        //        Logger.log(Logger.LEVEL_SEVERE, message);
        //        throw new ArgumentError(message);
        //    }
        //
        //    // Transform from geographic coordinates to source grid coordinates. Start with the following system of
        //    // equations. The values a-f are defined by the world file, which construct and affine transform mapping grid
        //    // coordinates to geographic coordinates. We can simply plug these into the upper 3x3 values of our matrix.
        //    //
        //    // | a b c |   | x |   | lon |
        //    // | d e f | * | y | = | lat |
        //    // | 0 0 1 |   | 1 |   | 1   |
        //
        //    Double a = AVListImpl.getDoubleValue(worldFileParams, WorldFile.WORLD_FILE_X_PIXEL_SIZE);
        //    Double d = AVListImpl.getDoubleValue(worldFileParams, WorldFile.WORLD_FILE_Y_COEFFICIENT);
        //    Double b = AVListImpl.getDoubleValue(worldFileParams, WorldFile.WORLD_FILE_X_COEFFICIENT);
        //    Double e = AVListImpl.getDoubleValue(worldFileParams, WorldFile.WORLD_FILE_Y_PIXEL_SIZE);
        //    Double c = AVListImpl.getDoubleValue(worldFileParams, WorldFile.WORLD_FILE_X_LOCATION);
        //    Double f = AVListImpl.getDoubleValue(worldFileParams, WorldFile.WORLD_FILE_Y_LOCATION);
        //
        //    if (a == null || b == null || c == null || d == null || e == null || f == null)
        //    {
        //        return null;
        //    }
        //
        //    return new Matrix(
        //        a, b, c, 0.0,
        //        d, e, f, 0.0,
        //        0.0, 0.0, 1.0, 0.0,
        //        0.0, 0.0, 0.0, 0.0);
        //}

        // TODO: re-enable after dealing with polymorphism
        //public static Matrix fromGeographicToImage(AVList worldFileParams)
        //{
        //    if (worldFileParams == null)
        //    {
        //        String message = "nullValue.ParamsIsNull");
        //        Logger.log(Logger.LEVEL_SEVERE, message);
        //        throw new ArgumentError(message);
        //    }
        //
        //    // Transform from geographic coordinates to source grid coordinates. Start with the following system of
        //    // equations. The values a-f are defined by the world file, which construct and affine transform mapping grid
        //    // coordinates to geographic coordinates. We want to find the transform that maps geographic coordinates to
        //    // grid coordinates.
        //    //
        //    // | a b c |   | x |   | lon |
        //    // | d e f | * | y | = | lat |
        //    // | 0 0 1 |   | 1 |   | 1   |
        //    //
        //    // Expanding the matrix multiplication:
        //    //
        //    // a*x + b*y + c = lon
        //    // d*x + e*y + f = lat
        //    //
        //    // Then solving for x and y by eliminating variables:
        //    //
        //    // x0 = d - (e*a)/b
        //    // y0 = e - (d*b)/a
        //    // (-e/(b*x0))*lon + (1/x0)*lat + (e*c)/(b*x0) - f/x0 = x
        //    // (-d/(a*y0))*lon + (1/y0)*lat + (d*c)/(a*y0) - f/y0 = y
        //    //
        //    // And extracting new the matrix coefficients a'-f':
        //    //
        //    // a' = -e/(b*x0)
        //    // b' = 1/x0
        //    // c' = (e*c)/(b*x0) - f/x0
        //    // d' = -d/(a*y0)
        //    // e' = 1/y0
        //    // f' = (d*c)/(a*y0) - f/y0
        //    //
        //    // If b==0 and d==0, then we have the equation simplifies to:
        //    //
        //    // (1/a)*lon + (-c/a) = x
        //    // (1/e)*lat + (-f/e) = y
        //    //
        //    // And and the new matrix coefficients will be:
        //    //
        //    // a' = 1/a
        //    // b' = 0
        //    // c' = -c/a
        //    // d' = 0
        //    // e' = 1/e
        //    // f' = -f/e
        //
        //    Double a = AVListImpl.getDoubleValue(worldFileParams, WorldFile.WORLD_FILE_X_PIXEL_SIZE);
        //    Double d = AVListImpl.getDoubleValue(worldFileParams, WorldFile.WORLD_FILE_Y_COEFFICIENT);
        //    Double b = AVListImpl.getDoubleValue(worldFileParams, WorldFile.WORLD_FILE_X_COEFFICIENT);
        //    Double e = AVListImpl.getDoubleValue(worldFileParams, WorldFile.WORLD_FILE_Y_PIXEL_SIZE);
        //    Double c = AVListImpl.getDoubleValue(worldFileParams, WorldFile.WORLD_FILE_X_LOCATION);
        //    Double f = AVListImpl.getDoubleValue(worldFileParams, WorldFile.WORLD_FILE_Y_LOCATION);
        //
        //    if (a == null || b == null || c == null || d == null || e == null || f == null)
        //    {
        //        return null;
        //    }
        //
        //    if (b == 0.0 && d == 0.0)
        //    {
        //        return new Matrix(
        //            1.0 / a, 0.0, (-c / a), 0.0,
        //            0.0, 1.0 / e, (-f / e), 0.0,
        //            0.0, 0.0, 1.0, 0.0,
        //            0.0, 0.0, 0.0, 0.0);
        //    }
        //    else
        //    {
        //        double x0 = d - (e * a) / b;
        //        double ap = -e / (b * x0);
        //        double bp = 1.0 / x0;
        //        double cp = (e * c) / (b * x0) - f / x0;
        //
        //        double y0 = e - (d * b) / a;
        //        double dp = -d / (a * y0);
        //        double ep = 1.0 / y0;
        //        double fp = (d * c) / (a * y0) - f / y0;
        //
        //        return new Matrix(
        //            ap, bp, cp, 0.0,
        //            dp, ep, fp, 0.0,
        //            0.0, 0.0, 1.0, 0.0,
        //            0.0, 0.0, 0.0, 0.0);
        //    }
        //}

        // TODO: re-enable after dealing with polymorphism
        ///**
        // * Computes a <code>Matrix</code> that will map constrained 2D grid coordinates to geographic coordinates in
        // * degrees. The grid is defined by three control points. Each control point maps a location in the source grid to a
        // * geographic location.
        // *
        // * @param imagePoints three control points in the source grid.
        // * @param geoPoints   three geographic locations corresponding to each grid control point.
        // *
        // * @return <code>Matrix</code> that will map from geographic coordinates to grid coordinates in degrees.
        // *
        // * @throws IllegalArgumentException if either <code>imagePoints</code> or <code>geoPoints</code> is null or have
        // *                                  length less than 3.
        // */
        //public static Matrix fromImageToGeographic(java.awt.geom.Point2D[] imagePoints, LatLon[] geoPoints)
        //{
        //    if (imagePoints == null)
        //    {
        //        String message = "nullValue.ImagePointsIsNull");
        //        Logger.log(Logger.LEVEL_SEVERE, message);
        //        throw new ArgumentError(message);
        //    }
        //    if (geoPoints == null)
        //    {
        //        String message = "nullValue.GeoPointsIsNull");
        //        Logger.log(Logger.LEVEL_SEVERE, message);
        //        throw new ArgumentError(message);
        //    }
        //    if (imagePoints.length < 3)
        //    {
        //        String message = "generic.ArrayInvalidLength", "imagePoints.length < 3");
        //        Logger.log(Logger.LEVEL_SEVERE, message);
        //        throw new ArgumentError(message);
        //    }
        //    if (geoPoints.length < 3)
        //    {
        //        String message = "generic.ArrayInvalidLength", "geoPoints.length < 3");
        //        Logger.log(Logger.LEVEL_SEVERE, message);
        //        throw new ArgumentError(message);
        //    }
        //
        //    // Transform from geographic coordinates to source grid coordinates. Start with the following system of
        //    // equations. The values a-f are the unknown coefficients we want to derive, The (lat,lon) and (x,y)
        //    // coordinates are constants defined by the caller via geoPoints and imagePoints, respectively.
        //    //
        //    // | a b c |   | x1 x2 x3 |   | lon1 lon2 lon3 |
        //    // | d e f | * | y1 y2 y3 | = | lat1 lat2 lat3 |
        //    // | 0 0 1 |   | 1  1  1  |   | 1    1    1    |
        //    //
        //    // Expanding the matrix multiplication:
        //    //
        //    // a*x1 + b*y1 + c = lon1
        //    // a*x2 + b*y2 + c = lon2
        //    // a*x3 + b*y3 + c = lon3
        //    // d*x1 + e*y1 + f = lat1
        //    // d*x2 + e*y2 + f = lat2
        //    // d*x3 + e*y3 + f = lat3
        //    //
        //    // Then solving for a-c, and d-f by repeatedly eliminating variables:
        //    //
        //    // a0 = (x3-x1) - (x2-x1)*(y3-y1)/(y2-y1)
        //    // a = (1/a0) * [(lon3-lon1) - (lon2-lon1)*(y3-y1)/(y2-y1)]
        //    // b = (lon2-lon1)/(y2-y1) - a*(x2-x1)/(y2-y1)
        //    // c = lon1 - a*x1 - b*y1
        //    //
        //    // d0 = (x3-x1) - (x2-x1)*(y3-y1)/(y2-y1)
        //    // d = (1/d0) * [(lat3-lat1) - (lat2-lat1)*(y3-y1)/(y2-y1)]
        //    // e = (lat2-lat1)/(y2-y1) - d*(x2-x1)/(y2-y1)
        //    // f = lat1 - d*x1 - e*y1
        //
        //    double lat1 = geoPoints[0].getLatitude().degrees;
        //    double lat2 = geoPoints[1].getLatitude().degrees;
        //    double lat3 = geoPoints[2].getLatitude().degrees;
        //    double lon1 = geoPoints[0].getLongitude().degrees;
        //    double lon2 = geoPoints[1].getLongitude().degrees;
        //    double lon3 = geoPoints[2].getLongitude().degrees;
        //
        //    double x1 = imagePoints[0].getX();
        //    double x2 = imagePoints[1].getX();
        //    double x3 = imagePoints[2].getX();
        //    double y1 = imagePoints[0].getY();
        //    double y2 = imagePoints[1].getY();
        //    double y3 = imagePoints[2].getY();
        //
        //    double a0 = (x3 - x1) - (x2 - x1) * (y3 - y1) / (y2 - y1);
        //    double a = (1 / a0) * ((lon3 - lon1) - (lon2 - lon1) * (y3 - y1) / (y2 - y1));
        //    double b = (lon2 - lon1) / (y2 - y1) - a * (x2 - x1) / (y2 - y1);
        //    double c = lon1 - a * x1 - b * y1;
        //
        //    double d0 = (x3 - x1) - (x2 - x1) * (y3 - y1) / (y2 - y1);
        //    double d = (1 / d0) * ((lat3 - lat1) - (lat2 - lat1) * (y3 - y1) / (y2 - y1));
        //    double e = (lat2 - lat1) / (y2 - y1) - d * (x2 - x1) / (y2 - y1);
        //    double f = lat1 - d * x1 - e * y1;
        //
        //    return new Matrix(
        //        a, b, c, 0.0,
        //        d, e, f, 0.0,
        //        0.0, 0.0, 1.0, 0.0,
        //        0.0, 0.0, 0.0, 0.0);
        //}

        // TODO: re-enable after dealing with polymorphism
        //public static Matrix fromGeographicToImage(java.awt.geom.Point2D[] imagePoints, LatLon[] geoPoints)
        //{
        //    if (imagePoints == null)
        //    {
        //        String message = "nullValue.ImagePointsIsNull");
        //        Logger.log(Logger.LEVEL_SEVERE, message);
        //        throw new ArgumentError(message);
        //    }
        //    if (geoPoints == null)
        //    {
        //        String message = "nullValue.GeoPointsIsNull");
        //        Logger.log(Logger.LEVEL_SEVERE, message);
        //        throw new ArgumentError(message);
        //    }
        //    if (imagePoints.length < 3)
        //    {
        //        String message = "generic.ArrayInvalidLength", "imagePoints.length < 3");
        //        Logger.log(Logger.LEVEL_SEVERE, message);
        //        throw new ArgumentError(message);
        //    }
        //    if (geoPoints.length < 3)
        //    {
        //        String message = "generic.ArrayInvalidLength", "geoPoints.length < 3");
        //        Logger.log(Logger.LEVEL_SEVERE, message);
        //        throw new ArgumentError(message);
        //    }
        //
        //    // Transform from geographic coordinates to source grid coordinates. Start with the following system of
        //    // equations. The values a-f are the unknown coefficients we want to derive, The (lat,lon) and (x,y)
        //    // coordinates are constants defined by the caller via geoPoints and imagePoints, respectively.
        //    //
        //    // | a b c |   | lon1 lon2 lon3 |   | x1 x2 x3 |
        //    // | d e f | * | lat1 lat2 lat3 | = | y1 y2 y3 |
        //    // | 0 0 1 |   | 1    1    1    |   | 1  1  1  |
        //    //
        //    // Expanding the matrix multiplication:
        //    //
        //    // a*lon1 + b*lat1 + c = x1
        //    // a*lon2 + b*lat2 + c = x2
        //    // a*lon3 + b*lat3 + c = x3
        //    // d*lon1 + e*lat1 + f = y1
        //    // d*lon2 + e*lat2 + f = y2
        //    // d*lon3 + e*lat3 + f = y3
        //    //
        //    // Then solving for a-c, and d-f by repeatedly eliminating variables:
        //    //
        //    // a0 = (lon3-lon1) - (lon2-lon1)*(lat3-lat1)/(lat2-lat1)
        //    // a = (1/a0) * [(x3-x1) - (x2-x1)*(lat3-lat1)/(lat2-lat1)]
        //    // b = (x2-x1)/(lat2-lat1) - a*(lon2-lon1)/(lat2-lat1)
        //    // c = x1 - a*lon1 - b*lat1
        //    //
        //    // d0 = (lon3-lon1) - (lon2-lon1)*(lat3-lat1)/(lat2-lat1)
        //    // d = (1/d0) * [(y3-y1) - (y2-y1)*(lat3-lat1)/(lat2-lat1)]
        //    // e = (y2-y1)/(lat2-lat1) - d*(lon2-lon1)/(lat2-lat1)
        //    // f = y1 - d*lon1 - e*lat1
        //
        //    double lat1 = geoPoints[0].getLatitude().degrees;
        //    double lat2 = geoPoints[1].getLatitude().degrees;
        //    double lat3 = geoPoints[2].getLatitude().degrees;
        //    double lon1 = geoPoints[0].getLongitude().degrees;
        //    double lon2 = geoPoints[1].getLongitude().degrees;
        //    double lon3 = geoPoints[2].getLongitude().degrees;
        //
        //    double x1 = imagePoints[0].getX();
        //    double x2 = imagePoints[1].getX();
        //    double x3 = imagePoints[2].getX();
        //    double y1 = imagePoints[0].getY();
        //    double y2 = imagePoints[1].getY();
        //    double y3 = imagePoints[2].getY();
        //
        //    double a0 = (lon3 - lon1) - (lon2 - lon1) * (lat3 - lat1) / (lat2 - lat1);
        //    double a = (1 / a0) * ((x3 - x1) - (x2 - x1) * (lat3 - lat1) / (lat2 - lat1));
        //    double b = (x2 - x1) / (lat2 - lat1) - a * (lon2 - lon1) / (lat2 - lat1);
        //    double c = x1 - a * lon1 - b * lat1;
        //
        //    double d0 = (lon3 - lon1) - (lon2 - lon1) * (lat3 - lat1) / (lat2 - lat1);
        //    double d = (1 / d0) * ((y3 - y1) - (y2 - y1) * (lat3 - lat1) / (lat2 - lat1));
        //    double e = (y2 - y1) / (lat2 - lat1) - d * (lon2 - lon1) / (lat2 - lat1);
        //    double f = y1 - d * lon1 - e * lat1;
        //
        //    return new Matrix(
        //        a, b, c, 0.0,
        //        d, e, f, 0.0,
        //        0.0, 0.0, 1.0, 0.0,
        //        0.0, 0.0, 0.0, 0.0);
        //}

        // TODO: re-enable after dealing with polymorphism
        ///**
        // * Computes a Matrix that will map the geographic region defined by sector onto a Cartesian region of the specified
        // * <code>width</code> and <code>height</code> and centered at the point <code>(x, y)</code>.
        // *
        // * @param sector the geographic region which will be mapped to the Cartesian region
        // * @param x      x-coordinate of lower left hand corner of the Cartesian region
        // * @param y      y-coordinate of lower left hand corner of the Cartesian region
        // * @param width  width of the Cartesian region, extending to the right from the x-coordinate
        // * @param height height of the Cartesian region, extending up from the y-coordinate
        // *
        // * @return Matrix that will map from the geographic region to the Cartesian region.
        // *
        // * @throws IllegalArgumentException if <code>sector</code> is null, or if <code>width</code> or <code>height</code>
        // *                                  are less than zero.
        // */
        //public static Matrix fromGeographicToViewport(Sector sector, int x, int y, int width, int height)
        //{
        //    if (sector == null)
        //    {
        //        String message = "nullValue.SectorIsNull");
        //        Logger.log(Logger.LEVEL_SEVERE, message);
        //        throw new ArgumentError(message);
        //    }
        //
        //    if (width <= 0)
        //    {
        //        String message = "Geom.WidthInvalid", width);
        //        Logger.log(Logger.LEVEL_SEVERE, message);
        //        throw new ArgumentError(message);
        //    }
        //
        //    if (height <= 0)
        //    {
        //        String message = "Geom.HeightInvalid", height);
        //        Logger.log(Logger.LEVEL_SEVERE, message);
        //        throw new ArgumentError(message);
        //    }
        //
        //    Matrix transform = Matrix.IDENTITY;
        //    transform = transform.multiply(
        //        Matrix.fromTranslation(-x, -y, 0.0));
        //    transform = transform.multiply(
        //        Matrix.fromScale(width / sector.getDeltaLonDegrees(), height / sector.getDeltaLatDegrees(), 1.0));
        //    transform = transform.multiply(
        //        Matrix.fromTranslation(-sector.getMinLongitude().degrees, -sector.getMinLatitude().degrees, 0.0));
        //
        //    return transform;
        //}

        // TODO: re-enable after dealing with polymorphism
        ///**
        // * Computes a Matrix that will map a Cartesian region of the specified <code>width</code> and <code>height</code>
        // * and centered at the point <code>(x, y)</code> to the geographic region defined by sector onto .
        // *
        // * @param sector the geographic region the Cartesian region will be mapped to
        // * @param x      x-coordinate of lower left hand corner of the Cartesian region
        // * @param y      y-coordinate of lower left hand corner of the Cartesian region
        // * @param width  width of the Cartesian region, extending to the right from the x-coordinate
        // * @param height height of the Cartesian region, extending up from the y-coordinate
        // *
        // * @return Matrix that will map from Cartesian region to the geographic region.
        // *
        // * @throws IllegalArgumentException if <code>sector</code> is null, or if <code>width</code> or <code>height</code>
        // *                                  are less than zero.
        // */
        //public static Matrix fromViewportToGeographic(Sector sector, int x, int y, int width, int height)
        //{
        //    if (sector == null)
        //    {
        //        String message = "nullValue.SectorIsNull");
        //        Logger.log(Logger.LEVEL_SEVERE, message);
        //        throw new ArgumentError(message);
        //    }
        //
        //    if (width <= 0)
        //    {
        //        String message = "Geom.WidthInvalid", width);
        //        Logger.log(Logger.LEVEL_SEVERE, message);
        //        throw new ArgumentError(message);
        //    }
        //
        //    if (height <= 0)
        //    {
        //        String message = "Geom.HeightInvalid", height);
        //        Logger.log(Logger.LEVEL_SEVERE, message);
        //        throw new ArgumentError(message);
        //    }
        //
        //    Matrix transform = Matrix.IDENTITY;
        //    transform = transform.multiply(
        //        Matrix.fromTranslation(sector.getMinLongitude().degrees, sector.getMinLatitude().degrees, 0.0));
        //    transform = transform.multiply(
        //        Matrix.fromScale(sector.getDeltaLonDegrees() / width, sector.getDeltaLatDegrees() / height, 1.0));
        //    transform = transform.multiply(
        //        Matrix.fromTranslation(x, y, 0.0));
        //
        //    return transform;
        //}

        /**
         * Computes a symmetric covariance Matrix from the x, y, z coordinates of the specified points array. This
         * returns null if the points array is empty, or if all of the points are null.
         * <p/>
         * The returned covariance matrix represents the correlation between each pair of x-, y-, and z-coordinates as
         * they're distributed about the point array's arithmetic mean. Its layout is as follows:
         * <p/>
         * <code> C(x, x)  C(x, y)  C(x, z) <br/> C(x, y)  C(y, y)  C(y, z) <br/> C(x, z)  C(y, z)  C(z, z) </code>
         * <p/>
         * C(i, j) is the covariance of coordinates i and j, where i or j are a coordinate's dispersion about its mean
         * value. If any entry is zero, then there's no correlation between the two coordinates defining that entry. If the
         * returned matrix is diagonal, then all three coordinates are uncorrelated, and the specified point Iterable is
         * distributed evenly about its mean point.
         *
         * @param {Array} points the array of points for which to compute a Covariance matrix.
         *
         * @return {Matrix} the covariance matrix for the iterable of 3D points.
         *
         * @throws ArgumentError
         *      if the points array is not an array.
         */
        Matrix.fromCovarianceOfVertices = function (/* Iterable<? extends Vec3> */ points) {
            var msg;
            if (!(points instanceof Array)) {
                msg = "Matrix.fromCovarianceOfVertices: " + "generic.ArrayExpected - " + "points";
                Logger.log(Logger.LEVEL_SEVERE, msg);
                throw new ArgumentError(msg);
            }

            var mean = Vec3.computeAveragePoint(points);
            if (mean == null) {
                return null;
            }

            var count = 0,
                c11 = 0,
                c22 = 0,
                c33 = 0,
                c12 = 0,
                c13 = 0,
                c23 = 0;

            for (var idx = 0; idx < points.length; idx += 1) {
                var vec = point[idx];

                if (vec == null)
                    continue;

                count++;
                c11 += (vec.x - mean.x) * (vec.x - mean.x);
                c22 += (vec.y - mean.y) * (vec.y - mean.y);
                c33 += (vec.z - mean.z) * (vec.z - mean.z);
                c12 += (vec.x - mean.x) * (vec.y - mean.y); // c12 = c21
                c13 += (vec.x - mean.x) * (vec.z - mean.z); // c13 = c31
                c23 += (vec.y - mean.y) * (vec.z - mean.z); // c23 = c32
            }

            if (count == 0) {
                return null;
            }

            return new Matrix(
                c11 / count, c12 / count, c13 / count, 0,
                c12 / count, c22 / count, c23 / count, 0,
                c13 / count, c23 / count, c33 / count, 0,
                0, 0, 0, 0);
        };

        // TODO: re-enable after dealing with polymorphism
        ///**
        // * Computes a symmetric covariance Matrix from the x, y, z coordinates of the specified buffer of points. This
        // * returns null if the buffer is empty.
        // * <p/>
        // * The returned covariance matrix represents the correlation between each pair of x-, y-, and z-coordinates as
        // * they're distributed about the points arithmetic mean. Its layout is as follows:
        // * <p/>
        // * <code> C(x, x)  C(x, y)  C(x, z) <br/> C(x, y)  C(y, y)  C(y, z) <br/> C(x, z)  C(y, z)  C(z, z) </code>
        // * <p/>
        // * C(i, j) is the covariance of coordinates i and j, where i or j are a coordinate's dispersion about its mean
        // * value. If any entry is zero, then there's no correlation between the two coordinates defining that entry. If the
        // * returned matrix is diagonal, then all three coordinates are uncorrelated, and the specified points are
        // * distributed evenly about their mean point.
        // * <p/>
        // * The buffer must contain XYZ coordinate tuples which are either tightly packed or offset by the specified stride.
        // * The stride specifies the number of buffer elements between the first coordinate of consecutive tuples. For
        // * example, a stride of 3 specifies that each tuple is tightly packed as XYZXYZXYZ, whereas a stride of 5 specifies
        // * that there are two elements between each tuple as XYZabXYZab (the elements "a" and "b" are ignored). The stride
        // * must be at least 3. If the buffer's length is not evenly divisible into stride-sized tuples, this ignores the
        // * remaining elements that follow the last complete tuple.
        // *
        // * @param coordinates the buffer containing the point coordinates for which to compute a Covariance matrix.
        // * @param stride      the number of elements between the first coordinate of consecutive points. If stride is 3,
        // *                    this interprets the buffer has having tightly packed XYZ coordinate tuples.
        // *
        // * @return the covariance matrix for the buffer of points.
        // *
        // * @throws IllegalArgumentException if the buffer is null, or if the stride is less than three.
        // */
        //public static Matrix fromCovarianceOfVertices(BufferWrapper coordinates, int stride)
        //{
        //    if (coordinates == null)
        //    {
        //        msg = "nullValue.CoordinatesAreNull");
        //        Logger.log(Logger.LEVEL_SEVERE, msg);
        //        throw new ArgumentError(msg);
        //    }
        //
        //    if (stride < 3)
        //    {
        //        msg = "generic.StrideIsInvalid");
        //        Logger.log(Logger.LEVEL_SEVERE, msg);
        //        throw new ArgumentError(msg);
        //    }
        //
        //    Vec3 mean = Vec3.computeAveragePoint(coordinates, stride);
        //    if (mean == null)
        //        return null;
        //
        //    int count = 0;
        //    double c11 = 0d;
        //    double c22 = 0d;
        //    double c33 = 0d;
        //    double c12 = 0d;
        //    double c13 = 0d;
        //    double c23 = 0d;
        //
        //    for (int i = 0; i <= coordinates.length() - stride; i += stride)
        //    {
        //        double x = coordinates.getDouble(i);
        //        double y = coordinates.getDouble(i + 1);
        //        double z = coordinates.getDouble(i + 2);
        //        count++;
        //        c11 += (x - mean.x) * (x - mean.x);
        //        c22 += (y - mean.y) * (y - mean.y);
        //        c33 += (z - mean.z) * (z - mean.z);
        //        c12 += (x - mean.x) * (y - mean.y); // c12 = c21
        //        c13 += (x - mean.x) * (z - mean.z); // c13 = c31
        //        c23 += (y - mean.y) * (z - mean.z); // c23 = c32
        //    }
        //
        //    if (count == 0)
        //        return null;
        //
        //    return new Matrix(
        //        c11 / (double) count, c12 / (double) count, c13 / (double) count, 0d,
        //c12 / (double) count, c22 / (double) count, c23 / (double) count, 0d,
        //c13 / (double) count, c23 / (double) count, c33 / (double) count, 0d,
        //    0d, 0d, 0d, 0d);
        //}

        /**
         * Computes the eigensystem of the specified symmetric Matrix's upper 3x3 matrix. If the Matrix's upper 3x3 matrix
         * is not symmetric, this throws an IllegalArgumentException. This writes the eigensystem parameters to the
         * specified arrays <code>outEigenValues</code> and <code>outEigenVectors</code>, placing the eigenvalues in the
         * entries of array <code>outEigenValues</code>, and the corresponding eigenvectors in the entires of array
         * <code>outEigenVectors</code>. These arrays must be non-null, and have length three or greater.
         *
         * @param {Matrix} matrix         the symmetric matrix for which to compute an eigensystem.
         * @param {Array} outEigenvalues  the array which receives the three output eigenvalues.
         * @param {Array} outEigenvectors the array which receives the three output eigenvectors.
         *
         * @throws ArgumentError
         *      if the matrix is a Matrix or is not symmetric,
         *      if the output eigenvalue array is not an Array or has length less than 3, or
         *      if the output eigenvector is not an Array or has length less than 3.
         */
        Matrix.computeEigensystemFromSymmetricMatrix3 = function (/* Matrix */ matrix,
                                                                  /* double[] */ outEigenvalues,
                                                                  /* Vec3[] */ outEigenvectors) {
            var msg;
            if (!(matrix instanceof Matrix)) {
                msg = "Matrix.computeEigensystemFromSymmetricMatrix3: " + "generic.MatrixExpected - " + "matrix";
                Logger.log(Logger.LEVEL_SEVERE, msg);
                throw new ArgumentError(msg);
            }
            if (!(outEigenvalues instanceof Array)) {
                msg = "Matrix.computeEigensystemFromSymmetricMatrix3: " + "generic.ArrayExpected - " + "outEigenvalues";
                Logger.log(Logger.LEVEL_SEVERE, msg);
                throw new ArgumentError(msg);
            }
            if (outEigenvalues.length < 3) {
                msg = "Matrix.computeEigensystemFromSymmetricMatrix3: " + "generic.ArrayInvalidLength - " + "outEigenvalues";
                Logger.log(Logger.LEVEL_SEVERE, msg);
                throw new ArgumentError(msg);
            }
            if (!(outEigenvectors instanceof Array)) {
                msg = "Matrix.computeEigensystemFromSymmetricMatrix3: " + "generic.ArrayExpected - " + "outEigenvectors";
                Logger.log(Logger.LEVEL_SEVERE, msg);
                throw new ArgumentError(msg);
            }
            if (outEigenvectors.length < 3) {
                msg = "Matrix.computeEigensystemFromSymmetricMatrix3: " + "generic.ArrayInvalidLength - " + "outEigenvectors";
                Logger.log(Logger.LEVEL_SEVERE, msg);
                throw new ArgumentError(msg);
            }
            if (matrix.m12 != matrix.m21 || matrix.m13 != matrix.m31 || matrix.m23 != matrix.m32) {
                msg = "Matrix.computeEigensystemFromSymmetricMatrix3: " + "generic.MatrixNotSymmetric - " + matrix.toString();
                Logger.log(Logger.LEVEL_SEVERE, msg);
                throw new ArgumentError(msg);
            }

            // Take from "Mathematics for 3D Game Programming and Computer Graphics, Second Edition" by Eric Lengyel,
            // Listing 14.6 (pages 441-444).

            var EPSILON = 1.0e-10,// NOTE: different from Matrix.EPSILON
                MAX_SWEEPS = 32;

            // Since the Matrix is symmetric, m12=m21, m13=m31, and m23=m32. Therefore we can ignore the values m21, m31,
            // and m32.
            var m11 = matrix.m11,
                m12 = matrix.m12,
                m13 = matrix.m13,
                m22 = matrix.m22,
                m23 = matrix.m23,
                m33 = matrix.m33;

            /* double[][] r = new double[3][3]; */
            /* r[0][0] = r[1][1] = r[2][2] = 1d; */
            var r = [
                [1, 0, 0],
                [0, 1, 0],
                [0, 0, 1]
            ];
            var u,
                u2,
                u2p1,
                t,
                c,
                s,
                i,
                temp;

            for (var a = 0; a < MAX_SWEEPS; a += 1) {
                // Exit if off-diagonal entries small enough
                if ((Math.abs(m12) < EPSILON) && (Math.abs(m13) < EPSILON) && (Math.abs(m23) < EPSILON))
                    break;

                // Annihilate (1,2) entry
                if (m12 != 0) {
                    u = (m22 - m11) * 0.5 / m12;
                    u2 = u * u;
                    u2p1 = u2 + 1;
                    t = (u2p1 != u2) ?
                    ((u < 0) ? -1 : 1) * (Math.sqrt(u2p1) - Math.abs(u)) :
                    0.5 / u;
                    c = 1 / Math.sqrt(t * t + 1);
                    s = c * t;

                    m11 -= t * m12;
                    m22 += t * m12;
                    m12 = 0;

                    temp = c * m13 - s * m23;
                    m23 = s * m13 + c * m23;
                    m13 = temp;

                    for (i = 0; i < 3; i += 1) {
                        temp = c * r[i][0] - s * r[i][1];
                        r[i][1] = s * r[i][0] + c * r[i][1];
                        r[i][0] = temp;
                    }
                }

                // Annihilate (1,3) entry
                if (m13 != 0) {
                    u = (m33 - m11) * 0.5 / m13;
                    u2 = u * u;
                    u2p1 = u2 + 1;
                    t = (u2p1 != u2) ?
                    ((u < 0) ? -1 : 1) * (Math.sqrt(u2p1) - Math.abs(u)) :
                    0.5 / u;
                    c = 1 / Math.sqrt(t * t + 1);
                    s = c * t;

                    m11 -= t * m13;
                    m33 += t * m13;
                    m13 = 0;

                    temp = c * m12 - s * m23;
                    m23 = s * m12 + c * m23;
                    m12 = temp;

                    for (i = 0; i < 3; i += 1) {
                        temp = c * r[i][0] - s * r[i][2];
                        r[i][2] = s * r[i][0] + c * r[i][2];
                        r[i][0] = temp;
                    }
                }

                // Annihilate (2,3) entry
                if (m23 != 0) {
                    u = (m33 - m22) * 0.5 / m23;
                    u2 = u * u;
                    u2p1 = u2 + 1;
                    t = (u2p1 != u2) ?
                    ((u < 0) ? -1 : 1) * (Math.sqrt(u2p1) - Math.abs(u)) :
                    0.5 / u;
                    c = 1 / Math.sqrt(t * t + 1);
                    s = c * t;

                    m22 -= t * m23;
                    m33 += t * m23;
                    m23 = 0;

                    temp = c * m12 - s * m13;
                    m13 = s * m12 + c * m13;
                    m12 = temp;

                    for (i = 0; i < 3; i += 1) {
                        temp = c * r[i][1] - s * r[i][2];
                        r[i][2] = s * r[i][1] + c * r[i][2];
                        r[i][1] = temp;
                    }
                }
            }

            outEigenvalues[0] = m11;
            outEigenvalues[1] = m22;
            outEigenvalues[2] = m33;

            outEigenvectors[0] = new Vec3(r[0][0], r[1][0], r[2][0]);
            outEigenvectors[1] = new Vec3(r[0][1], r[1][1], r[2][1]);
            outEigenvectors[2] = new Vec3(r[0][2], r[1][2], r[2][2]);
        };

        // ============== Arithmetic Functions ======================= //
        // ============== Arithmetic Functions ======================= //
        // ============== Arithmetic Functions ======================= //

        /**
         * Add a matrix to <code>this</code> matrix.
         *
         * @param {Matrix} matrix to add
         * @returns {Matrix} the sum of the matrices
         * @throws ArgumentError
         *      if <code>matrix</code> is not a <code>Matrix</code>
         */
        Matrix.add = function (matrix) {
            var msg;
            if (!(matrix == Matrix)) {
                msg = "Matrix.add: " + "generic.MatrixExpected - " + "matrix";
                Logger.log(Logger.LEVEL_SEVERE, msg);
                throw new ArgumentError(msg);
            }

            return new Matrix(
                this.m11 + matrix.m11, this.m12 + matrix.m12, this.m13 + matrix.m13, this.m14 + matrix.m14,
                this.m21 + matrix.m21, this.m22 + matrix.m22, this.m23 + matrix.m23, this.m24 + matrix.m24,
                this.m31 + matrix.m31, this.m32 + matrix.m32, this.m33 + matrix.m33, this.m34 + matrix.m34,
                this.m41 + matrix.m41, this.m42 + matrix.m42, this.m43 + matrix.m43, this.m44 + matrix.m44);
        };

        /**
         * Subtract a matrix from <code>this</code> matrix.
         *
         * @param {Matrix} matrix matrix to subtract
         * @returns {Matrix} the difference of <code>this</code> and <code>matrix</code>
         * @throws ArgumentError
         *      if matrix is not a <code>Matrix</code>
         */
        Matrix.subtract = function (/* Matrix */ matrix) {
            var msg;
            if (!(matrix instanceof Matrix)) {
                msg = "Matrix.subtract: " + "generic.MatrixExpected - " + "matrix";
                Logger.log(Logger.LEVEL_SEVERE, msg);
                throw new ArgumentError(msg);
            }

            return new Matrix(
                this.m11 - matrix.m11, this.m12 - matrix.m12, this.m13 - matrix.m13, this.m14 - matrix.m14,
                this.m21 - matrix.m21, this.m22 - matrix.m22, this.m23 - matrix.m23, this.m24 - matrix.m24,
                this.m31 - matrix.m31, this.m32 - matrix.m32, this.m33 - matrix.m33, this.m34 - matrix.m34,
                this.m41 - matrix.m41, this.m42 - matrix.m42, this.m43 - matrix.m43, this.m44 - matrix.m44);
        };

        /**
         * Multiply <code>this</code> matrix by a constant factor.
         *
         * @param {Number} value scale factor for matrix
         * @returns {Matrix} <code>this</code> matrix modified in place
         */
        Matrix.prototype.multiplyComponents = function (value) {
            return new Matrix(
                this.m11 * value, this.m12 * value, this.m13 * value, this.m14 * value,
                this.m21 * value, this.m22 * value, this.m23 * value, this.m24 * value,
                this.m31 * value, this.m32 * value, this.m33 * value, this.m34 * value,
                this.m41 * value, this.m42 * value, this.m43 * value, this.m44 * value);
        };

        /**
         * Multiply a matrix to <code>this</code> matrix, modifying <code>this</code> matrix.
         *
         * @param {Matrix} matrix matrix to multiply
         * @returns {Matrix} <code>this</code> matrix modified in place
         * @throws ArgumentError
         *      if matrix is not a <code>Matrix</code>
         */
        Matrix.prototype.multiply = function (/* Matrix */ matrix) {
            var msg;
            if (!(matrix instanceof Matrix)) {
                msg = "Matrix.multiply: " + "generic.MatrixExpected - " + "matrix";
                Logger.log(Logger.LEVEL_SEVERE, msg);
                throw new ArgumentError(msg);
            }

            return new Matrix(
                // Row 1
                (this.m11 * matrix.m11) + (this.m12 * matrix.m21) + (this.m13 * matrix.m31) + (this.m14 * matrix.m41),
                (this.m11 * matrix.m12) + (this.m12 * matrix.m22) + (this.m13 * matrix.m32) + (this.m14 * matrix.m42),
                (this.m11 * matrix.m13) + (this.m12 * matrix.m23) + (this.m13 * matrix.m33) + (this.m14 * matrix.m43),
                (this.m11 * matrix.m14) + (this.m12 * matrix.m24) + (this.m13 * matrix.m34) + (this.m14 * matrix.m44),
                // Row 2
                (this.m21 * matrix.m11) + (this.m22 * matrix.m21) + (this.m23 * matrix.m31) + (this.m24 * matrix.m41),
                (this.m21 * matrix.m12) + (this.m22 * matrix.m22) + (this.m23 * matrix.m32) + (this.m24 * matrix.m42),
                (this.m21 * matrix.m13) + (this.m22 * matrix.m23) + (this.m23 * matrix.m33) + (this.m24 * matrix.m43),
                (this.m21 * matrix.m14) + (this.m22 * matrix.m24) + (this.m23 * matrix.m34) + (this.m24 * matrix.m44),
                // Row 3
                (this.m31 * matrix.m11) + (this.m32 * matrix.m21) + (this.m33 * matrix.m31) + (this.m34 * matrix.m41),
                (this.m31 * matrix.m12) + (this.m32 * matrix.m22) + (this.m33 * matrix.m32) + (this.m34 * matrix.m42),
                (this.m31 * matrix.m13) + (this.m32 * matrix.m23) + (this.m33 * matrix.m33) + (this.m34 * matrix.m43),
                (this.m31 * matrix.m14) + (this.m32 * matrix.m24) + (this.m33 * matrix.m34) + (this.m34 * matrix.m44),
                // Row 4
                (this.m41 * matrix.m11) + (this.m42 * matrix.m21) + (this.m43 * matrix.m31) + (this.m44 * matrix.m41),
                (this.m41 * matrix.m12) + (this.m42 * matrix.m22) + (this.m43 * matrix.m32) + (this.m44 * matrix.m42),
                (this.m41 * matrix.m13) + (this.m42 * matrix.m23) + (this.m43 * matrix.m33) + (this.m44 * matrix.m43),
                (this.m41 * matrix.m14) + (this.m42 * matrix.m24) + (this.m43 * matrix.m34) + (this.m44 * matrix.m44),
                // Product of orthonormal 3D transform matrices is also an orthonormal 3D transform.
                this.isOrthonormalTransform && matrix.isOrthonormalTransform);
        };

        /**
         * Divide <code>this</code> matrix by a constant factor.
         *
         * @param {Number} value divisor for matrix
         * @returns {Matrix} <code>this</code> matrix modified in place
         */
        Matrix.prototype.divideComponents = function (value) {
            var msg;
            if (value == 0) {
                msg = "Matrix.divideComponents: " + "generic.ArgumentOutOfRange - " + "value";
                Logger.log(Logger.LEVEL_SEVERE, msg);
                throw new ArgumentError(msg);
            }

            return new Matrix(
                this.m11 / value, this.m12 / value, this.m13 / value, this.m14 / value,
                this.m21 / value, this.m22 / value, this.m23 / value, this.m24 / value,
                this.m31 / value, this.m32 / value, this.m33 / value, this.m34 / value,
                this.m41 / value, this.m42 / value, this.m43 / value, this.m44 / value);
        };

        /**
         * Component-wise divide the <code>this</code> matrix by another matrix.
         *
         * @param {Matrix} matrix matrix to divide
         * @returns {Matrix} <code>this</code> matrix modified in place
         * @throws ArgumentError
         *      if matrix is not a <code>Matrix</code>
         */
        Matrix.prototype.divide = function (/* Matrix */ matrix) {
            var msg;
            if (!(matrix instanceof Matrix)) {
                msg = "Matrix.divide: " + "generic.MatrixExpected - " + "matrix";
                Logger.log(Logger.LEVEL_SEVERE, msg);
                throw new ArgumentError(msg);
            }

            return new Matrix(
                this.m11 / matrix.m11, this.m12 / matrix.m12, this.m13 / matrix.m13, this.m14 / matrix.m14,
                this.m21 / matrix.m21, this.m22 / matrix.m22, this.m23 / matrix.m23, this.m24 / matrix.m24,
                this.m31 / matrix.m31, this.m32 / matrix.m32, this.m33 / matrix.m33, this.m34 / matrix.m34,
                this.m41 / matrix.m41, this.m42 / matrix.m42, this.m43 / matrix.m43, this.m44 / matrix.m44);
        };

        /**
         * Negate the <code>this</code> matrix.
         *
         * @returns {Matrix} <code>this</code> matrix modified in place
         */
        Matrix.prototype.negate = function () {
            return new Matrix(
                0.0 - this.m11, 0.0 - this.m12, 0.0 - this.m13, 0.0 - this.m14,
                0.0 - this.m21, 0.0 - this.m22, 0.0 - this.m23, 0.0 - this.m24,
                0.0 - this.m31, 0.0 - this.m32, 0.0 - this.m33, 0.0 - this.m34,
                0.0 - this.m41, 0.0 - this.m42, 0.0 - this.m43, 0.0 - this.m44,
                // Negative of orthonormal 3D transform matrix is also an orthonormal 3D transform.
                this.isOrthonormalTransform);
        };

        /**
         * Transform a 3-vector by a transformation matrix. The vector is augmented by an implicit <code>w</code> component,
         * which is assumed to be 1. The resultant 4-vector will also have a <code>w</code> component. A 3-vector is
         * created by dividing the <code>x</code>, <code>y</code>, and <code>z</code> components by the resultant
         * <code>w</code> component.
         *
         * @param {Matrix} matrix transformation matrix
         * @param {Vec3} vec vector to be transformed
         * @returns {Vec3} a transformed vector
         */
        Matrix.transform = function (/* Matrix */ matrix, vec) {
            var msg;
            if (!(matrix instanceof Matrix)) {
                msg = "Matrix.transform: " + "generic.MatrixExpected - " + "matrix";
                Logger.log(Logger.LEVEL_SEVERE, msg);
                throw new ArgumentError(msg);
            }
            if (!(vec instanceof Vec3)) {
                msg = "Matrix.transform: " + "generic.Vec3Expected - " + "vec";
                Logger.log(Logger.LEVEL_SEVERE, msg);
                throw new ArgumentError(msg);
            }

            var x = (matrix.m11 * vec[0]) + (matrix.m12 * vec[1]) + (matrix.m13 * vec[2]) + matrix.m14,
                y = (matrix.m21 * vec[0]) + (matrix.m22 * vec[1]) + (matrix.m23 * vec[2]) + matrix.m24,
                z = (matrix.m31 * vec[0]) + (matrix.m32 * vec[1]) + (matrix.m33 * vec[2]) + matrix.m34,
                w = (matrix.m41 * vec[0]) + (matrix.m42 * vec[1]) + (matrix.m43 * vec[2]) + matrix.m44;

            if (w == 1.0) {
                return new Vec3(x, y, z);
            }
            else if (w != 0) {
                return new Vec3(x / w, y / w, z / w);
            }
            else {
                return null;
            }
        };

        // ============== Matrix Arithmetic Functions ======================= //
        // ============== Matrix Arithmetic Functions ======================= //
        // ============== Matrix Arithmetic Functions ======================= //

        /**
         * Compute the determinant of <code>this</code> matrix.
         *
         * @returns {Number} determinant of <code>this</code> matrix
         */
        Matrix.prototype.getDeterminant = function () {
            var result = 0.0;
            // Columns 2, 3, 4.
            result += this.m11 *
            (this.m22 * (this.m33 * this.m44 - this.m43 * this.m34)
            - this.m23 * (this.m32 * this.m44 - this.m42 * this.m34)
            + this.m24 * (this.m32 * this.m43 - this.m42 * this.m33));
            // Columns 1, 3, 4.
            result -= this.m12 *
            (this.m21 * (this.m33 * this.m44 - this.m43 * this.m34)
            - this.m23 * (this.m31 * this.m44 - this.m41 * this.m34)
            + this.m24 * (this.m31 * this.m43 - this.m41 * this.m33));
            // Columns 1, 2, 4.
            result += this.m13 *
            (this.m21 * (this.m32 * this.m44 - this.m42 * this.m34)
            - this.m22 * (this.m31 * this.m44 - this.m41 * this.m34)
            + this.m24 * (this.m31 * this.m42 - this.m41 * this.m32));
            // Columns 1, 2, 3.
            result -= this.m14 *
            (this.m21 * (this.m32 * this.m43 - this.m42 - this.m33)
            - this.m22 * (this.m31 * this.m43 - this.m41 * this.m33)
            + this.m23 * (this.m31 * this.m42 - this.m41 * this.m32));
            return result;
        };

        /**
         * Create the transpose of <code>this</code> matrix.
         *
         * @returns {Matrix} the transpose of <code>this</code> matrix
         */
        Matrix.prototype.getTranspose = function () {
            // Swap rows with columns.
            return new Matrix(
                this.m11, this.m21, this.m31, this.m41,
                this.m12, this.m22, this.m32, this.m42,
                this.m13, this.m23, this.m33, this.m43,
                this.m14, this.m24, this.m34, this.m44,
                // Transpose of orthonormal 3D transform matrix is not an orthonormal 3D transform matrix.
                false);
        };

        /**
         * Compute the trace (the sum of the diagonals) of <code>this</code> matrix
         * @returns {Number} the trace of <code>this</code> matrix
         */
        Matrix.prototype.getTrace = function () {
            return this.m11 + this.m22 + this.m33 + this.m44;
        };

        /**
         * Returns the inverse of <code>this</code> matrix, or <code>null</code> if <code>this</code> matrix
         * is singular and has no inverse.
         *
         * @return the inverse of <code>this</code> matrix, or <code>null</code> if <code>this</code> matrix has no inverse.
         */
        Matrix.prototype.getInverse = function () {
            if (this.isOrthonormalTransform) {
                return Matrix.computeTransformInverse(this);
            }
            else {
                return Matrix.computeGeneralInverse(this);
            }
        };

        /**
         * Invert a matrix assumed not to translate or project. This assumption is valid only if
         * <code>isOthronormalTransform</code> is <code>true</code>.
         *
         * @param {Matrix} a matrix to invert
         * @returns {Matrix} the inverse of the input
         */
        Matrix.computeTransformInverse = function (/* Matrix */ a) {
            // 'a' is assumed to contain a 3D transformation matrix.
            // Upper-3x3 is inverted, translation is transformed by inverted-upper-3x3 and negated.
            return new Matrix(
                a.m11, a.m21, a.m31, 0.0 - (a.m11 * a.m14) - (a.m21 * a.m24) - (a.m31 * a.m34),
                a.m12, a.m22, a.m32, 0.0 - (a.m12 * a.m14) - (a.m22 * a.m24) - (a.m32 * a.m34),
                a.m13, a.m23, a.m33, 0.0 - (a.m13 * a.m14) - (a.m23 * a.m24) - (a.m33 * a.m34),
                0.0, 0.0, 0.0, 1.0,
                false); // Inverse of an orthogonal, 3D transform matrix is not an orthogonal 3D transform.
        };

        /**
         * Invert an arbitrary 4x4 matrix.
         *
         * @param {Matrix} a matrix to invert
         * @returns {Matrix} the inverse of the input matrix
         */
        Matrix.computeGeneralInverse = function (/* Matrix */ a) {
            // Copy the specified matrix into a mutable two-dimensional array.
            /* double[][] A = new double[4][4]; */
            var A = [[], [], [], []];
            A[0][0] = a.m11;
            A[0][1] = a.m12;
            A[0][2] = a.m13;
            A[0][3] = a.m14;
            A[1][0] = a.m21;
            A[1][1] = a.m22;
            A[1][2] = a.m23;
            A[1][3] = a.m24;
            A[2][0] = a.m31;
            A[2][1] = a.m32;
            A[2][2] = a.m33;
            A[2][3] = a.m34;
            A[3][0] = a.m41;
            A[3][1] = a.m42;
            A[3][2] = a.m43;
            A[3][3] = a.m44;

            /* int[] indx = new int[4]; */
            var indx = [],
                d = ludcmp(A, indx),
                i,
                j;

            // Compute the matrix's determinant.
            for (i = 0; i < 4; i += 1) {
                d *= A[i][i];
            }

            // The matrix is singular if its determinant is zero or very close to zero.
            if (Math.abs(d) < NEAR_ZERO_THRESHOLD)
                return null;

            /* double[][] Y = new double[4][4];*/
            /* double[] col = new double[4];*/
            var Y = [[], [], [], []],
                col = [];
            for (j = 0; j < 4; j += 1) {
                for (i = 0; i < 4; i += 1) {
                    col[i] = 0.0;
                }

                col[j] = 1.0;
                lubksb(A, indx, col);

                for (i = 0; i < 4; i += 1) {
                    Y[i][j] = col[i];
                }
            }

            return new Matrix(
                Y[0][0], Y[0][1], Y[0][2], Y[0][3],
                Y[1][0], Y[1][1], Y[1][2], Y[1][3],
                Y[2][0], Y[2][1], Y[2][2], Y[2][3],
                Y[3][0], Y[3][1], Y[3][2], Y[3][3]);
        };

        /**
         * Utility method to solve a linear system with an LU factorization of a matrix.
         * Solves Ax=b, where A is in LU factorized form.
         * Algorithm derived from "Numerical Recipes in C", Press et al., 1988.
         *
         * @param {Matrix} A an LU factorization of a matrix
         * @param {Array} indx permutation vector of that LU factorization
         * @param {Array} b vector to be solved
         */
        // Method "lubksb" derived from "Numerical Recipes in C", Press et al., 1988
        Matrix.lubksb = function (/* double[][] */ A, /* int[] */ indx, /* double[] */ b) {
            var ii = -1,
                i,
                j,
                sum;
            for (i = 0; i < 4; i += 1) {
                var ip = indx[i];
                sum = b[ip];
                b[ip] = b[i];

                if (ii != -1) {
                    for (j = ii; j <= i - 1; j += 1) {
                        sum -= A[i][j] * b[j];
                    }
                }
                else if (sum != 0.0) {
                    ii = i;
                }

                b[i] = sum;
            }

            for (i = 3; i >= 0; i -= 1) {
                sum = b[i];
                for (j = i + 1; j < 4; j += 1) {
                    sum -= A[i][j] * b[j];
                }

                b[i] = sum / A[i][i];
            }
        };

        /**
         * Utility method to perform an LU factoization of a matrix.
         * "ludcmp" is derived from "Numerical Recipes in C", Press et al., 1988.
         *
         * @param {Matrix} A matix to be factored
         * @param {Array} indx permutation vector
         * @returns {number} Condition number of matrix???
         */
        Matrix.ludcmp = function (/* double[][] */ A, /* int[] */ indx) {
            var TINY = 1.0e-20,
                vv = [], /* new double[4]; */
                d = 1.0,
                temp,
                i,
                j,
                k,
                big,
                sum,
                imax,
                dum;
            for (i = 0; i < 4; i += 1) {
                big = 0.0;
                for (j = 0; j < 4; j += 1) {
                    if ((temp = Math.abs(A[i][j])) > big) {
                        big = temp;
                    }
                }

                if (big == 0.0) {
                    return 0.0; // Matrix is singular if the entire row contains zero.
                }
                else {
                    vv[i] = 1.0 / big;
                }
            }

            for (j = 0; j < 4; j += 1) {
                for (i = 0; i < j; i += 1) {
                    sum = A[i][j];
                    for (k = 0; k < i; k += 1) {
                        sum -= A[i][k] * A[k][j];
                    }

                    A[i][j] = sum;
                }

                big = 0.0;
                imax = -1;
                for (i = j; i < 4; i += 1) {
                    sum = A[i][j];
                    for (k = 0; k < j; k++) {
                        sum -= A[i][k] * A[k][j];
                    }

                    A[i][j] = sum;

                    if ((dum = vv[i] * Math.abs(sum)) >= big) {
                        big = dum;
                        imax = i;
                    }
                }

                if (j != imax) {
                    for (k = 0; k < 4; k += 1) {
                        dum = A[imax][k];
                        A[imax][k] = A[j][k];
                        A[j][k] = dum;
                    }

                    d = -d;
                    vv[imax] = vv[j];
                }

                indx[j] = imax;
                if (A[j][j] == 0.0)
                    A[j][j] = TINY;

                if (j != 3) {
                    dum = 1.0 / A[j][j];
                    for (i = j + 1; i < 4; i += 1) {
                        A[i][j] *= dum;
                    }
                }
            }

            return d;
        };

        // ============== Accessor Functions ======================= //
        // ============== Accessor Functions ======================= //
        // ============== Accessor Functions ======================= //

        /**
         * Compute the x-axis rotation component of <code>this</code> transformation matrix.
         *
         * @returns {Number} the rotation angle about the x axis in degrees.
         */
        Matrix.prototype.getRotationX = function () {
            var yRadians = Math.asin(this.m13),
                cosY = Math.cos(yRadians);
            if (cosY == 0)
                return null;

            var xRadians;
            // No Gimbal lock.
            if (Math.abs(cosY) > 0.005) {
                xRadians = Math.atan2(-this.m23 / cosY, this.m33 / cosY);
            }
            // Gimbal lock has occurred. Rotation around X axis becomes rotation around Z axis.
            else {
                xRadians = 0;
            }

            if (Number.NaN == xRadians) {
                return null;
            }

            return Angle.DEGREES_TO_RADIANS * xRadians;
        };

        /**
         * Compute the y-axis rotation component of <code>this</code> transformation matrix.
         *
         * @returns {Number} the rotation angle about the y axis in degrees.
         */
        Matrix.prototype.getRotationY = function () {
            var yRadians = Math.asin(this.m13);
            if (Number.NaN == yRadians) {
                return null;
            }

            return Angle.DEGREES_TO_RADIANS * yRadians;
        };

        /**
         * Compute the z-axis rotation component of <code>this</code> transformation matrix.
         *
         * @returns {Number} the rotation angle about the z axis in degrees.
         */
        Matrix.prototype.getRotationZ = function () {
            var yRadians = Math.asin(this.m13),
                cosY = Math.cos(yRadians);
            if (cosY == 0) {
                return null;
            }

            var zRadians;
            // No Gimbal lock.
            if (Math.abs(cosY) > 0.005) {
                zRadians = Math.atan2(-this.m12 / cosY, this.m11 / cosY);
            }
            // Gimbal lock has occurred. Rotation around X axis becomes rotation around Z axis.
            else {
                zRadians = Math.atan2(this.m21, this.m22);
            }

            if (Number.NaN == zRadians) {
                return null;
            }

            return Angle.DEGREES_TO_RADIANS * zRadians;
        };

        Matrix.prototype.getKMLRotationX = function () {   // KML assumes the order of rotations is YXZ, positive CW
            var xRadians = Math.asin(-this.m23);
            if (Number.NaN == xRadians) {
                return null;
            }

            return Angle.DEGREES_TO_RADIANS * -xRadians;    // negate to make angle CW
        };

        Matrix.prototype.getKMLRotationY = function () {    // KML assumes the order of rotations is YXZ, positive CW
            var xRadians = Math.asin(-this.m23);
            if (Number.NaN == xRadians) {
                return null;
            }

            var yRadians;
            if (xRadians < Math.PI / 2) {
                if (xRadians > -Math.PI / 2) {
                    yRadians = Math.atan2(this.m13, this.m33);
                }
                else {
                    yRadians = -Math.atan2(-this.m12, this.m11);
                }
            }
            else {
                yRadians = Math.atan2(-this.m12, this.m11);
            }

            if (Number.NaN == yRadians) {
                return null;
            }

            return Angle.DEGREES_TO_RADIANS * -yRadians;    // negate angle to make it CW
        };

        Matrix.prototype.getKMLRotationZ = function () {    // KML assumes the order of rotations is YXZ, positive CW
            var xRadians = Math.asin(-this.m23);
            if (Number.NaN == xRadians) {
                return null;
            }

            var zRadians;
            if (xRadians < Math.PI / 2 && xRadians > -Math.PI / 2) {
                zRadians = Math.atan2(this.m21, this.m22);
            }
            else {
                zRadians = 0;
            }

            if (Number.NaN == zRadians) {
                return null;
            }

            return Angle.DEGREES_TO_RADIANS * -zRadians;    // negate angle to make it CW
        };

        /**
         * Compute the translation component of <code>this</code> transformation matrix.
         *
         * @returns {Vec3} the translation component of the matrix.
         */
        Matrix.prototype.getTranslation = function () {
            return new Vec3(this.m14, this.m24, this.m34);
        };

        /**
         * Extracts this viewing matrix's eye point.
         * <p/>
         * This method assumes that this matrix represents a viewing matrix. If this does not represent a viewing matrix the
         * results are undefined.
         * <p/>
         * In model coordinates, a viewing matrix's eye point is the point the viewer is looking from and maps to the center
         * of the screen.
         *
         * @return {Vec3} this viewing matrix's eye point, in model coordinates.
         */
        Matrix.prototype.extractEyePoint = function () {
            // The eye point of a modelview matrix is computed by transforming the origin (0, 0, 0, 1) by the matrix's
            // inverse. This is equivalent to transforming the inverse of this matrix's translation components in the
            // rightmost column by the transpose of its upper 3x3 components.
            var x = -(this.m11 * this.m14) - (this.m21 * this.m24) - (this.m31 * this.m34);
            var y = -(this.m12 * this.m14) - (this.m22 * this.m24) - (this.m32 * this.m34);
            var z = -(this.m13 * this.m14) - (this.m23 * this.m24) - (this.m33 * this.m34);

            return new Vec3(x, y, z);
        };

        /**
         * Extracts this viewing matrix's forward vector.
         * <p/>
         * This method assumes that this matrix represents a viewing matrix. If this does not represent a viewing matrix the
         * results are undefined.
         * <p/>
         * In model coordinates, a viewing matrix's forward vector is the direction the viewer is looking and maps to a
         * vector going into the screen.
         *
         * @return this viewing matrix's forward vector, in model coordinates.
         */
        Matrix.prototype.extractForwardVector = function () {
            // The forward vector of a modelview matrix is computed by transforming the negative Z axis (0, 0, -1, 0) by the
            // matrix's inverse. We have pre-computed the result inline here to simplify this computation.
            return new Vec3(-this.m31, -this.m32, -this.m33);
        };

        /**
         * Extracts this viewing matrix's parameters given a viewing origin and a globe.
         * <p/>
         * This method assumes that this matrix represents a viewing matrix. If this does not represent a viewing matrix the
         * results are undefined.
         * <p/>
         * This returns a parameterization of this viewing matrix based on the specified origin and globe. The origin
         * indicates the model coordinate point that the view's orientation is relative to, while the globe provides the
         * necessary model coordinate context for the origin and the orientation. The origin should be either the view's eye
         * point or a point on the view's forward vector. The view's roll must be specified in order to disambiguate heading
         * and roll when the view's tilt is zero.
         *
         * The following list outlines the returned key-value pairs and their meanings:
         * <ul>
         * <li>AVKey.ORIGIN - The geographic position corresponding to the origin point.</li>
         * <li>AVKey.RANGE - The distance between the specified origin point and the view's eye point, in model coordinates.</li>
         * <li>AVKey.HEADING - The view's heading angle relative to the globe's north pointing tangent at the origin point.</li>
         * <li>AVKey.TILT - The view's tilt angle relative to the globe's normal vector at the origin point.</li>
         * <li>AVKey.ROLL - The view's roll relative to the globe's normal vector at the origin point.</li>
         * </ul>
         *
         * @param {Vec3} origin the origin of the viewing parameters, in model coordinates.
         * @param {Number} roll   the view's roll in degrees.
         * @param {Globe} globe  the globe the viewer is looking at.
         *
         * @return a parameterization of this viewing matrix as a list of key-value pairs.
         *
         * @throws IllegalArgumentException if arguments are not of correct type.
         */
        Matrix.prototype.extractViewingParameters = function (/* Vec3 */ origin, /* Angle */ roll, /* Globe */ globe) {
            var msg;
            if (!(origin instanceof Vec3)) {
                msg = "Matrix.extractViewingParameters:" + "generic.Vec3Expected - " + "origin";
                Logger.log(Logger.LEVEL_SEVERE, msg);
                throw new ArgumentError(msg);
            }

            if (!(globe instanceof Globe)) {
                msg = "Matrix.extractViewingParameters:" + "generic.GlobeExpected - " + "globe";
                Logger.log(Logger.LEVEL_SEVERE, msg);
                throw new ArgumentError(msg);
            }

            // Transform the modelview matrix to a local coordinate system at the origin. This eliminates the geographic
            // transform contained in the modelview matrix while maintaining rotation and translation relative to the origin.
            var originPos = globe.computePositionFromPoint(origin),
                modelviewLocal = this.multiply(globe.computeModelCoordinateOriginTransform(originPos));

            // Extract the viewing parameters from the transform in local coordinates.
            // TODO: Document how these parameters are extracted. See [WWMatrix extractViewingParameters] in WWiOS.

            var m = modelviewLocal,
                range = -m.m34;

            var ct = m.m33,
                st = Math.sqrt(m.m13 * m.m13 + m.m23 * m.m23),
                tilt = Math.atan2(st, ct);

            var cr = Math.cos(Angle.DEGREES_TO_RADIANS * roll),
                sr = Math.sin(Angle.DEGREES_TO_RADIANS * roll),
                ch = cr * m.m11 - sr * m.m21,
                sh = sr * m.m22 - cr * m.m12,
                heading = Math.atan2(sh, ch);

            var params = new AVListImpl();
            params.setValue(AVKey.ORIGIN, originPos);
            params.setValue(AVKey.RANGE, range);
            params.setValue(AVKey.HEADING, Angle.DEGREES_TO_RADIANS * heading);
            params.setValue(AVKey.TILT, Angle.DEGREES_TO_RADIANS * tilt);
            params.setValue(AVKey.ROLL, roll);

            return params;
        };

        return Matrix;
    });

