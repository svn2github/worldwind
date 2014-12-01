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
        'src/render/DrawContext',
        'src/globe/ElevationModel',
        'src/util/FrameStatistics',
        'src/geom/Frustum',
        'src/globe/Globe',
        'src/render/GpuProgram',
        'src/render/GpuResourceCache',
        'src/layer/Layer',
        'src/Layer/LayerList',
        'src/geom/Line',
        'src/geom/Location',
        'src/util/Logger',
        'src/geom/Matrix',
        'src/navigate/NavigatorState',
        'src/geom/Plane',
        'src/geom/Position',
        'src/geom/Rectangle',
        'src/geom/Sector',
        'src/render/SurfaceTileRenderer',
        'src/globe/Terrain',
        'src/globe/Tessellator',
        'src/render/Texture',
        'src/geom/Vec2',
        'src/geom/Vec3',
        'src/WorldWindow',
        'src/util/WWMath',
        'src/globe/ZeroElevationModel'],
    function (Angle,
              ArgumentError,
              DrawContext,
              ElevationModel,
              FrameStatistics,
              Frustum,
              Globe,
              GpuProgram,
              GpuResourceCache,
              Layer,
              LayerList,
              Line,
              Location,
              Logger,
              Matrix,
              NavigatorState,
              Plane,
              Position,
              Rectangle,
              Sector,
              SurfaceTileRenderer,
              Terrain,
              Tessellator,
              Texture,
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
            LINEAR: "linear",

            /**
             * Indicates an altitude mode relative to the globe's ellipsoid.
             * @constant
             */
            ABSOLUTE: "absolute",

            /**
             * Indicates an altitude mode always on the terrain.
             * @constant
             */
            CLAMP_TO_GROUND: "clampToGround",

            /**
             * Indicates an altitude mode relative to the terrain.
             * @constant
             */
            RELATIVE_TO_GROUND: "relativeToGround"
        };

        WorldWind['Angle'] = Angle;
        WorldWind['ArgumentError'] = ArgumentError;
        WorldWind['DrawContext'] = DrawContext;
        WorldWind['ElevationModel'] = ElevationModel;
        WorldWind['FrameStatistics'] = FrameStatistics;
        WorldWind['Frustum'] = Frustum;
        WorldWind['Globe'] = Globe;
        WorldWind['GpuProgram'] = GpuProgram;
        WorldWind['GpuResourceCache'] = GpuResourceCache;
        WorldWind['Layer'] = Layer;
        WorldWind['LayerList'] = LayerList;
        WorldWind['Line'] = Line;
        WorldWind['Location'] = Location;
        WorldWind['Logger'] = Logger;
        WorldWind['Matrix'] = Matrix;
        WorldWind['NavigatorState'] = NavigatorState;
        WorldWind['Plane'] = Plane;
        WorldWind['Position'] = Position;
        WorldWind['Rectangle'] = Rectangle;
        WorldWind['Sector'] = Sector;
        WorldWind['SurfaceTileRenderer'] = SurfaceTileRenderer;
        WorldWind['Terrain'] = Terrain;
        WorldWind['Tessellator'] = Tessellator;
        WorldWind['Texture'] = Texture;
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