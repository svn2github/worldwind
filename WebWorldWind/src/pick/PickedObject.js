/*
 * Copyright (C) 2014 United States Government as represented by the Administrator of the
 * National Aeronautics and Space Administration. All Rights Reserved.
 */
/**
 * @exports PickedObject
 * @version $Id$
 */
define([],
    function () {
        "use strict";

        /**
         * Constructs a picked object.
         * @alias PickedObject
         * @constructor
         * @classdesc Represents a picked object.
         * @param {Color} color The color identifying the object.
         * @param {Vec2} pickPoint The pick point.
         * @param {Object} userObject An optional object to associate with this picked object.
         * @param {Position} position The picked object's geographic position.
         * @param {Layer} parentLayer The layer containing the picked object.
         * @param {Boolean} isTerrain <code>true</code> if the picked object is terrain, otherwise
         * <code>false</code>.
         */
        var PickedObject = function (color, pickPoint, userObject, position, parentLayer, isTerrain) {

            /**
             * This picked object's pick color.
             * @type {Number}
             */
            this.color = color;

            /**
             * The pick point used to select this picked object.
             * @type {Vec2}
             */
            this.pickPoint = pickPoint;

            /**
             * An optional object associated with this picked object.
             * @type {Object}
             */
            this.userObject = userObject;

            /**
             * This picked object's geographic position.
             * @type {Position}
             */
            this.position = position;

            /**
             * The layer containing this picked object.
             * @type {Layer}
             */
            this.parentLayer = parentLayer;

            /**
             * Indicates whether this picked object is terrain.
             * @type {Boolean}
             */
            this.isTerrain = isTerrain;

            /**
             * Indicates whether this picked object is the top object.
             * @type {boolean}
             */
            this.isOnTop = false;
        };

        return PickedObject;
    });