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
        './layer/BMNGOneImageLayer',
        './geom/BoundingBox',
        './util/Color',
        './render/DrawContext',
        './globe/ElevationModel',
        './util/FrameStatistics',
        './geom/Frustum',
        './globe/Globe',
        './shaders/GpuProgram',
        './cache/GpuResourceCache',
        './shaders/GpuShader',
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
        './navigate/Navigator',
        './navigate/NavigatorState',
        './error/NotYetImplementedError',
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
        './util/Tile',
        './util/TileFactory',
        './error/UnsupportedOperationError',
        './geom/Vec2',
        './geom/Vec3',
        './WorldWindow',
        './util/WWMath',
        './globe/ZeroElevationModel'],
    function (AbstractError,
              Angle,
              ArgumentError,
              BasicProgram,
              BMNGOneImageLayer,
              BoundingBox,
              Color,
              DrawContext,
              ElevationModel,
              FrameStatistics,
              Frustum,
              Globe,
              GpuProgram,
              GpuResourceCache,
              GpuShader,
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
              Navigator,
              NavigatorState,
              NotYetImplementedError,
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
        WorldWind['BMNGOneImageLayer'] = BMNGOneImageLayer;
        WorldWind['BoundingBox'] = BoundingBox;
        WorldWind['Color'] = Color;
        WorldWind['DrawContext'] = DrawContext;
        WorldWind['ElevationModel'] = ElevationModel;
        WorldWind['FrameStatistics'] = FrameStatistics;
        WorldWind['Frustum'] = Frustum;
        WorldWind['Globe'] = Globe;
        WorldWind['GpuProgram'] = GpuProgram;
        WorldWind['GpuResourceCache'] = GpuResourceCache;
        WorldWind['GpuShader'] = GpuShader;
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
        WorldWind['Navigator'] = Navigator;
        WorldWind['NavigatorState'] = NavigatorState;
        WorldWind['NotYetImplementedError'] = NotYetImplementedError;
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
        WorldWind['Tile'] = Tile;
        WorldWind['TileFactory'] = TileFactory;
        WorldWind['UnsupportedOperationError'] = UnsupportedOperationError;
        WorldWind['Vec2'] = Vec2;
        WorldWind['Vec3'] = Vec3;
        WorldWind['WWMath'] = WWMath;
        WorldWind['WorldWindow'] = WorldWindow;
        WorldWind['ZeroElevationModel'] = ZeroElevationModel;

        WorldWind.configuration = {};

        window.WorldWind = WorldWind;

        return WorldWind;
    }
)
;