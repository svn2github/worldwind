/*
 * Copyright (C) 2014 United States Government as represented by the Administrator of the
 * National Aeronautics and Space Administration.
 * All Rights Reserved.
 */

package gov.nasa.worldwind.ogc.wcs;

import gov.nasa.worldwind.ogc.ows.*;
import junit.framework.*;
import junit.textui.TestRunner;

import javax.xml.stream.XMLStreamException;
import java.util.*;

/**
 * @author tag
 * @version $Id$
 */
public class WCSCapabilitiesParsingTest
{
    public static class Tests extends TestCase
    {
        public void testParsing001()
        {
            WCSCapabilities caps = new WCSCapabilities("testData/WCS/WCSCapabilities001.xml");

            try
            {
                caps.parse();
            }
            catch (XMLStreamException e)
            {
                e.printStackTrace();
            }

            assertNotNull("Version is null", caps.getVersion());
            assertEquals("Incorrect version number", "1.1.1", caps.getVersion());
            assertEquals("Incorrect update sequence", "99", caps.getUpdateSequence());

            OWSServiceIdentification serviceIdentification = caps.getServiceIdentification();
            assertNotNull("Service Identification is null", serviceIdentification);
            assertEquals("Incorrect Fees", "NONE", serviceIdentification.getFees());
            assertEquals("Incorrect ServiceType", "WCS", serviceIdentification.getServiceType());

            Set<String> titles = serviceIdentification.getTitles();
            assertTrue("Titles is null", titles != null);
            assertEquals("Incorrect Title count", 1, titles.size());
            for (String title : titles)
            {
                assertEquals("Incorrect Title", "Web Coverage Service", title);
            }

            Set<String> abstracts = serviceIdentification.getAbstracts();
            assertTrue("Abstracts is null", abstracts != null);
            assertEquals("Incorrect Abstract count", 1, abstracts.size());
            for (String abs : abstracts)
            {
                assertTrue("Incorrect Abstract start", abs.startsWith("This server implements"));
                assertTrue("Incorrect Abstract end", abs.endsWith("available on WMS also."));
            }

            Set<String> keywords = serviceIdentification.getKeywords();
            assertTrue("Keywords is null", keywords != null);
            assertEquals("Incorrect Keyword count", 3, keywords.size());
            assertTrue("Missing Keyword", keywords.contains("WCS"));
            assertTrue("Missing Keyword", keywords.contains("WMS"));
            assertTrue("Missing Keyword", keywords.contains("GEOSERVER"));

            Set<String> serviceTypeVersions = serviceIdentification.getServiceTypeVersions();
            assertTrue("ServiceTypeVersions is null", serviceTypeVersions != null);
            assertEquals("Incorrect ServiceTypeVersion count", 2, serviceTypeVersions.size());
            assertTrue("Missing Keyword", serviceTypeVersions.contains("1.1.0"));
            assertTrue("Missing Keyword", serviceTypeVersions.contains("1.1.1"));

            Set<String> accessConstraints = serviceIdentification.getAccessConstraints();
            assertTrue("AccessConstraints is null", accessConstraints != null);
            assertEquals("Incorrect AccessConstraints count", 1, abstracts.size());
            for (String abs : accessConstraints)
            {
                assertEquals("Incorrect AccessConstraint", "NONE", abs);
            }

            OWSServiceProvider serviceProvider = caps.getServiceProvider();
            assertTrue("ServiceProvider is null", serviceProvider != null);
            assertEquals("ProviderName is incorrect", "The ancient geographes INC", serviceProvider.getProviderName());
            assertEquals("ProviderSite is incorrect", "http://geoserver.org", serviceProvider.getProviderSite());

            OWSServiceContact serviceContact = serviceProvider.getServiceContact();
            assertTrue("ServiceContact is null", serviceContact != null);
            assertEquals("IndividualName is incorrect", "Claudius Ptolomaeus", serviceContact.getIndividualName());
            assertEquals("PositionName is incorrect", "Chief geographer", serviceContact.getPositionName());

            OWSContactInfo contactInfo = serviceContact.getContactInfo();
            assertTrue("ContactInfo is null", contactInfo != null);
            assertEquals("OnlineResource is incorrect", "http://geoserver.org", contactInfo.getOnlineResource());

            OWSPhone phone = contactInfo.getPhone();
            assertTrue("Phone is null", phone != null);

            OWSAddress address = contactInfo.getAddress();
            assertTrue("Address is null", address != null);
            assertEquals("City is incorrect", "Alexandria", address.getCity());

            Set<String> countries = address.getCountries();
            assertTrue("Countries is null", countries != null);
            assertEquals("Incorrect Country count", 1, countries.size());
            for (String country : countries)
            {
                assertEquals("Incorrect Country", "Egypt", country);
            }

            Set<String> emails = address.getElectronicMailAddresses();
            assertTrue("ElectronicMailAddress is null", emails != null);
            assertEquals("Incorrect ElectronicMailAddress count", 1, emails.size());
            for (String email : emails)
            {
                assertEquals("Incorrect ElectronicMailAddress", "claudius.ptolomaeus@gmail.com", email);
            }

            OWSOperationsMetadata operationsMetadata = caps.getOperationsMetadata();
            assertTrue("OperationsMetadata is null", operationsMetadata != null);

            Set<OWSOperation> operations = operationsMetadata.getOperations();
            assertTrue("Operations is null", operations != null);
            assertEquals("Incorrect Operation count", 3, operations.size());
            Set<String> operationNames = new HashSet<String>(3);
            for (OWSOperation operation : operations)
            {
                operationNames.add(operation.getName());
            }
            assertTrue("Missing Operation", operationNames.contains("GetCapabilities"));
            assertTrue("Missing Operation", operationNames.contains("DescribeCoverage"));
            assertTrue("Missing Operation", operationNames.contains("GetCoverage"));

            for (OWSOperation operation : operations)
            {
                Set<OWSDCP> dcps = operation.getDCPs();
                assertTrue("DCPs is null", dcps != null);
                assertEquals("Incorrect DCP count", 2, dcps.size());

                for (OWSDCP dcp : dcps)
                {
                    assertTrue("DCP HTTP is null", dcp.getHTTP() != null);
                }
            }

            String url = operationsMetadata.getGetOperationAddress("Get", "GetCapabilities");
            assertTrue("Get operation address is null", url != null);
            assertEquals("Incorrect HTTP address", "http://10.0.1.198:8080/geoserver/wcs?", url);
            url = operationsMetadata.getGetOperationAddress("Post", "GetCapabilities");
            assertTrue("Get operation address is null", url != null);
            assertEquals("Incorrect HTTP address", "http://10.0.1.198:8080/geoserver/wcs?", url);

            url = operationsMetadata.getGetOperationAddress("Get", "DescribeCoverage");
            assertTrue("Get operation address is null", url != null);
            assertEquals("Incorrect HTTP address", "http://10.0.1.198:8080/geoserver/wcs?", url);
            url = operationsMetadata.getGetOperationAddress("Post", "DescribeCoverage");
            assertTrue("Get operation address is null", url != null);
            assertEquals("Incorrect HTTP address", "http://10.0.1.198:8080/geoserver/wcs?", url);

            url = operationsMetadata.getGetOperationAddress("Get", "GetCoverage");
            assertTrue("Get operation address is null", url != null);
            assertEquals("Incorrect HTTP address", "http://10.0.1.198:8080/geoserver/wcs?", url);
            url = operationsMetadata.getGetOperationAddress("Post", "GetCoverage");
            assertTrue("Get operation address is null", url != null);
            assertEquals("Incorrect HTTP address", "http://10.0.1.198:8080/geoserver/wcs?", url);

            OWSOperation coverageOp = operationsMetadata.getOperation("GetCoverage");
            Set<OWSParameter> parameters = coverageOp.getParameters();
            assertTrue("Operation Parameters is null", parameters != null);
            assertEquals("Operation Parameter count is incorrect", 1, parameters.size());
            for (OWSParameter parameter : parameters)
            {
                assertTrue("Store parameter is missing", parameter.getName() != null);
                assertEquals("Incorrect store value", "store", parameter.getName());

                Set<OWSAllowedValues> allowedValues = parameter.getAllowedValues();
                assertTrue("AllowedValues is null", allowedValues != null);
                assertEquals("AllowedValues count is incorrect", 1, allowedValues.size());
                for (OWSAllowedValues avs : allowedValues)
                {
                    Set<String> avals = avs.getValues();
                    assertTrue("AllowedValues values is null", avals != null);
                    assertEquals("Allowed Values values count is incorrect", 2, avals.size());
                    assertTrue("Missing allowed value", avals.contains("True"));
                    assertTrue("Missing allowed value", avals.contains("False"));
                }
            }

            Set<OWSConstraint> constraints = operationsMetadata.getConstraints();
            assertTrue("Constraints is null", constraints != null);
            assertEquals("Incorrect Constraint count", 1, constraints.size());
            for (OWSConstraint constraint : constraints)
            {
                assertEquals("Incorrect Constraint", "PostEncoding", constraint.getName());

                Set<OWSAllowedValues> allowedValues = constraint.getAllowedValues();
                assertTrue("AllowedValues is null", allowedValues != null);
                assertEquals("AllowedValues count is incorrect", 1, allowedValues.size());
                for (OWSAllowedValues avs : allowedValues)
                {
                    Set<String> avals = avs.getValues();
                    assertTrue("AllowedValues values is null", avals != null);
                    assertEquals("Allowed Values values count is incorrect", 1, avals.size());
                    assertTrue("Missing allowed value", avals.contains("XML"));
                }
            }

            WCSContents contents = caps.getContents();
            assertTrue("WCS Contents is missing", contents != null);

            Set<WCSCoverageSummary> coverageSummaries = contents.getCoverageSummaries();
            assertTrue("WCS CoverageSummarys are missing", coverageSummaries != null);
            assertEquals("WCS CoverageSummarys count is incorrect", 7, coverageSummaries.size());

            Set<String> identifiers = new HashSet<String>(coverageSummaries.size());
            for  (WCSCoverageSummary summary: coverageSummaries)
            {
                identifiers.add(summary.getIdentifier());
            }
            assertTrue("Missing CoverageSummary Identifier", identifiers.contains("Arc_Sample"));
            assertTrue("Missing CoverageSummary Identifier", identifiers.contains("aster_v2"));
            assertTrue("Missing CoverageSummary Identifier", identifiers.contains("FAAChartsCroppedReprojected"));
            assertTrue("Missing CoverageSummary Identifier", identifiers.contains("NASA_SRTM30_900m_Tiled"));
            assertTrue("Missing CoverageSummary Identifier", identifiers.contains("Img_Sample"));
            assertTrue("Missing CoverageSummary Identifier", identifiers.contains("mosaic"));
            assertTrue("Missing CoverageSummary Identifier", identifiers.contains("sfdem"));

            for (WCSCoverageSummary summary : coverageSummaries)
            {
                if (summary.getIdentifier().equals("Arc_Sample"))
                {
                    assertEquals("CoverageSummary Title is incorrect", "A sample ArcGrid file", summary.getTitle());
                    assertEquals("CoverageSummary Abstract is incorrect", "Generated from arcGridSample",
                        summary.getAbstract());

                    keywords = summary.getKeywords();
                    assertTrue("Keywords is null", keywords != null);
                    assertEquals("Incorrect Keyword count", 3, keywords.size());
                    assertTrue("Missing Keyword", keywords.contains("WCS"));
                    assertTrue("Missing Keyword", keywords.contains("arcGridSample"));
                    assertTrue("Missing Keyword", keywords.contains("arcGridSample_Coverage"));

                    OWSWGS84BoundingBox bbox = summary.getBoundingBox();
                    assertTrue("BoundingBox is null", bbox != null);
                    assertEquals("LowerCorner is incorrect", "-180.0 -90.0", bbox.getLowerCorner());
                    assertEquals("UpperCorner is incorrect", "180.0 90.0", bbox.getUpperCorner());
                }
                else if (summary.getIdentifier().equals("aster_v2"))
                {
                    assertEquals("CoverageSummary Title is incorrect", "ASTER", summary.getTitle());
                    assertEquals("CoverageSummary Abstract is incorrect", "Generated from ImageMosaic",
                        summary.getAbstract());

                    keywords = summary.getKeywords();
                    assertTrue("Keywords is null", keywords != null);
                    assertEquals("Incorrect Keyword count", 3, keywords.size());
                    assertTrue("Missing Keyword", keywords.contains("WCS"));
                    assertTrue("Missing Keyword", keywords.contains("ImageMosaic"));
                    assertTrue("Missing Keyword", keywords.contains("ASTER"));

                    OWSWGS84BoundingBox bbox = summary.getBoundingBox();
                    assertTrue("BoundingBox is null", bbox != null);
                    assertEquals("LowerCorner is incorrect", "-180.0001388888889 -83.0001388888889", bbox.getLowerCorner());
                    assertEquals("UpperCorner is incorrect", "180.00013888888887 83.00013888888888", bbox.getUpperCorner());
                }
                else if (summary.getIdentifier().equals("FAAChartsCroppedReprojected"))
                {
                    assertEquals("CoverageSummary Title is incorrect", "FAAChartsCroppedReprojected", summary.getTitle());
                    assertEquals("CoverageSummary Abstract is incorrect", "Generated from ImageMosaic",
                        summary.getAbstract());

                    keywords = summary.getKeywords();
                    assertTrue("Keywords is null", keywords != null);
                    assertEquals("Incorrect Keyword count", 3, keywords.size());
                    assertTrue("Missing Keyword", keywords.contains("WCS"));
                    assertTrue("Missing Keyword", keywords.contains("ImageMosaic"));
                    assertTrue("Missing Keyword", keywords.contains("FAAChartsCroppedReprojected"));

                    OWSWGS84BoundingBox bbox = summary.getBoundingBox();
                    assertTrue("BoundingBox is null", bbox != null);
                    assertEquals("LowerCorner is incorrect", "-173.4897609604564 50.896520942672375", bbox.getLowerCorner());
                    assertEquals("UpperCorner is incorrect", "178.65474058869506 72.33574978977076", bbox.getUpperCorner());
                }
                else if (summary.getIdentifier().equals("NASA_SRTM30_900m_Tiled"))
                {
                    assertEquals("CoverageSummary Title is incorrect", "NASA_SRTM30_900m_Tiled", summary.getTitle());
                    assertEquals("CoverageSummary Abstract is incorrect", "Generated from ImageMosaic",
                        summary.getAbstract());

                    keywords = summary.getKeywords();
                    assertTrue("Keywords is null", keywords != null);
                    assertEquals("Incorrect Keyword count", 3, keywords.size());
                    assertTrue("Missing Keyword", keywords.contains("WCS"));
                    assertTrue("Missing Keyword", keywords.contains("ImageMosaic"));
                    assertTrue("Missing Keyword", keywords.contains("NASA_SRTM30_900m_Tiled"));

                    OWSWGS84BoundingBox bbox = summary.getBoundingBox();
                    assertTrue("BoundingBox is null", bbox != null);
                    assertEquals("LowerCorner is incorrect", "-180.0 -90.0", bbox.getLowerCorner());
                    assertEquals("UpperCorner is incorrect", "180.0 90.0", bbox.getUpperCorner());
                }
                else if (summary.getIdentifier().equals("Img_Sample"))
                {
                    assertEquals("CoverageSummary Title is incorrect", "North America sample imagery", summary.getTitle());
                    assertEquals("CoverageSummary Abstract is incorrect", "A very rough imagery of North America",
                        summary.getAbstract());

                    keywords = summary.getKeywords();
                    assertTrue("Keywords is null", keywords != null);
                    assertEquals("Incorrect Keyword count", 3, keywords.size());
                    assertTrue("Missing Keyword", keywords.contains("WCS"));
                    assertTrue("Missing Keyword", keywords.contains("worldImageSample"));
                    assertTrue("Missing Keyword", keywords.contains("worldImageSample_Coverage"));

                    OWSWGS84BoundingBox bbox = summary.getBoundingBox();
                    assertTrue("BoundingBox is null", bbox != null);
                    assertEquals("LowerCorner is incorrect", "-130.85168 20.7052", bbox.getLowerCorner());
                    assertEquals("UpperCorner is incorrect", "-62.0054 54.1141", bbox.getUpperCorner());
                }
                else if (summary.getIdentifier().equals("mosaic"))
                {
                    assertEquals("CoverageSummary Title is incorrect", "mosaic", summary.getTitle());
                    assertEquals("CoverageSummary Abstract is incorrect", "Generated from ImageMosaic",
                        summary.getAbstract());

                    keywords = summary.getKeywords();
                    assertTrue("Keywords is null", keywords != null);
                    assertEquals("Incorrect Keyword count", 3, keywords.size());
                    assertTrue("Missing Keyword", keywords.contains("WCS"));
                    assertTrue("Missing Keyword", keywords.contains("ImageMosaic"));
                    assertTrue("Missing Keyword", keywords.contains("mosaic"));

                    OWSWGS84BoundingBox bbox = summary.getBoundingBox();
                    assertTrue("BoundingBox is null", bbox != null);
                    assertEquals("LowerCorner is incorrect", "6.346 36.492", bbox.getLowerCorner());
                    assertEquals("UpperCorner is incorrect", "20.83 46.591", bbox.getUpperCorner());
                }
                else if (summary.getIdentifier().equals("sfdem"))
                {
                    assertEquals("CoverageSummary Title is incorrect", "sfdem is a Tagged Image File Format with Geographic information", summary.getTitle());
                    assertEquals("CoverageSummary Abstract is incorrect", "Generated from sfdem",
                        summary.getAbstract());

                    keywords = summary.getKeywords();
                    assertTrue("Keywords is null", keywords != null);
                    assertEquals("Incorrect Keyword count", 2, keywords.size());
                    assertTrue("Missing Keyword", keywords.contains("WCS"));
                    assertTrue("Missing Keyword", keywords.contains("sfdem"));

                    OWSWGS84BoundingBox bbox = summary.getBoundingBox();
                    assertTrue("BoundingBox is null", bbox != null);
                    assertEquals("LowerCorner is incorrect", "-103.87108701853181 44.370187074132616", bbox.getLowerCorner());
                    assertEquals("UpperCorner is incorrect", "-103.62940739432703 44.5016011535299", bbox.getUpperCorner());
                }
                else
                {
                    assertTrue("Unrecognized WCS CoverageSummary", false);
                }
            }
        }
    }

    public static void main(String[] args)
    {
        new TestRunner().doRun(new TestSuite(Tests.class));
    }
}
