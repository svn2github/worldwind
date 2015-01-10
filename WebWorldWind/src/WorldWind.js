/*
 * Copyright (C) 2014 United States Government as represented by the Administrator of the
 * National Aeronautics and Space Administration. All Rights Reserved.
 */
/**
 * @version $Id$
 */
define([ // PLEASE KEEP ALL THIS IN ALPHABETICAL ORDER BY MODULE NAME (not directory name).
        './error/AbstractError',
        './geom/Angle',
        './error/ArgumentError',
        './shaders/BasicProgram',
        './layer/BingWMSLayer',
        './layer/BMNGLandsatLayer',
        './layer/BMNGLayer',
        './layer/BMNGOneImageLayer',
        './layer/BMNGRestLayer',
        './geom/BoundingBox',
        './util/Color',
        './render/DrawContext',
        './globe/ElevationModel',
        './util/FrameStatistics',
        './geom/Frustum',
        './navigate/GestureRecognizer',
        './globe/Globe',
        './shaders/GpuProgram',
        './cache/GpuResourceCache',
        './shaders/GpuShader',
        './layer/Layer',
        './util/Level',
        './util/LevelRowColumnUrlBuilder',
        './util/LevelSet',
        './geom/Line',
        './geom/Location',
        './util/Logger',
        './navigate/LookAtNavigator',
        './geom/Matrix',
        './cache/MemoryCache',
        './cache/MemoryCacheListener',
        './navigate/Navigator',
        './navigate/NavigatorState',
        './error/NotYetImplementedError',
        './navigate/PanGestureRecognizer',
        './geom/Plane',
        './geom/Position',
        './geom/Rectangle',
        './render/Renderable',
        './layer/RenderableLayer',
        './geom/Sector',
        './layer/ShowTessellationLayer',
        './shapes/SurfaceImage',
        './render/SurfaceTile',
        './render/SurfaceTileRenderer',
        './shaders/SurfaceTileRendererProgram',
        './globe/Terrain',
        './globe/TerrainTile',
        './globe/TerrainTileList',
        './globe/Tessellator',
        './render/Texture',
        './render/TextureTile',
        './util/Tile',
        './layer/TiledImageLayer',
        './util/TileFactory',
        './error/UnsupportedOperationError',
        './geom/Vec2',
        './geom/Vec3',
        './util/WmsUrlBuilder',
        './WorldWindow',
        './util/WWMath',
        './util/WWUtil',
        './globe/ZeroElevationModel'],
    function (AbstractError,
              Angle,
              ArgumentError,
              BasicProgram,
              BingWMSLayer,
              BMNGLandsatLayer,
              BMNGLayer,
              BMNGOneImageLayer,
              BMNGRestLayer,
              BoundingBox,
              Color,
              DrawContext,
              ElevationModel,
              FrameStatistics,
              Frustum,
              GestureRecognizer,
              Globe,
              GpuProgram,
              GpuResourceCache,
              GpuShader,
              Layer,
              Level,
              LevelRowColumnUrlBuilder,
              LevelSet,
              Line,
              Location,
              Logger,
              LookAtNavigator,
              Matrix,
              MemoryCache,
              MemoryCacheListener,
              Navigator,
              NavigatorState,
              NotYetImplementedError,
              PanGestureRecognizer,
              Plane,
              Position,
              Rectangle,
              Renderable,
              RenderableLayer,
              Sector,
              ShowTessellationLayer,
              SurfaceImage,
              SurfaceTile,
              SurfaceTileRenderer,
              SurfaceTileRendererProgram,
              Terrain,
              TerrainTile,
              TerrainTileList,
              Tessellator,
              Texture,
              TextureTile,
              Tile,
              TiledImageLayer,
              TileFactory,
              UnsupportedOperationError,
              Vec2,
              Vec3,
              WmsUrlBuilder,
              WorldWindow,
              WWMath,
              WWUtil,
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

            // PLEASE KEEP THE ENTRIES BELOW IN ALPHABETICAL ORDER
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
             * Indicates a GPU program resource.
             */
            GPU_PROGRAM: "gpuProgram",

            /**
             * Indicates a GPU texture resource.
             */
            GPU_TEXTURE: "gpuTexture",

            /**
             * Indicates a GPU buffer resource.
             */
            GPU_BUFFER: "gpuBuffer",

            /**
             * Indicates a great circle path.
             * @constant
             */
            GREAT_CIRCLE: "greatCircle",

            /**
             * Indicates a linear, straight line path.
             * @constant
             */
            LINEAR: "linear",

            /**
             * The event name of World Wind redraw events.
             */
            REDRAW_EVENT_TYPE: "WorldWindRedraw",

            /**
             * Indicates an altitude mode relative to the terrain.
             * @constant
             */
            RELATIVE_TO_GROUND: "relativeToGround",

            /**
             * Indicates a rhumb path -- a path of constant bearing.
             * @constant
             */
            RHUMB_LINE: "rhumbLine"
        };

        WorldWind['AbstractError'] = AbstractError;
        WorldWind['Angle'] = Angle;
        WorldWind['ArgumentError'] = ArgumentError;
        WorldWind['BasicProgram'] = BasicProgram;
        WorldWind['BingWMSLayer'] = BingWMSLayer;
        WorldWind['BMNGLandsatLayer'] = BMNGLandsatLayer;
        WorldWind['BMNGLayer'] = BMNGLayer;
        WorldWind['BMNGOneImageLayer'] = BMNGOneImageLayer;
        WorldWind['BMNGRestLayer'] = BMNGRestLayer;
        WorldWind['BoundingBox'] = BoundingBox;
        WorldWind['Color'] = Color;
        WorldWind['DrawContext'] = DrawContext;
        WorldWind['ElevationModel'] = ElevationModel;
        WorldWind['FrameStatistics'] = FrameStatistics;
        WorldWind['Frustum'] = Frustum;
        WorldWind['GestureRecognizer'] = GestureRecognizer;
        WorldWind['Globe'] = Globe;
        WorldWind['GpuProgram'] = GpuProgram;
        WorldWind['GpuResourceCache'] = GpuResourceCache;
        WorldWind['GpuShader'] = GpuShader;
        WorldWind['Layer'] = Layer;
        WorldWind['Level'] = Level;
        WorldWind['LevelRowColumnUrlBuilder'] = LevelRowColumnUrlBuilder;
        WorldWind['LevelSet'] = LevelSet;
        WorldWind['Line'] = Line;
        WorldWind['Location'] = Location;
        WorldWind['Logger'] = Logger;
        WorldWind['LookAtNavigator'] = LookAtNavigator;
        WorldWind['Matrix'] = Matrix;
        WorldWind['MemoryCache'] = MemoryCache;
        WorldWind['MemoryCacheListener'] = MemoryCacheListener;
        WorldWind['Navigator'] = Navigator;
        WorldWind['NavigatorState'] = NavigatorState;
        WorldWind['NotYetImplementedError'] = NotYetImplementedError;
        WorldWind['PanGestureRecognizer'] = PanGestureRecognizer;
        WorldWind['Plane'] = Plane;
        WorldWind['Position'] = Position;
        WorldWind['Rectangle'] = Rectangle;
        WorldWind['Renderable'] = Renderable;
        WorldWind['RenderableLayer'] = RenderableLayer;
        WorldWind['Sector'] = Sector;
        WorldWind['ShowTessellationLayer'] = ShowTessellationLayer;
        WorldWind['SurfaceImage'] = SurfaceImage;
        WorldWind['SurfaceTile'] = SurfaceTile;
        WorldWind['SurfaceTileRenderer'] = SurfaceTileRenderer;
        WorldWind['SurfaceTileRendererProgram'] = SurfaceTileRendererProgram;
        WorldWind['Terrain'] = Terrain;
        WorldWind['TerrainTile'] = TerrainTile;
        WorldWind['TerrainTileList'] = TerrainTileList;
        WorldWind['Tessellator'] = Tessellator;
        WorldWind['Texture'] = Texture;
        WorldWind['TextureTile'] = TextureTile;
        WorldWind['Tile'] = Tile;
        WorldWind['TiledImageLayer'] = TiledImageLayer;
        WorldWind['TileFactory'] = TileFactory;
        WorldWind['UnsupportedOperationError'] = UnsupportedOperationError;
        WorldWind['Vec2'] = Vec2;
        WorldWind['Vec3'] = Vec3;
        WorldWind['WmsUrlBuilder'] = WmsUrlBuilder;
        WorldWind['WWMath'] = WWMath;
        WorldWind['WWUtil'] = WWUtil;
        WorldWind['WorldWindow'] = WorldWindow;
        WorldWind['ZeroElevationModel'] = ZeroElevationModel;

        WorldWind.configuration = {};

        window.WorldWind = WorldWind;

        return WorldWind;
    }
)
;