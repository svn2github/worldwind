/*
 * Copyright (C) 2014 United States Government as represented by the Administrator of the
 * National Aeronautics and Space Administration.
 * All Rights Reserved.
 */

package gov.nasa.worldwind.util;

import gov.nasa.worldwind.geom.*;
import gov.nasa.worldwind.globes.*;
import gov.nasa.worldwind.terrain.*;
import junit.framework.*;
import junit.textui.TestRunner;

import java.util.*;

/**
 * @author tag
 * @version $Id$
 */
public class HighResolutionTerrainTest
{
    public static class Tests extends TestCase
    {
        protected static ArrayList<Position> generateReferenceLocations(Sector sector, int numLats, int numLons)
       {
           int decimalPlaces = 5;
           ArrayList<Position> locations = new ArrayList<Position>();
           double dLat = (sector.getMaxLatitude().degrees - sector.getMinLatitude().degrees) / (numLats - 1);
           double dLon = (sector.getMaxLongitude().degrees - sector.getMinLongitude().degrees) / (numLons - 1);

           Position p0 = Position.fromDegrees(
               round(decimalPlaces, sector.getMinLatitude().degrees),
               round(decimalPlaces, sector.getMinLongitude().degrees), 0);
           for (int j = 1; j < numLats; j++)
           {
               double lat = sector.getMinLatitude().degrees + j * dLat;

               for (int i = 0; i < numLons; i++)
               {
                   double lon = sector.getMinLongitude().degrees + i * dLon;

                   locations.add(p0);
                   locations.add(Position.fromDegrees(round(decimalPlaces, lat), round(decimalPlaces, lon), 0));
               }
           }

           return locations;
       }

        protected static double round(int decimalPlaces, double value)
        {
            double scale = Math.pow(10, decimalPlaces);
            return Math.round(value * scale) / scale;
        }

        public void testConsistency()
        {
            Sector sector = Sector.boundingSector(
                Position.fromDegrees(34.42391, -119.75557),
                Position.fromDegrees(34.51959, -119.63282));

            ArrayList<Position> referencePositions = generateReferenceLocations(sector, 10, 10);

            final HashMap<Position, Intersection[]> currentIntersections = new HashMap<>();
            final HashMap<Position, Intersection[]> previousIntersections = new HashMap<>();

            Globe globe = new Earth();
            CompoundElevationModel cem = (CompoundElevationModel) globe.getElevationModel();
            cem.addElevationModel(EllipsoidalGlobe.makeElevationModel(
                "", "config/Earth/EarthMergedElevationModel.xml"));

            for (int i = 0; i < 5; i++)
            {
                System.out.print("PASS " + i);
                long start = System.currentTimeMillis();
                HighResolutionTerrain hrt = new HighResolutionTerrain(globe, sector, null, 1.0);
                try
                {
                    hrt.intersect(referencePositions, new HighResolutionTerrain.IntersectionCallback()
                    {
                        @Override
                        public void intersection(Position pA, Position pB, Intersection[] intersections)
                        {
                            currentIntersections.put(pB, intersections);
                        }
                    });
                }
                catch (InterruptedException e)
                {
                    e.printStackTrace();
                }
                System.out.println(" " + (System.currentTimeMillis() - start) + " ms" );

                if (previousIntersections.size() > 0)
                {
                    int item = -1;
                    for (Position position : currentIntersections.keySet())
                    {
                        ++item;
                        Intersection[] currentIntersection = currentIntersections.get(position);
                        Intersection[] previousIntersection = previousIntersections.get(position);
                        if (currentIntersection.length != previousIntersection.length)
                        {
                            String msg = "Different number of intersections: " + item + ", "
                                + currentIntersection.length + ", " + previousIntersection.length + ", " + position;
                            assertTrue(msg, currentIntersection.length == previousIntersection.length);
                        }


                        for (int j = 0; j < currentIntersection.length; j++)
                        {
                            if (!currentIntersection[j].equals(previousIntersection[j]))
                            {
                                String msg = "Different intersection points: " + j + ", "
                                    + currentIntersection[j] + ", " + previousIntersection[j] + ", " + position;
                                assertTrue(msg, currentIntersection[j].equals(previousIntersection[j]));
                            }
                        }
                    }
                }

                previousIntersections.clear();
                previousIntersections.putAll(currentIntersections);
                currentIntersections.clear();
            }
        }
    }

    public static void main(String[] args)
    {
        new TestRunner().doRun(new TestSuite(Tests.class));
    }
}
