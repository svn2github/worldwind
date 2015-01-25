/*
 * Copyright (C) 2014 United States Government as represented by the Administrator of the
 * National Aeronautics and Space Administration. All Rights Reserved.
 */
/**
 * @exports PickSupport
 * @version $Id$
 */
define([],
    function () {
        "use strict";

        /**
         * Constructs a pick-support object.
         * @alias PickSupport
         * @constructor
         * @classdesc Provides methods to assist in picking.
         */
        var PickSupport = function () {
            this.pickableObjects = {};
        };

        /**
         * Adds an object to this list.
         * @param {PickedObject} pickableObject The object to add.
         */
        PickSupport.prototype.addPickableObject = function (pickableObject) {
            this.pickableObjects[pickableObject.color.toByteString()] = pickableObject;
        };

        // Internal. Intentionally not documented.
        PickSupport.prototype.topObject = function (dc, pickPoint) {
            if (Object.keys(this.pickableObjects).length === 0) {
                return null;
            }

            var color = dc.readPickColor(pickPoint);
            if (!color) { // getPickColor returns null if the pick point selects the clear color
                return null;
            }

            return this.pickableObjects[color.toByteString()];
        };

        /**
         * Returns the top-most object in this instance's list of pickable objects as determined be reading the
         * pick color from the frame buffer and identifying the pickable object associated with that color.
         * This method should be called after all picked objects have been added to this pick-support instance.
         * This method clears the current list of pickable objects.
         * @param {DrawContext} dc The current draw context.
         * @returns {PickedObject} The top-most picked object, or null if none is found.
         */
        PickSupport.prototype.resolvePick = function (dc) {
            var pickedObject = this.topObject(dc, dc.pickPoint);

            if (pickedObject) {
                dc.addPickedObject(pickedObject);
            }

            this.pickableObjects = []; // clear the pick list to avoid dangling references

            return pickedObject;
        };

        return PickSupport;
    });