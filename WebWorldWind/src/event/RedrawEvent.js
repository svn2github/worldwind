/*
 * Copyright (C) 2014 United States Government as represented by the Administrator of the
 * National Aeronautics and Space Administration. All Rights Reserved.
 */
/**
 * @exports RedrawEvent
 * @version $Id$
 */
define(function () {
    "use strict";

    /**
     * Constructs a redraw event.
     * @alias RedrawEvent
     * @constructor
     * @augments CustomEvent
     * @classdesc Provides an event that requests a redraw of the World Window.
     */
    var RedrawEvent = function () {
        CustomEvent.call(this, "WorldWindRedraw");
    };

    RedrawEvent.prototype = Object.create(CustomEvent.prototype);

    /**
     * The name of the redraw event.
     * @type {string}
     * @constant
     */
    RedrawEvent.EVENT_TYPE = "WorldWindRedraw";

    return RedrawEvent;
});