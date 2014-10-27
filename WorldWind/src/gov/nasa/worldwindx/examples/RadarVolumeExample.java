/*
 * Copyright (C) 2014 United States Government as represented by the Administrator of the
 * National Aeronautics and Space Administration.
 * All Rights Reserved.
 */

package gov.nasa.worldwindx.examples;

import gov.nasa.worldwind.WorldWind;
import gov.nasa.worldwind.geom.*;
import gov.nasa.worldwind.globes.Globe;
import gov.nasa.worldwind.layers.*;
import gov.nasa.worldwind.render.*;
import gov.nasa.worldwind.render.markers.*;
import gov.nasa.worldwind.terrain.HighResolutionTerrain;

import javax.swing.*;
import java.util.*;

/**
 * Shows how to compute a radar volume that considers terrain intersection and how to use the {@link
 * gov.nasa.worldwindx.examples.RadarVolume} shape to display the computed volume.
 *
 * @author tag
 * @version $Id$
 */
public class RadarVolumeExample extends ApplicationTemplate
{
    public static class AppFrame extends ApplicationTemplate.AppFrame
    {
        // Use the HighResolutionTerrain class to get accurate terrain for computing the intersections.
        protected HighResolutionTerrain terrain;

        public AppFrame()
        {
            super(true, true, false);

            Position center = Position.fromDegrees(36.8378, -118.8743, 100); // radar location
            Angle startAzimuth = Angle.fromDegrees(135);
            Angle endAzimuth = Angle.fromDegrees(270);
            Angle startElevation = Angle.fromDegrees(0);
            Angle endElevation = Angle.fromDegrees(70);
            double innerRange = 10e3;
            double outerRange = 30e3;
            final int numAz = 25; // number of azimuth samplings
            final int numEl = 25; // number of elevation samplings

            // Initialize the high-resolution terrain class. Construct it to use 100 meter resolution elevations.
            this.terrain = new HighResolutionTerrain(this.getWwd().getModel().getGlobe(), 100d);

            // Compute a near and far grid of positions that will serve as ray endpoints for computing terrain
            // intersections.
            List<Vec4> vertices = this.computeOriginalVertices(center, startAzimuth, endAzimuth, startElevation,
                endElevation, innerRange, outerRange, numAz, numEl);

            // Create geographic positions from the computed Cartesian vertices. The terrain intersector works with
            // geographic positions.
            final List<Position> positions = this.makePositions(vertices);

            // Intersect the rays defined by the radar center and the computed positions with the terrain. Since
            // this is potentially a long-running operation, perform it in a separate thread.
            Thread thread = new Thread(new Runnable()
            {
                @Override
                public void run()
                {
                    long start = System.currentTimeMillis(); // keep track of how long the intersection operation takes
                    final List<Position> intersectionPositions = intersectTerrain(positions);
                    long end = System.currentTimeMillis();
                    System.out.println(end - start);

                    // The computed positions define the radar volume. Set up to show that on the event dispatch thread.
                    SwingUtilities.invokeLater(new Runnable()
                    {
                        @Override
                        public void run()
                        {
                            showRadarVolume(intersectionPositions, numAz, numEl);
                            getWwd().redraw();
                        }
                    });
                }
            });
            thread.start();

            // Show the radar source as a marker.
            MarkerLayer markerLayer = new MarkerLayer();
            markerLayer.setKeepSeparated(false);
            MarkerAttributes markerAttributes = new BasicMarkerAttributes();
            ArrayList<Marker> markers = new ArrayList<Marker>();
            markerLayer.setMarkers(markers);
            markers.add(new BasicMarker(positions.get(0), markerAttributes));
            insertAfterPlacenames(getWwd(), markerLayer);
        }

