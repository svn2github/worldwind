/*
 * Copyright (C) 2014 United States Government as represented by the Administrator of the
 * National Aeronautics and Space Administration. All Rights Reserved.
 */
/**
 * @version $Id$
 */
define([ // KEEP ALL THIS IN ALPHABETICAL ORDER.
        './geom/Angle',
        './geom/BoundingBox',
        './error/ArgumentError',
        './render/DrawContext',
        './globe/ElevationModel',
        './util/FrameStatistics',
        './geom/Frustum',
        './globe/Globe',
        './shaders/GpuProgram',
        './render/GpuResourceCache',
        './layer/Layer',
        './Layer/LayerList',
        './util/Level',
        './util/LevelSet',
        './geom/Line',
        './geom/Location',
        './util/Logger',
        './navigate/LookAtNavigator',
        './geom/Matrix',
        './cache/MemoryCache',
        './cache/MemoryCacheListener',
        './navigate/NavigatorState',
        './error/NotYetImplementedError',
        './geom/Plane',
        './geom/Position',
        './geom/Rectangle',
        './geom/Sector',
        './render/SurfaceTile',
        './render/SurfaceTileRenderer',
        './globe/Terrain',
        './globe/TerrainTile',
        './globe/TerrainTileList',
        './globe/Tessellator',
        './render/Texture',
        './util/Tile',
        './util/TileFactory',
        './error/UnsupportedOperationError',
        './geom/Vec2',
        './geom/Vec3',
        './WorldWindow',
        './util/WWMath',
        './globe/ZeroElevationModel'],
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
              TerrainTileList,
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
        WorldWind['TerrainTileList'] = TerrainTileList;
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