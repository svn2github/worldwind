/*
 * Copyright (C) 2014 United States Government as represented by the Administrator of the
 * National Aeronautics and Space Administration. All Rights Reserved.
 */
/**
 * @exports AbstractError
 * @version $Id$
 */
define(function () {
    "use strict";

    /**
     * Constructs an error with a specified message. This is an abstract class and not meant to be
     * instantiated directly.
     * @alias AbstractError
     * @constructor
     * @abstract
     * @classdesc Provides an abstract base class for error classes.
     * @param {String} name The error's name.
     * @param {String} message The message.
     */
    var AbstractError = function (name, message) {
        this.name = name;
        this.message = message;
    };

    /**
     * Returns the message and stack trace associated with this error.
     * @returns {string} The message and stack trace associated with this error.
     */
    AbstractError.prototype.toString = function () {
        var str = this.name + ': ' + this.message;

        if (this.stack) {
            str += '\n' + this.stack.toString();
        }

        return str;
    };

    return AbstractError;

});