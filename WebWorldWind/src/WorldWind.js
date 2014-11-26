/*
 * Copyright (C) 2014 United States Government as represented by the Administrator of the
 * National Aeronautics and Space Administration. All Rights Reserved.
 */
/**
 * @version $Id$
 */
define([ // KEEP ALL THIS IN ALPHABETICAL ORDER.
        'src/geom/Angle',
        'src/error/ArgumentError',
        'src/globe/Globe',
        'src/globe/ElevationModel',
        'src/geom/Location',
        'src/util/Logger',
        'src/geom/Matrix',
        'src/geom/Position',
        'src/geom/Sector',
        'src/geom/Vec2',
        'src/geom/Vec3',
        'src/WorldWindow',
        'src/util/WWMath',
        'src/globe/ZeroElevationModel'],
    function (Angle,
              ArgumentError,
              Globe,
              ElevationModel,
              Location,
              Logger,
              Matrix,
              Position,
              Sector,
              Vec2,
              Vec3,
              WorldWindow,
              WWMath,
              ZeroElevationModel) {
        "use strict";
        /**
         * This is the top-level World Wind module. It is global.
         * @exports WorldWind
         * @global
         */
        var WorldWind = {
            /**
             * The World Wind version number.
             * @default "0.0.0"
             * @constant
             */
            VERSION: "0.0.0",

            /**
             * Indicates a great circle path.
             * @constant
             */
            GREAT_CIRCLE: "greatCircle",
            /**
             * Indicates a rhumb path -- a path of constant bearing.
             * @constant
             */
            RHUMB_LINE: "rhumbLine",
            /**
             * Indicates a linear, straight line path.
             * @constant
             */
            LINEAR: "linear"
        };

        WorldWind['ArgumentError'] = ArgumentError;
        WorldWind['Globe'] = Globe;
        WorldWind['Location'] = Location;
        WorldWind['Logger'] = Logger;
        WorldWind['Matrix'] = Matrix;
        WorldWind['Position'] = Position;
        WorldWind['Sector'] = Sector;
        WorldWind['Vec2'] = Vec2;
        WorldWind['Vec3'] = Vec3;
        WorldWind['WWMath'] = WWMath;
        WorldWind['WorldWindow'] = WorldWindow;
        WorldWind['ZeroElevationModel'] = ZeroElevationModel;

        window.WorldWind = WorldWind;

        return WorldWind;
    }
)
;