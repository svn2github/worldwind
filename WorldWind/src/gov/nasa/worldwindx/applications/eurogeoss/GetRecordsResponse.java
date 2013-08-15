/*
 * Copyright (C) 2013 United States Government as represented by the Administrator of the
 * National Aeronautics and Space Administration.
 * All Rights Reserved.
 */
package gov.nasa.worldwindx.applications.eurogeoss;

import gov.nasa.worldwind.util.*;
import org.w3c.dom.*;

import javax.xml.xpath.XPath;
import java.util.*;

/**
 * @author dcollins
 * @version $Id$
 */
public class GetRecordsResponse
{
    protected int numberOfRecordsMatched;
    protected int numberOfRecordsReturned;
    protected int nextRecord;
    protected Collection<Record> records;

    public GetRecordsResponse(Object docSource)
    {
        if (docSource == null)
        {
            String msg = Logging.getMessage("nullValue.DocumentSourceIsNull");
            Logging.logger().severe(msg);
            throw new IllegalArgumentException(msg);
        }

        Document doc = WWXML.openDocument(docSource);

        BasicNamespaceContext namespaceContext = new BasicNamespaceContext();
        namespaceContext.addNamespace("csw", "http://www.opengis.net/cat/csw/2.0.2");
        namespaceContext.addNamespace("gmd", "http://www.isotc211.org/2005/gmd");
        namespaceContext.addNamespace("gco", "http://www.isotc211.org/2005/gco");

        XPath xpath = WWXML.makeXPath();
        xpath.setNamespaceContext(namespaceContext);

        this.numberOfRecordsMatched = WWXML.getInteger(doc.getDocumentElement(),
            "/csw:GetRecordsResponse/csw:SearchResults/@numberOfRecordsMatched", xpath);
        this.numberOfRecordsReturned = WWXML.getInteger(doc.getDocumentElement(),
            "/csw:GetRecordsResponse/csw:SearchResults/@numberOfRecordsReturned", xpath);
        this.nextRecord = WWXML.getInteger(doc.getDocumentElement(),
            "/csw:GetRecordsResponse/csw:SearchResults/@nextRecord", xpath);

        Element[] recordElems = WWXML.getElements(doc.getDocumentElement(),
            "/csw:GetRecordsResponse/csw:SearchResults/gmd:MD_Metadata", xpath);
        if (recordElems != null && recordElems.length > 0)
        {
            this.records = new ArrayList<Record>();

            for (Element recordElem : recordElems)
            {
                Record record = new Record();
                record.setTitle(WWXML.getText(recordElem,
                    "./gmd:identificationInfo/gmd:MD_DataIdentification/gmd:citation/gmd:CI_Citation/gmd:title/*[1]",
                    xpath).trim());

                Element[] wmsResourceElems = WWXML.getElements(recordElem,
                    "./gmd:distributionInfo/gmd:MD_Distribution/gmd:transferOptions/gmd:MD_DigitalTransferOptions/gmd:onLine/gmd:CI_OnlineResource[starts-with(gmd:protocol/gco:CharacterString, \"urn:ogc:serviceType:WebMapService:\")]",
                    xpath);
                if (wmsResourceElems != null && wmsResourceElems.length > 0)
                {
                    Set<OnlineResource> resourceSet
                        = new LinkedHashSet<OnlineResource>(); // Use LinkedHashSet to preserve insertion order.
                    record.setWmsOnlineResources(resourceSet);

                    for (Element wmsResourceElem : wmsResourceElems)
                    {
                        OnlineResource onlineResource = new OnlineResource();
                        onlineResource.setName(
                            WWXML.getText(wmsResourceElem, "./gmd:name/gco:CharacterString", xpath).trim());
                        onlineResource.setLinkage(
                            WWXML.getText(wmsResourceElem, "./gmd:linkage/gmd:URL", xpath).trim());
                        onlineResource.setProtocol(
                            WWXML.getText(wmsResourceElem, "./gmd:protocol/gco:CharacterString", xpath).trim());
                        resourceSet.add(onlineResource);
                    }
                }

                this.records.add(record);
            }
        }
    }

    public int getNumberOfRecordsMatched()
    {
        return this.numberOfRecordsMatched;
    }

    public int getNumberOfRecordsReturned()
    {
        return this.numberOfRecordsReturned;
    }

    public int getNextRecord()
    {
        return this.nextRecord;
    }

    public Collection<Record> getRecords()
    {
        return this.records;
    }
}
