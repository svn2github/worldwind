/*
 * Copyright (C) 2014 United States Government as represented by the Administrator of the
 * National Aeronautics and Space Administration.
 * All Rights Reserved.
 */

package gov.nasa.worldwindx.examples;

import gov.nasa.worldwind.WorldWind;
import gov.nasa.worldwind.avlist.AVKey;
import gov.nasa.worldwind.event.*;
import gov.nasa.worldwind.geom.*;
import gov.nasa.worldwind.layers.*;
import gov.nasa.worldwind.pick.PickedObject;
import gov.nasa.worldwind.render.*;
import gov.nasa.worldwind.render.airspaces.*;
import gov.nasa.worldwind.render.airspaces.Polygon;
import gov.nasa.worldwind.render.markers.*;
import gov.nasa.worldwind.util.AirspaceEditor;

import java.awt.*;
import java.util.ArrayList;

/**
 * @author tag
 * @version $Id$
 */
public class AirspaceEditing extends ApplicationTemplate
{
    public static class AppFrame extends ApplicationTemplate.AppFrame implements SelectListener
    {
        protected AirspaceEditor editor;
        protected Airspace lastHighlightAirspace;
        protected AirspaceAttributes lastAttrs;

        public AppFrame()
        {
            this.getWwd().addSelectListener(this);

            RenderableLayer layer = new RenderableLayer();

            AirspaceAttributes attrs = new BasicAirspaceAttributes();
            attrs.setDrawInterior(true);
            attrs.setDrawOutline(true);
            attrs.setInteriorMaterial(new Material(Color.WHITE));
            attrs.setOutlineMaterial(new Material(Color.BLACK));
            attrs.setOutlineWidth(2);

            java.util.List<LatLon> locations = new ArrayList<LatLon>();
            locations.add(LatLon.fromDegrees(40, -121));
            locations.add(LatLon.fromDegrees(40, -120));
            locations.add(LatLon.fromDegrees(41, -120));
            locations.add(LatLon.fromDegrees(41, -121));
            Polygon polygon = new Polygon(locations);
            polygon.setAttributes(attrs);
            polygon.setAltitudes(1e4, 2e4);
            polygon.setAltitudeDatum(AVKey.ABOVE_GROUND_LEVEL, AVKey.ABOVE_GROUND_LEVEL);
            layer.addRenderable(polygon);

            CappedCylinder cylinder = new CappedCylinder(LatLon.fromDegrees(40.5, -118), 5e4);
            cylinder.setAttributes(attrs);
            cylinder.setAltitudeDatum(AVKey.ABOVE_GROUND_LEVEL, AVKey.ABOVE_GROUND_LEVEL);
            cylinder.setAltitudes(1e4, 2e4);
            layer.addRenderable(cylinder);

            cylinder = new CappedCylinder(LatLon.fromDegrees(40.5, -116), 5e4);
            cylinder.setRadii(3e4, 5e4);
            cylinder.setAttributes(attrs);
            cylinder.setAltitudeDatum(AVKey.ABOVE_GROUND_LEVEL, AVKey.ABOVE_GROUND_LEVEL);
            cylinder.setAltitudes(1e4, 2e4);
            layer.addRenderable(cylinder);

            Orbit orbit = new Orbit(LatLon.fromDegrees(40, -114), LatLon.fromDegrees(41, -114), Orbit.OrbitType.CENTER,
                4e4);
            orbit.setAttributes(attrs);
            orbit.setAltitudeDatum(AVKey.ABOVE_GROUND_LEVEL, AVKey.ABOVE_GROUND_LEVEL);
            orbit.setAltitudes(1e4, 2e4);
            layer.addRenderable(orbit);

            locations = new ArrayList<LatLon>();
            locations.add(LatLon.fromDegrees(40, -113));
            locations.add(LatLon.fromDegrees(41, -112));
            locations.add(LatLon.fromDegrees(41, -111));
            locations.add(LatLon.fromDegrees(40, -112));
            Route route = new Route(locations, 4e4);
            route.setAttributes(attrs);
            route.setAltitudes(1e4, 2e4);
            route.setAltitudeDatum(AVKey.ABOVE_GROUND_LEVEL, AVKey.ABOVE_GROUND_LEVEL);
            layer.addRenderable(route);

            locations = new ArrayList<LatLon>();
            locations.add(LatLon.fromDegrees(40, -110));
            locations.add(LatLon.fromDegrees(41, -110));
            locations.add(LatLon.fromDegrees(41, -109));
            locations.add(LatLon.fromDegrees(40, -109));
            Curtain curtain = new Curtain(locations);
            curtain.setAttributes(attrs);
            curtain.setAltitudes(1e4, 2e4);
            curtain.setAltitudeDatum(AVKey.ABOVE_GROUND_LEVEL, AVKey.ABOVE_GROUND_LEVEL);
            layer.addRenderable(curtain);

            SphereAirspace sphere = new SphereAirspace(LatLon.fromDegrees(40.5, -107), 5e4);
            sphere.setAttributes(attrs);
            sphere.setAltitudeDatum(AVKey.ABOVE_GROUND_LEVEL, AVKey.ABOVE_GROUND_LEVEL);
            sphere.setAltitudes(1e4, 2e4);
            layer.addRenderable(sphere);

            PartialCappedCylinder partialCylinder = new PartialCappedCylinder(LatLon.fromDegrees(40.5, -105), 5e4);
            partialCylinder.setAzimuths(Angle.fromDegrees(270), Angle.fromDegrees(90));
            partialCylinder.setRadii(3e4, 5e4);
            partialCylinder.setAttributes(attrs);
            partialCylinder.setAltitudeDatum(AVKey.ABOVE_GROUND_LEVEL, AVKey.ABOVE_GROUND_LEVEL);
            partialCylinder.setAltitudes(1e4, 2e4);
            layer.addRenderable(partialCylinder);

            TrackAirspace track = new TrackAirspace();
            track.addLeg(LatLon.fromDegrees(40, -103), LatLon.fromDegrees(41, -103), 1e4, 2e4, 2e4, 2e4);
            track.addLeg(LatLon.fromDegrees(41, -103), LatLon.fromDegrees(41, -102), 1e4, 2e4, 2e4, 2e4);
            track.addLeg(LatLon.fromDegrees(41, -102), LatLon.fromDegrees(40, -102), 1e4, 2e4, 2e4, 2e4);
            track.addLeg(LatLon.fromDegrees(39.5, -102), LatLon.fromDegrees(39.5, -103), 1e4, 2e4, 2e4, 2e4);
            track.setAttributes(attrs);
            track.setAltitudeDatum(AVKey.ABOVE_GROUND_LEVEL, AVKey.ABOVE_GROUND_LEVEL);
            track.setAltitudes(1e4, 2e4);
            layer.addRenderable(track);

            java.util.List<Marker> markers = new ArrayList<Marker>(1);
            markers.add(new BasicMarker(Position.fromDegrees(90, 0), new BasicMarkerAttributes()));
            MarkerLayer markerLayer = new MarkerLayer();
            markerLayer.setMarkers(markers);
            insertBeforeCompass(getWwd(), markerLayer);

            java.util.List<Position> positions = new ArrayList<Position>(2);
            positions.add(Position.fromDegrees(-90, 180));
            positions.add(Position.fromDegrees(90, 180));
            Path antiMeridian = new Path(positions);
            antiMeridian.setFollowTerrain(true);
            antiMeridian.setAltitudeMode(WorldWind.CLAMP_TO_GROUND);
            ShapeAttributes shapeAttributes = new BasicShapeAttributes();
            shapeAttributes.setOutlineMaterial(Material.WHITE);
            antiMeridian.setAttributes(shapeAttributes);
            antiMeridian.setHighlightAttributes(shapeAttributes);
            layer.addRenderable(antiMeridian);

            insertBeforePlacenames(getWwd(), layer);
        }

