/*
 * Copyright (C) 2014 United States Government as represented by the Administrator of the
 * National Aeronautics and Space Administration.
 * All Rights Reserved.
 */

package gov.nasa.worldwind.ogc.wcs;

import gov.nasa.worldwind.avlist.*;
import gov.nasa.worldwind.geom.Sector;
import gov.nasa.worldwind.ogc.wcs.wcs100.*;
import gov.nasa.worldwind.terrain.WCSElevationModel;
import junit.framework.*;
import junit.textui.TestRunner;

import javax.xml.stream.XMLStreamException;

/**
 * @author tag
 * @version $Id$
 */
public class WCSElevationModelCreationTest
{
    public static class Tests extends TestCase
    {
        public void test001()
        {
            WCS100Capabilities caps = new WCS100Capabilities("testData/WCS/WCSCapabilities003.xml");
            WCS100DescribeCoverage coverage = new WCS100DescribeCoverage("testData/WCS/WCSDescribeCoverage001.xml");

            try
            {
                caps.parse();
                coverage.parse();
            }
            catch (XMLStreamException e)
            {
                e.printStackTrace();
            }

            AVList params = new AVListImpl();
            params.setValue(AVKey.DOCUMENT, coverage);
            WCSElevationModel elevationModel = new WCSElevationModel(caps, params);

            assertEquals("Incorrect number of levels", 5, elevationModel.getLevels().getNumLevels());
            double bestResolution = elevationModel.getBestResolution(Sector.FULL_SPHERE) * 180.0 / Math.PI;
            assertTrue("Incorrect best resolution", bestResolution > 0.0083 && bestResolution < 0.0084);

            assertEquals("Min elevation incorrect", -11000.0, elevationModel.getMinElevation());
            assertEquals("Max elevation incorrect", 8850.0, elevationModel.getMaxElevation());

            assertEquals("Incorrect dataset name", "WW:NASA_SRTM30_900m_Tiled",
                elevationModel.getLevels().getFirstLevel().getDataset());
            assertEquals("Incorrect format suffix", ".tif",
                elevationModel.getLevels().getFirstLevel().getFormatSuffix());
            assertEquals("Incorrect format suffix", "worldwind26.arc.nasa.gov/_wms2/WW_NASA_SRTM30_900m_Tiled",
                elevationModel.getLevels().getFirstLevel().getCacheName());
        }
    }

    public static void main(String[] args)
    {
        new TestRunner().doRun(new TestSuite(Tests.class));
    }
}
