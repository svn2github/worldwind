/*
 * Copyright (C) 2012 United States Government as represented by the Administrator of the
 * National Aeronautics and Space Administration.
 * All Rights Reserved.
 */
package gov.nasa.worldwindx.examples;

import gov.nasa.worldwind.avlist.AVKey;
import gov.nasa.worldwind.geom.Sector;
import gov.nasa.worldwind.layers.Layer;
import gov.nasa.worldwind.util.*;
import gov.nasa.worldwindx.examples.util.*;

import javax.swing.*;
import javax.swing.filechooser.*;
import java.awt.*;
import java.awt.event.*;
import java.io.File;

/**
 * Illustrates how to import ESRI Shapefiles into World Wind. This uses a <code>{@link ShapefileLoader}</code> to parse
 * a Shapefile's contents and convert each shape into an equivalent World Wind shape. This provides examples of
 * importing a Shapefile on the local hard drive and importing a Shapefile at a remote URL.
 *
 * @author Patrick Murris
 * @version $Id$
 */
public class Shapefiles extends ApplicationTemplate
{
    public static class AppFrame extends ApplicationTemplate.AppFrame
    {
        public AppFrame()
        {
            makeMenu(this);
        }

        public void addShapefileLayer(Layer layer)
        {
            this.getWwd().getModel().getLayers().add(layer);
            this.getLayerPanel().update(this.getWwd());
        }

        public void gotoLayer(Layer layer)
        {
            Sector sector = (Sector) layer.getValue(AVKey.SECTOR);
            if (sector != null)
            {
                ExampleUtil.goTo(this.getWwd(), sector);
            }
        }
    }

    public static class WorkerThread extends Thread
    {
        protected Object shpSource;
        protected AppFrame appFrame;

        public WorkerThread(Object shpSource, AppFrame appFrame)
        {
            this.shpSource = shpSource;
            this.appFrame = appFrame;
        }

        public void run()
        {
            SwingUtilities.invokeLater(new Runnable()
            {
                @Override
                public void run()
                {
                    appFrame.setCursor(Cursor.getPredefinedCursor(Cursor.WAIT_CURSOR));
                }
            });

            try
            {
                Layer shpLayer = this.parse();

                // Set the shapefile layer's display name
                shpLayer.setName(formName(this.shpSource));

                // Schedule a task on the EDT to add the parsed shapefile layer to a layer
                final Layer finalSHPLayer = shpLayer;
                SwingUtilities.invokeLater(new Runnable()
                {
                    public void run()
                    {
                        appFrame.addShapefileLayer(finalSHPLayer);
                        appFrame.gotoLayer(finalSHPLayer);
                    }
                });
            }
            catch (Exception e)
            {
                e.printStackTrace();
            }
            finally
            {
                SwingUtilities.invokeLater(new Runnable()
                {
                    public void run()
                    {
                        appFrame.setCursor(null);
                    }
                });
            }
        }

        protected Layer parse()
        {
            if (OpenStreetMapShapefileLoader.isOSMPlacesSource(this.shpSource))
            {
                return OpenStreetMapShapefileLoader.makeLayerFromOSMPlacesSource(this.shpSource);
            }
            else
            {
                ShapefileLoader loader = new ShapefileLoader();
                return loader.createLayerFromSource(this.shpSource);
            }
        }
    }

    protected static String formName(Object source)
    {
        String name = WWIO.getSourcePath(source);
        if (name != null)
            name = WWIO.getFilename(name);
        if (name == null)
            name = "Shapefile";

        return name;
    }

    protected static void makeMenu(final AppFrame appFrame)
    {
        final JFileChooser fileChooser = new JFileChooser();
        fileChooser.setMultiSelectionEnabled(true);
        fileChooser.addChoosableFileFilter(new FileNameExtensionFilter("Shapefile", "shp"));
        fileChooser.setFileFilter(fileChooser.getChoosableFileFilters()[1]);

        JMenuBar menuBar = new JMenuBar();
        appFrame.setJMenuBar(menuBar);
        JMenu fileMenu = new JMenu("File");
        menuBar.add(fileMenu);

        JMenuItem openFileMenuItem = new JMenuItem(new AbstractAction("Open File...")
        {
            public void actionPerformed(ActionEvent actionEvent)
            {
                try
                {
                    int status = fileChooser.showOpenDialog(appFrame);
                    if (status == JFileChooser.APPROVE_OPTION)
                    {
                        for (File file : fileChooser.getSelectedFiles())
                        {
                            new WorkerThread(file, appFrame).start();
                        }
                    }
                }
                catch (Exception e)
                {
                    e.printStackTrace();
                }
            }
        });

        fileMenu.add(openFileMenuItem);

        JMenuItem openURLMenuItem = new JMenuItem(new AbstractAction("Open URL...")
        {
            public void actionPerformed(ActionEvent actionEvent)
            {
                try
                {
                    String status = JOptionPane.showInputDialog(appFrame, "URL");
                    if (!WWUtil.isEmpty(status))
                    {
                        new WorkerThread(status.trim(), appFrame).start();
                    }
                }
                catch (Exception e)
                {
                    e.printStackTrace();
                }
            }
        });

        fileMenu.add(openURLMenuItem);
    }

    public static void main(String[] args)
    {
        start("World Wind Shapefile Viewer", AppFrame.class);
    }
}
