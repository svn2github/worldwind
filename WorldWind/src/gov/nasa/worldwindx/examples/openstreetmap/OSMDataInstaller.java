/*
 * Copyright (C) 2012 United States Government as represented by the Administrator of the
 * National Aeronautics and Space Administration.
 * All Rights Reserved.
 */

package gov.nasa.worldwindx.examples.openstreetmap;

import gov.nasa.worldwind.avlist.AVKey;
import gov.nasa.worldwind.util.*;

import javax.swing.*;
import javax.swing.border.*;
import javax.xml.stream.XMLStreamException;
import java.awt.*;
import java.awt.event.*;
import java.io.*;

/**
 * Shows how to use {@link OSMCacheBuilder} to install Open Street Map data into the local cache. The process is simply
 * to create an {@code OSMCacheBuilder} and invoke its {@link OSMCacheBuilder#loadFromFile(java.io.File)} method with
 * the desired .pbf file containing the open street map data.
 *
 * @author tag
 * @version $Id$
 */
public class OSMDataInstaller extends JFrame
{
    protected JFileChooser fileChooser = new JFileChooser();
    protected JLabel nodeLabel;
    protected JLabel wayLabel;
    protected Thread loadingThread;

    public OSMDataInstaller()
    {
        this.setTitle("World Wind Open Street Map Data Installer");

        this.setDefaultCloseOperation(JFrame.EXIT_ON_CLOSE);

        this.getContentPane().add(this.makePanel());

        this.pack();

        WWUtil.alignComponent(null, this, AVKey.CENTER);

        java.awt.EventQueue.invokeLater(new Runnable()
        {
            public void run()
            {
                setVisible(true);
            }
        });
    }

    protected JPanel makePanel()
    {
        JPanel panel = new JPanel(new BorderLayout(5, 5));
        panel.setBorder(new EmptyBorder(10, 10, 10, 10));

        JButton openButton = new JButton("Open OSM File");
        openButton.addActionListener(new ActionListener()
        {
            @Override
            public void actionPerformed(ActionEvent actionEvent)
            {
                try
                {
                    int status = fileChooser.showOpenDialog(OSMDataInstaller.this);
                    if (status == JFileChooser.APPROVE_OPTION)
                    {
                        loadOSMData(fileChooser.getSelectedFile());
                    }
                }
                catch (Exception e)
                {
                    e.printStackTrace();
                }
            }
        });

        panel.add(openButton, BorderLayout.NORTH);

        JPanel labelPanel = new JPanel(new GridLayout(2, 2, 5, 5));
        labelPanel.setBorder(new EmptyBorder(10, 10, 10, 10));

        labelPanel.add(new JLabel("Nodes"));
        labelPanel.add(this.nodeLabel = new JLabel("0"));

        labelPanel.add(new JLabel("Ways"));
        labelPanel.add(this.wayLabel = new JLabel("0"));

        panel.add(labelPanel, BorderLayout.CENTER);

        JButton cancelButton = new JButton("Cancel");
        cancelButton.addActionListener(new ActionListener()
        {
            @Override
            public void actionPerformed(ActionEvent actionEvent)
            {
                if (loadingThread != null && loadingThread.isAlive())
                    loadingThread.interrupt();
            }
        });

        panel.add(cancelButton, BorderLayout.SOUTH);

        return panel;
    }

    protected void loadOSMData(final File file)
    {
        final OSMCacheBuilder cacheBuilder;
        try
        {
            // Create an OSM cache builder.
            cacheBuilder = new OSMCacheBuilder(getOSMConfigurationStream());
        }
        catch (XMLStreamException e)
        {
            e.printStackTrace();
            return;
        }

        this.loadingThread = new Thread(new Runnable()
        {
            public void run()
            {
                try
                {
                    // Tell the cache builder to load the selected file.
                    cacheBuilder.loadFromFile(file);
                }
                catch (FileNotFoundException e)
                {
                    e.printStackTrace();
                }
                catch (InterruptedException e)
                {
                    e.printStackTrace();
                }
                finally
                {
                    SwingUtilities.invokeLater(new Runnable()
                    {
                        @Override
                        public void run()
                        {
                            setCursor(Cursor.getDefaultCursor());
                        }
                    });
                }
            }
        });

        this.nodeLabel.setText("0");
        this.wayLabel.setText("0");
        this.startTimer(cacheBuilder);
        setCursor(new Cursor(Cursor.WAIT_CURSOR));

        this.loadingThread.start();
    }

    protected void startTimer(final OSMCacheBuilder cacheBuilder)
    {
        Timer timer = new Timer(1000, new ActionListener()
        {
            @Override
            public void actionPerformed(ActionEvent actionEvent)
            {
                nodeLabel.setText(Integer.toString(cacheBuilder.getNumNodes()));
                wayLabel.setText(Integer.toString(cacheBuilder.getNumWays()));
            }
        });
        timer.start();
    }

    protected InputStream getOSMConfigurationStream()
    {
        Object o = WWIO.getFileOrResourceAsStream("config/Earth/OSMAttributes.xml", OSMCacheBuilder.class);
        if (o instanceof Exception)
        {
            ((Exception) o).printStackTrace();
            return null;
        }

        return (InputStream) o;
    }

    public static void main(String[] args)
    {
        OSMDataInstaller installer = new OSMDataInstaller();
    }
}
