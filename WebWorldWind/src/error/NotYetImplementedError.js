/*
 * Copyright (C) 2014 United States Government as represented by the Administrator of the
 * National Aeronautics and Space Administration. All Rights Reserved.
 */
/**
 * @exports NotYetImplementedError
 * @version $Id$
 */
define(function () {
    "use strict";

    /**
     * Constructs an not-yet-implemented error with a specified message.
     * @alias ArgumentError
     * @constructor
     * @classdesc Represents an error associated with an operation that is not yet implemented.
     * @param {String} message The message.
     */
    var NotYetImplementedError = function (message) {
        this.name = "NotYetImplementedError";
        this.message = message;

        var stack;
        try {
            //noinspection ExceptionCaughtLocallyJS
            throw new Error();
        } catch (e) {
            stack = e.stack;
        }
        this.stack = stack;
    };

    /**
     * Returns the message and stack trace associated with this error.
     * @returns {string} The message and stack trace associated with this error.
     */
    NotYetImplementedError.prototype.toString = function () {
        var str = this.name + ': ' + this.message;

        if (this.stack) {
            str += '\n' + this.stack.toString();
        }

        return str;
    };

    return NotYetImplementedError;

});