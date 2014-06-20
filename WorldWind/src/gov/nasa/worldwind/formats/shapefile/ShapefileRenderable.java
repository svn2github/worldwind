/*
 * Copyright (C) 2014 United States Government as represented by the Administrator of the
 * National Aeronautics and Space Administration.
 * All Rights Reserved.
 */
package gov.nasa.worldwind.formats.shapefile;

import gov.nasa.worldwind.WWObjectImpl;
import gov.nasa.worldwind.avlist.AVListImpl;
import gov.nasa.worldwind.geom.Sector;
import gov.nasa.worldwind.render.*;
import gov.nasa.worldwind.util.*;

import java.nio.IntBuffer;
import java.util.*;

/**
 * @author dcollins
 * @version $Id$
 */
public abstract class ShapefileRenderable extends WWObjectImpl
    implements Renderable, Iterable<ShapefileRenderable.Record>
{
    public static class Record extends AVListImpl implements Highlightable
    {
        // Record properties.
        protected final ShapefileRenderable shapefileRenderable;
        protected final Sector sector;
        protected final int recordNumber;
        protected boolean visible = true;
        protected boolean highlighted;
        protected ShapeAttributes normalAttrs;
        protected ShapeAttributes highlightAttrs;
        // Data structures supporting record tessellation and display.
        protected int firstPartNumber;
        protected int lastPartNumber;
        protected int numberOfPoints;
        protected IntBuffer interiorIndices;
        protected IntBuffer outlineIndices;
        protected Double height;
        protected Object tile;

        public Record(ShapefileRenderable shapefileRenderable, ShapefileRecord shapefileRecord)
        {
            if (shapefileRenderable == null)
            {
                String msg = Logging.getMessage("nullValue.RenderableIsNull");
                Logging.logger().severe(msg);
                throw new IllegalArgumentException(msg);
            }

            if (shapefileRecord == null)
            {
                String msg = Logging.getMessage("nullValue.RecordIsNull");
                Logging.logger().severe(msg);
                throw new IllegalArgumentException(msg);
            }

            this.shapefileRenderable = shapefileRenderable;
            this.recordNumber = shapefileRecord.getRecordNumber();

            if (shapefileRecord instanceof ShapefileRecordPolyline)
            {
                double[] boundingRect = ((ShapefileRecordPolyline) shapefileRecord).getBoundingRectangle();
                this.sector = boundingRect != null ? Sector.fromDegrees(boundingRect) : null;
            }
            else
            {
                this.sector = null;
            }

            this.firstPartNumber = shapefileRecord.getFirstPartNumber();
            this.lastPartNumber = shapefileRecord.getLastPartNumber();
            this.numberOfPoints = shapefileRecord.getNumberOfPoints();
            this.height = ShapefileUtils.extractHeightAttribute(shapefileRecord);
        }

        public ShapefileRenderable getShapefileRenderable()
        {
            return this.shapefileRenderable;
        }

        public Sector getSector()
        {
            return this.sector;
        }

        public int getRecordNumber()
        {
            return this.recordNumber;
        }

        public boolean isVisible()
        {
            return this.visible;
        }

        public void setVisible(boolean visible)
        {
            if (this.visible != visible)
            {
                this.visible = visible;
                this.shapefileRenderable.recordDidChange(this);
            }
        }

        @Override
        public boolean isHighlighted()
        {
            return this.highlighted;
        }

        @Override
        public void setHighlighted(boolean highlighted)
        {
            if (this.highlighted != highlighted)
            {
                this.highlighted = highlighted;
                this.shapefileRenderable.recordDidChange(this);
            }
        }

        public ShapeAttributes getAttributes()
        {
            return this.normalAttrs;
        }

        public void setAttributes(ShapeAttributes normalAttrs)
        {
            if (this.normalAttrs != normalAttrs)
            {
                this.normalAttrs = normalAttrs;
                this.shapefileRenderable.recordDidChange(this);
            }
        }

        public ShapeAttributes getHighlightAttributes()
        {
            return this.highlightAttrs;
        }

        public void setHighlightAttributes(ShapeAttributes highlightAttrs)
        {
            if (this.highlightAttrs != highlightAttrs)
            {
                this.highlightAttrs = highlightAttrs;
                this.shapefileRenderable.recordDidChange(this);
            }
        }
    }

    protected Sector sector;
    protected ArrayList<ShapefileRenderable.Record> records;
    protected CompoundVecBuffer coordBuffer;
    protected boolean visible = true;
    protected double maxHeight;

    protected static ShapeAttributes defaultAttributes;
    protected static ShapeAttributes defaultHighlightAttributes;

    static
    {
        defaultAttributes = new BasicShapeAttributes();
        defaultAttributes.setInteriorMaterial(Material.LIGHT_GRAY);
        defaultAttributes.setOutlineMaterial(Material.DARK_GRAY);
        defaultHighlightAttributes = new BasicShapeAttributes();
        defaultHighlightAttributes.setInteriorMaterial(Material.WHITE);
        defaultHighlightAttributes.setOutlineMaterial(Material.DARK_GRAY);
    }

    public ShapefileRenderable(Shapefile shapefile)
    {
        if (shapefile == null)
        {
            String msg = Logging.getMessage("nullValue.ShapefileIsNull");
            Logging.logger().severe(msg);
            throw new IllegalArgumentException(msg);
        }

        this.records = new ArrayList<ShapefileRenderable.Record>();
        this.assembleShapefileRecords(shapefile);

        double[] boundingRect = shapefile.getBoundingRectangle();
        this.sector = boundingRect != null ? Sector.fromDegrees(boundingRect) : null;
        this.coordBuffer = shapefile.getPointBuffer(); // valid only after records are assembled
    }

    protected void assembleShapefileRecords(Shapefile shapefile)
    {
        while (shapefile.hasNext())
        {
            this.addShapefileRecord(shapefile.nextRecord());
        }

        this.records.trimToSize(); // Reduce memory overhead from unused ArrayList capacity.
    }

    protected void addShapefileRecord(ShapefileRecord shapefileRecord)
    {
        if (Shapefile.isNullType(shapefileRecord.getShapeType()))
            return;

        if (shapefileRecord.getNumberOfParts() == 0 || shapefileRecord.getNumberOfPoints() == 0)
            return;

        ShapefileRenderable.Record record = new ShapefileRenderable.Record(this, shapefileRecord);
        this.records.add(record);

        if (record.height != null && this.maxHeight < record.height)
        {
            this.maxHeight = record.height;
        }
    }

    public Sector getSector()
    {
        return this.sector;
    }

    public int getRecordCount()
    {
        return this.records.size();
    }

    public ShapefileRenderable.Record getRecord(int recordNumber)
    {
        if (recordNumber < 0 || recordNumber >= this.records.size())
        {
            String msg = Logging.getMessage("generic.indexOutOfRange", recordNumber);
            Logging.logger().severe(msg);
            throw new IllegalArgumentException(msg);
        }

        return this.records.get(recordNumber);
    }

    @Override
    public Iterator<ShapefileRenderable.Record> iterator()
    {
        return this.records.iterator();
    }

    public boolean isVisible()
    {
        return this.visible;
    }

    public void setVisible(boolean visible)
    {
        this.visible = visible;
    }

    protected void recordDidChange(ShapefileRenderable.Record record)
    {
        // Intentionally left empty. May be overridden by subclass.
    }

    protected ShapeAttributes determineActiveAttributes(ShapefileRenderable.Record record)
    {
        if (record.highlighted)
        {
            return record.highlightAttrs != null ? record.highlightAttrs : defaultHighlightAttributes;
        }
        else if (record.normalAttrs != null)
        {
            return record.normalAttrs;
        }
        else
        {
            return defaultAttributes;
        }
    }
}