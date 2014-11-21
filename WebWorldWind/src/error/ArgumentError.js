/*
 * Copyright (C) 2014 United States Government as represented by the Administrator of the
 * National Aeronautics and Space Administration. All Rights Reserved.
 */
/**
 * @version $Id$
 */
define(function () {
    "use strict";

    var ArgumentError = function(message) {
        this.name = "ArgumentError";
        this.message = message;

        var stack;
        try {
            throw new Error();
        } catch (e) {
            stack = e.stack;
        }
        this.stack = stack;
    };

    ArgumentError.prototype.toString = function() {
        var str = this.name + ': ' + this.message;

        if (this.stack) {
            str += '\n' + this.stack.toString();
        }

        return str;
    };

    return ArgumentError;

});