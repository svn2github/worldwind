/*
 * Copyright (C) 2014 United States Government as represented by the Administrator of the
 * National Aeronautics and Space Administration. All Rights Reserved.
 */
/**
 * @version $Id$
 */
define([ // KEEP ALL THIS IN ALPHABETICAL ORDER.
        'src/geom/Angle',
        'src/geom/BoundingBox',
        'src/error/ArgumentError',
        'src/render/DrawContext',
        'src/globe/ElevationModel',
        'src/util/FrameStatistics',
        'src/geom/Frustum',
        'src/globe/Globe',
        'src/shaders/GpuProgram',
        'src/render/GpuResourceCache',
        'src/layer/Layer',
        'src/Layer/LayerList',
        'src/util/Level',
        'src/util/LevelSet',
        'src/geom/Line',
        'src/geom/Location',
        'src/util/Logger',
        'src/navigate/LookAtNavigator',
        'src/geom/Matrix',
        'src/cache/MemoryCache',
        'src/cache/MemoryCacheListener',
        'src/navigate/NavigatorState',
        'src/error/NotYetImplementedError',
        'src/geom/Plane',
        'src/geom/Position',
        'src/geom/Rectangle',
        'src/geom/Sector',
        'src/render/SurfaceTile',
        'src/render/SurfaceTileRenderer',
        'src/globe/Terrain',
        'src/globe/TerrainTile',
        'src/globe/Tessellator',
        'src/render/Texture',
        'src/util/Tile',
        'src/util/TileFactory',
        'src/error/UnsupportedOperationError',
        'src/geom/Vec2',
        'src/geom/Vec3',
        'src/WorldWindow',
        'src/util/WWMath',
        'src/globe/ZeroElevationModel'],
    function (Angle,
              ArgumentError,
              BoundingBox,
              DrawContext,
              ElevationModel,
              FrameStatistics,
              Frustum,
              Globe,
              GpuProgram,
              GpuResourceCache,
              Layer,
              LayerList,
              Level,
              LevelSet,
              Line,
              Location,
              Logger,
              LookAtNavigator,
              Matrix,
              MemoryCache,
              MemoryCacheListener,
              NavigatorState,
              NotYetImplementedError,
              Plane,
              Position,
              Rectangle,
              Sector,
              SurfaceTile,
              SurfaceTileRenderer,
              Terrain,
              TerrainTile,
              Tessellator,
              Texture,
              Tile,
              TileFactory,
              UnsupportedOperationError,
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
        WorldWind['BoundingBox'] = BoundingBox;
        WorldWind['DrawContext'] = DrawContext;
        WorldWind['ElevationModel'] = ElevationModel;
        WorldWind['FrameStatistics'] = FrameStatistics;
        WorldWind['Frustum'] = Frustum;
        WorldWind['Globe'] = Globe;
        WorldWind['GpuProgram'] = GpuProgram;
        WorldWind['GpuResourceCache'] = GpuResourceCache;
        WorldWind['Layer'] = Layer;
        WorldWind['LayerList'] = LayerList;
        WorldWind['Level'] = Level;
        WorldWind['LevelSet'] = LevelSet;
        WorldWind['Line'] = Line;
        WorldWind['Location'] = Location;
        WorldWind['Logger'] = Logger;
        WorldWind['LookAtNavigator'] = LookAtNavigator;
        WorldWind['Matrix'] = Matrix;
        WorldWind['MemoryCache'] = MemoryCache;
        WorldWind['MemoryCacheListener'] = MemoryCacheListener;
        WorldWind['NavigatorState'] = NavigatorState;
        WorldWind['NotYetImplementedError'] = NotYetImplementedError;
        WorldWind['Plane'] = Plane;
        WorldWind['Position'] = Position;
        WorldWind['Rectangle'] = Rectangle;
        WorldWind['Sector'] = Sector;
        WorldWind['SurfaceTile'] = SurfaceTile;
        WorldWind['SurfaceTileRenderer'] = SurfaceTileRenderer;
        WorldWind['Terrain'] = Terrain;
        WorldWind['TerrainTile'] = TerrainTile;
        WorldWind['Tessellator'] = Tessellator;
        WorldWind['Texture'] = Texture;
        WorldWind['Tile'] = Tile;
        WorldWind['TileFactory'] = TileFactory;
        WorldWind['UnsupportedOperationError'] = UnsupportedOperationError;
        WorldWind['Vec2'] = Vec2;
        WorldWind['Vec3'] = Vec3;
        WorldWind['WWMath'] = WWMath;
        WorldWind['WorldWindow'] = WorldWindow;
        WorldWind['ZeroElevationModel'] = ZeroElevationModel;

        WorldWind.configuration = {
        };

        window.WorldWind = WorldWind;

        return WorldWind;
    }
)
;