/*
Copyright (C) 2001, 2012 United States Government as represented by
the Administrator of the National Aeronautics and Space Administration. 
All Rights Reserved.
*/
package gov.nasa.worldwindx.examples;

import android.app.Activity;
import android.content.Intent;
import android.content.pm.ActivityInfo;
import android.os.Bundle;
import gov.nasa.worldwindx.examples.util.ActivityList;

/**
 * The WorldWindExamples activity displays a list of all World Wind examples, and enables the user to start each one by
 * clicking on its list item. Each example is registered by providing an activity entry in the Android manifest file.
 * The following template demonstrates the necessary elements and attributes that each activity must provide:
 * <p/>
 * <code>
 * <pre>
 * <activity android:name="EXAMPLE_CLASS_NAME"
 *           android:label="EXAMPLE_LABEL"
 *           android:icon="EXAMPLE_ICON">
 *     <intent-filter>
 *         <action android:name="android.intent.action.MAIN"/>
 *         <category android:name="android.intent.category.SAMPLE_CODE"/>
 *     </intent-filter>
 *     <meta-data android:name="description" android:value="EXAMPLE_DESCRIPTION"/>
 * </activity>
 * </pre>
 * </code>
 *
 * @author dcollins
 * @version $Id$
 */
public class WorldWindExamples extends Activity implements ActivityList.OnActivityClickListener
{
    /**
     * Configures this activity's content view using the worldwind_examples layout, and listens to item clicks on the
     * example_list fragment. Item clicks are forwarded to <code>onExampleItemClick</code>.
     *
     * @param savedInstanceState If the activity is being re-initialized after previously being shut down then this
     *                           Bundle contains the data it most recently supplied in {@link #onSaveInstanceState}.
     *                           <b><i>Note: Otherwise it is null.</i></b>
     */
    @Override
    protected void onCreate(Bundle savedInstanceState)
    {
        super.onCreate(savedInstanceState);
        this.setContentView(R.layout.worldwind_examples);

        // Listen to click events in the list of examples, and forward them to onExampleItemClicked.
        ActivityList activityList = (ActivityList) this.getFragmentManager().findFragmentById(R.id.example_list);
        activityList.setOnActivityClickListener(this);
    }

    /**
     * Called when the user has clicked an item in the list of examples. This starts the activity associated with the
     * clicked example.
     *
     * @param activityInfo the activity package information for the example that has been clicked.
     */
    public void onActivityClick(ActivityInfo activityInfo)
    {
        // Create an intent that indicates the example activity that we want to start, and use this activity's built-in
        // capabilities to start that activity. By starting the example this way, the system automatically manages the
        // back stack for us. When the user is done with the example activity and clicks back, they will return to this
        // activity.
        Intent intent = new Intent();
        intent.setClassName(activityInfo.packageName, activityInfo.name);
        this.startActivity(intent);
    }
}