        List<Vec4> computeOriginalVertices(Position center, Angle leftAzimuth, Angle rightAzimuth, Angle lowerElevation,
            Angle upperElevation, double innerRange, double outerRange, int numAzimuths, int numElevations)
        {
            // Compute the vertices at the Cartesian origin then transform them to the radar position and
            // orientation.

            List<Vec4> vertices = new ArrayList<Vec4>();
            vertices.add(Vec4.ZERO); // the first vertex is the radar position.

            double dAz = (rightAzimuth.radians - leftAzimuth.radians) / (numAzimuths - 1);
            double dEl = (upperElevation.radians - lowerElevation.radians) / (numElevations - 1);

            // Compute the grid for the inner range.
            for (int iel = 0; iel < numElevations; iel++)
            {
                double elevation = lowerElevation.radians + iel * dEl;

                for (int iaz = 0; iaz < numAzimuths; iaz++)
                {
                    double azimuth = leftAzimuth.radians + iaz * dAz;

                    double x = innerRange * Math.sin(azimuth) * Math.cos(elevation);
                    double y = innerRange * Math.cos(azimuth) * Math.cos(elevation);
                    double z = innerRange * Math.sin(elevation);

                    vertices.add(new Vec4(x, y, z));
                }
            }

            // Compute the grid for the outer range.
            for (int iel = 0; iel < numElevations; iel++)
            {
                double elevation = lowerElevation.radians + iel * dEl;

                for (int iaz = 0; iaz < numAzimuths; iaz++)
                {
                    double azimuth = leftAzimuth.radians + iaz * dAz;

                    double x = outerRange * Math.sin(azimuth) * Math.cos(elevation);
                    double y = outerRange * Math.cos(azimuth) * Math.cos(elevation);
                    double z = outerRange * Math.sin(elevation);

                    vertices.add(new Vec4(x, y, z));
                }
            }

            // The vertices are computed relative to the origin. Transform them to the radar position and orientation.
            return this.transformVerticesToPosition(center, vertices);
        }

        List<Vec4> transformVerticesToPosition(Position position, List<Vec4> vertices)
        {
            // Transforms the incoming origin-centered vertices to the radar position and orientation.

            List<Vec4> transformedVertices = new ArrayList<Vec4>(vertices.size());

            // Create the transformation matrix that performs the transform.
            Matrix transform = this.getWwd().getModel().getGlobe().computeEllipsoidalOrientationAtPosition(
                position.getLatitude(), position.getLongitude(),
                this.terrain.getElevation(position) + position.getAltitude());

            for (Vec4 vertex : vertices)
            {
                transformedVertices.add(vertex.transformBy4(transform));
            }

            return transformedVertices;
        }

        List<Position> intersectTerrain(List<Position> positions)
        {
            // Perform the intersection tests with the terrain.

            List<Position> intersectPositions = new ArrayList<Position>(positions.size());

            Position origin = positions.get(0); // this is the radar position

            for (int i = 1; i < positions.size(); i++)
            {
                Position position = positions.get(i);
                Intersection[] intersections = this.terrain.intersect(origin, position, WorldWind.ABSOLUTE);
                if (intersections == null || intersections.length == 0)
                {
                    // No intersection so just use the grid position.
                    intersectPositions.add(position);
                }
                else
                {
                    // An intersection with the terrain occurred so contract this ray to the radar position.
                    intersectPositions.add(origin);
                }
            }

            return intersectPositions;
        }

        List<Position> makePositions(List<Vec4> vertices)
        {
            // Convert the Cartesian vertices to geographic positions.

            List<Position> positions = new ArrayList<Position>(vertices.size());

            Globe globe = this.getWwd().getModel().getGlobe();

            for (Vec4 vertex : vertices)
            {
                positions.add(globe.computePositionFromEllipsoidalPoint(vertex));
            }

            return positions;
        }

        void showRadarVolume(List<Position> positions, int numAz, int numEl)
        {
            RenderableLayer layer = new RenderableLayer();

            // Set the volume's attributes.
            ShapeAttributes attributes = new BasicShapeAttributes();
            attributes.setDrawOutline(false);
            attributes.setDrawInterior(true);
            attributes.setOutlineMaterial(Material.RED);
            attributes.setInteriorMaterial(Material.WHITE);
            attributes.setEnableLighting(true);
            attributes.setInteriorOpacity(0.8);

            // Create the volume and add it to the model.
            RadarVolume volume = new RadarVolume(positions, numAz, numEl);
            volume.setAttributes(attributes);
            layer.addRenderable(volume);

            // Create two paths to show their interaction with the radar volume. The first path goes through most
            // of the volume. The second path goes mostly under the volume.

            Path path = new Path(Position.fromDegrees(36.9843, -119.4464, 20e3),
                Position.fromDegrees(36.4630, -118.3595, 20e3));
            ShapeAttributes pathAttributes = new BasicShapeAttributes();
            pathAttributes.setOutlineMaterial(Material.RED);
            path.setAttributes(pathAttributes);
            layer.addRenderable(path);

            path = new Path(Position.fromDegrees(36.9843, -119.4464, 5e3),
                Position.fromDegrees(36.4630, -118.3595, 5e3));
            path.setAttributes(pathAttributes);
            layer.addRenderable(path);

            insertAfterPlacenames(getWwd(), layer);
        }
    }

    public static void main(String[] args)
    {
        ApplicationTemplate.start("Terrain Shadow Prototype", AppFrame.class);
    }
}
