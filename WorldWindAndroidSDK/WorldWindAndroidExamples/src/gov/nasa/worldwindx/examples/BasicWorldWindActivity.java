/* Copyright (C) 2001, 2012 United States Government as represented by
the Administrator of the National Aeronautics and Space Administration.
All Rights Reserved.
*/
package gov.nasa.worldwindx.examples;

import android.app.Activity;
import android.os.Bundle;
import android.widget.TextView;
import gov.nasa.worldwind.*;
import gov.nasa.worldwind.avlist.AVKey;
import gov.nasa.worldwind.geom.*;
import gov.nasa.worldwind.globes.Globe;

import java.io.File;

/**
 * @author dcollins
 * @version $Id$
 */
public class BasicWorldWindActivity extends Activity
{
    protected WorldWindowGLSurfaceView wwd;

    /** Called when the activity is first created. */
    @Override
    public void onCreate(Bundle savedInstanceState)
    {
        super.onCreate(savedInstanceState);

        // TODO: temporary method of setting the location of the file store on Android. Need to replace this with
        // TODO: something more flexible.
        File fileDir = getFilesDir();
        System.setProperty("gov.nasa.worldwind.platform.user.store", fileDir.getAbsolutePath());

        this.setContentView(R.layout.basic_worldwind_activity);

        this.wwd = (WorldWindowGLSurfaceView) this.findViewById(R.id.wwd);
        this.wwd.setModel((Model) WorldWind.createConfigurationComponent(AVKey.MODEL_CLASS_NAME));
        this.setupView();
        this.setupTextViews();
    }

    @Override
    protected void onPause()
    {
        super.onPause();

        // Pause the OpenGL ES rendering thread.
        this.wwd.onPause();
    }

    @Override
    protected void onResume()
    {
        super.onResume();

        // Resume the OpenGL ES rendering thread.
        this.wwd.onResume();
    }

    protected void setupView()
    {
        // TODO: this should be done during View initialization, not here in the application.
        BasicView view = (BasicView) this.wwd.getView();
        Globe globe = this.wwd.getModel().getGlobe();

        Position lookFromPosition = Position.fromDegrees(Configuration.getDoubleValue(AVKey.INITIAL_LATITUDE),
            Configuration.getDoubleValue(AVKey.INITIAL_LONGITUDE),
            Configuration.getDoubleValue(AVKey.INITIAL_ALTITUDE));
        view.setEyePosition(lookFromPosition, Angle.fromDegrees(0), Angle.fromDegrees(0), globe);
        view.setEyeTilt(Angle.fromDegrees(0), globe);
    }

    protected void setupTextViews()
    {
        TextView latTextView = (TextView) findViewById(R.id.latvalue);
        this.wwd.setLatitudeText(latTextView);
        TextView lonTextView = (TextView) findViewById(R.id.lonvalue);
        this.wwd.setLongitudeText(lonTextView);
    }
}
