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
        './shaders/BasicTextureProgram',
        './layer/BingWMSLayer',
        './layer/BMNGLandsatLayer',
        './layer/BMNGLayer',
        './layer/BMNGOneImageLayer',
        './layer/BMNGRestLayer',
        './geom/BoundingBox',
        './util/Color',
        './render/DrawContext',
        './globe/EarthElevationModel',
        './globe/EarthRestElevationModel',
        './globe/ElevationModel',
        './util/Font',
        './util/FrameStatistics',
        './geom/Frustum',
        './gesture/GestureRecognizer',
        './globe/Globe',
        './shaders/GpuProgram',
        './cache/GpuResourceCache',
        './shaders/GpuShader',
        './layer/LandsatRestLayer',
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
        './util/Offset',
        './gesture/PanGestureRecognizer',
        './pick/PickedObject',
        './pick/PickedObjectList',
        './pick/PickSupport',
        './gesture/PinchGestureRecognizer',
        './shapes/Placemark',
        './shapes/PlacemarkAttributes',
        './layer/PlacenameLayer',
        './geom/Plane',
        './geom/Position',
        './geom/Rectangle',
        './render/Renderable',
        './layer/RenderableLayer',
        './gesture/RotationGestureRecognizer',
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
        './render/UserFacingText',
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
              BasicTextureProgram,
              BingWMSLayer,
              BMNGLandsatLayer,
              BMNGLayer,
              BMNGOneImageLayer,
              BMNGRestLayer,
              BoundingBox,
              Color,
              DrawContext,
              EarthElevationModel,
              EarthRestElevationModel,
              ElevationModel,
              Font,
              FrameStatistics,
              Frustum,
              GestureRecognizer,
              Globe,
              GpuProgram,
              GpuResourceCache,
              GpuShader,
              LandsatRestLayer,
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
              Offset,
              PanGestureRecognizer,
              PickedObject,
              PickedObjectList,
              PickSupport,
              PinchGestureRecognizer,
              Placemark,
              PlacemarkAttributes,
              PlacenameLayer,
              Plane,
              Position,
              Rectangle,
              Renderable,
              RenderableLayer,
              RotationGestureRecognizer,
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
              UserFacingText,
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
             * Indicates that the associated parameters are fractional values of the virtual rectangle's width or
             * height in the range [0, 1], where 0 indicates the rectangle's origin and 1 indicates the corner
             * opposite its origin.
             * @constant
             */
            OFFSET_FRACTION: "fraction",

            /**
             * Indicates that the associated parameters are in units of pixels relative to the virtual rectangle's
             * corner opposite its origin corner.
             * @constant
             */
            OFFSET_INSET_PIXELS: "insetPixels",

            /**
             * Indicates that the associated parameters are in units of pixels relative to the virtual rectangle's
             * origin.
             * @constant
             */
            OFFSET_PIXELS: "pixels",

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
        WorldWind['BasicTextureProgram'] = BasicTextureProgram;
        WorldWind['BingWMSLayer'] = BingWMSLayer;
        WorldWind['BMNGLandsatLayer'] = BMNGLandsatLayer;
        WorldWind['BMNGLayer'] = BMNGLayer;
        WorldWind['BMNGOneImageLayer'] = BMNGOneImageLayer;
        WorldWind['BMNGRestLayer'] = BMNGRestLayer;
        WorldWind['BoundingBox'] = BoundingBox;
        WorldWind['Color'] = Color;
        WorldWind['DrawContext'] = DrawContext;
        WorldWind['EarthElevationModel'] = EarthElevationModel;
        WorldWind['EarthRestElevationModel'] = EarthRestElevationModel;
        WorldWind['ElevationModel'] = ElevationModel;
        WorldWind['Font'] = Font;
        WorldWind['FrameStatistics'] = FrameStatistics;
        WorldWind['Frustum'] = Frustum;
        WorldWind['GestureRecognizer'] = GestureRecognizer;
        WorldWind['Globe'] = Globe;
        WorldWind['GpuProgram'] = GpuProgram;
        WorldWind['GpuResourceCache'] = GpuResourceCache;
        WorldWind['GpuShader'] = GpuShader;
        WorldWind['LandsatRestLayer'] = LandsatRestLayer;
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
        WorldWind['Offset'] = Offset;
        WorldWind['PanGestureRecognizer'] = PanGestureRecognizer;
        WorldWind['PickedObject'] = PickedObject;
        WorldWind['PickedObjectList'] = PickedObjectList;
        WorldWind['PickSupport'] = PickSupport;
        WorldWind['PinchGestureRecognizer'] = PinchGestureRecognizer;
        WorldWind['Placemark'] = Placemark;
        WorldWind['PlacemarkAttributes'] = PlacemarkAttributes;
        WorldWind['PlacenameLayer'] = PlacenameLayer;
        WorldWind['Plane'] = Plane;
        WorldWind['Position'] = Position;
        WorldWind['Rectangle'] = Rectangle;
        WorldWind['Renderable'] = Renderable;
        WorldWind['RenderableLayer'] = RenderableLayer;
        WorldWind['RotationGestureRecognizer'] = RotationGestureRecognizer;
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
        WorldWind['UserFaceingText'] = UserFacingText;
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