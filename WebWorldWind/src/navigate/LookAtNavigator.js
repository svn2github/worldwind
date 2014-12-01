/*
 * Copyright (C) 2014 United States Government as represented by the Administrator of the
 * National Aeronautics and Space Administration. All Rights Reserved.
 */
/**
 * @exports LookAtNavigator
 * @version $Id$
 */
define([
        'src/util/Logger',
        'src/navigate/NavigatorState'
    ],
    function (Logger,
              NavigatorState) {
        "use strict";

        var LookAtNavigator = function () {
        };

        LookAtNavigator.prototype.currentState = function () {
            return new NavigatorState();
        };

        return LookAtNavigator;
    });