        @Override
        public void selected(SelectEvent event)
        {
            PickedObject topObject = event.getTopPickedObject();

            if (event.getEventAction().equals(SelectEvent.ROLLOVER))
            {
                this.highlight(event.getTopObject());
            }
            else if (event.getEventAction().equals(SelectEvent.LEFT_CLICK))
            {
                if (topObject != null && topObject.getObject() instanceof Airspace)
                {
                    if (this.editor == null)
                    {
                        // Enable editing of the selected shape.
                        this.editor = new AirspaceEditor(getWwd(), (Airspace) topObject.getObject());
                        this.editor.setArmed(true);
                        event.consume();
                    }
                    else if (this.editor.getAirspace() != event.getTopObject())
                    {
                        // Switch editor to a different shape.
                        this.editor.setArmed(false);
                        this.editor = new AirspaceEditor(getWwd(), (Airspace) topObject.getObject());
                        this.editor.setArmed(true);
                        event.consume();
                    }
                    else
                    {
                        // Disable editing of the current shape.
                        this.editor.setArmed(false);
                        this.editor = null;
                        event.consume();
                    }
                }
            }
        }

        protected void highlight(Object o)
        {
            if (this.lastHighlightAirspace == o)
                return; // Same thing selected

            // Turn off highlight if on.
            if (this.lastHighlightAirspace != null)
            {
                this.lastHighlightAirspace.setAttributes(this.lastAttrs);
                this.lastHighlightAirspace = null;
                this.lastAttrs = null;
            }

            // Turn on highlight if selected object is a SurfaceImage.
            if (o instanceof Airspace)
            {
                this.lastHighlightAirspace = (Airspace) o;
                this.lastAttrs = this.lastHighlightAirspace.getAttributes();
                BasicAirspaceAttributes highlightAttrs = new BasicAirspaceAttributes(this.lastAttrs);
                highlightAttrs.setOutlineMaterial(Material.RED);
                this.lastHighlightAirspace.setAttributes(highlightAttrs);
            }
        }
    }

    public static void main(String[] args)
    {
        ApplicationTemplate.start("World Wind Airspace Editing", AirspaceEditing.AppFrame.class);
    }
}
