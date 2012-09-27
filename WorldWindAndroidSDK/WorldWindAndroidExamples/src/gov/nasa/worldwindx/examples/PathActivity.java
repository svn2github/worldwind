/* Copyright (C) 2001, 2012 United States Government as represented by 
the Administrator of the National Aeronautics and Space Administration. 
All Rights Reserved.
*/
package gov.nasa.worldwindx.examples;

import android.os.Bundle;
import gov.nasa.worldwind.avlist.AVKey;
import gov.nasa.worldwind.geom.Position;
import gov.nasa.worldwind.layers.RenderableLayer;
import gov.nasa.worldwind.render.*;

import java.util.*;

/**
 * Example of World Wind {@link Path} shape usage. A path is a line or curve between positions. The path may follow
 * terrain, and may be turned into a curtain by extruding the path to the ground.
 *
 * @author dcollins
 * @version $Id$
 */
public class PathActivity extends BasicWorldWindActivity
{
    @Override
    public void onCreate(Bundle savedInstanceState)
    {
        super.onCreate(savedInstanceState);

        RenderableLayer layer = new RenderableLayer();

        // Create a path that uses all default values.
        List<Position> pathPositions = Arrays.asList(
            Position.fromDegrees(28, -110, 1e4),
            Position.fromDegrees(35, -108, 1e4));
        Path path = new Path(pathPositions);
        layer.addRenderable(path);

        // Create a path, set some of its properties and set its attributes.
        pathPositions = Arrays.asList(
            Position.fromDegrees(28, -108, 1e4),
            Position.fromDegrees(35, -106, 1e4));
        path = new Path(pathPositions);
        path.setAltitudeMode(AVKey.RELATIVE_TO_GROUND);
        path.setPathType(AVKey.GREAT_CIRCLE);
        ShapeAttributes attrs = new BasicShapeAttributes();
        attrs.setOutlineColor(Color.randomColor());
        attrs.setOutlineWidth(4);
        path.setAttributes(attrs);
        layer.addRenderable(path);

        // Create a path with more than two positions that is extruded to display a curtain.
        pathPositions = Arrays.asList(
            Position.fromDegrees(28, -106, 4e4),
            Position.fromDegrees(35, -104, 4e4),
            Position.fromDegrees(35, -102, 4e4),
            Position.fromDegrees(28, -104, 4e4));
        path = new Path(pathPositions);
        path.setAltitudeMode(AVKey.ABSOLUTE);
        path.setPathType(AVKey.GREAT_CIRCLE);
        path.setExtrude(true);
        attrs = new BasicShapeAttributes();
        attrs.setOutlineColor(Color.randomColor());
        attrs.setInteriorColor(Color.randomColor());
        attrs.setOutlineWidth(4);
        path.setAttributes(attrs);
        layer.addRenderable(path);

        this.wwd.getModel().getLayers().add(layer);
    }
}
