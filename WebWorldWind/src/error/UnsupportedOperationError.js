/*
 * Copyright (C) 2014 United States Government as represented by the Administrator of the
 * National Aeronautics and Space Administration. All Rights Reserved.
 */
/**
 * @exports UnsupportedOperationError
 * @version $Id$
 */
define(function () {
    "use strict";

    /**
     * Constructs an unsupported-operation error with a specified message.
     * @alias ArgumentError
     * @constructor
     * @classdesc Represents an error associated with an operation that is not available or should not be invoked.
     * @param {String} message The message.
     */
    var UnsupportedOperationError = function (message) {
        this.name = "UnsupportedOperationError";
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
    UnsupportedOperationError.prototype.toString = function () {
        var str = this.name + ': ' + this.message;

        if (this.stack) {
            str += '\n' + this.stack.toString();
        }

        return str;
    };

    return UnsupportedOperationError;

});