/* Copyright (C) 2001, 2012 United States Government as represented by 
the Administrator of the National Aeronautics and Space Administration. 
All Rights Reserved.
*/
package gov.nasa.worldwindx.examples.util;

import android.app.ListFragment;
import android.content.Intent;
import android.content.pm.*;
import android.os.Bundle;
import android.view.View;
import android.widget.*;
import gov.nasa.worldwindx.examples.R;

import java.util.*;

/**
 * Fragment that displays a list of activities. We use a fragment rather than a ListView or ListActivity in order to
 * enable its re-use as a general list of activities. When this fragment is created it populates its list with all
 * activities that meet the following criteria:
 * <p/>
 * <ul> <li>Action is MAIN</li> <li>At least one Category is SAMPLE_CODE</li> <li>Package is the same as this fragment's
 * containing activity</li> </ul>
 * <p/>
 * When an activity is clicked, this calls the registered OnActivityClickListener, passing the ActivityInfo
 * corresponding to the clicked activity. The layout for each list item is defined by activity_list_item.xml.
 *
 * @author dcollins
 * @version $Id$
 */
public class ActivityList extends ListFragment
{
    /**
     * Implementations of OnActivityClickListener are notified by onActivityClick when the user clicks an activity in an
     * ActivityList.
     */
    public interface OnActivityClickListener
    {
        /**
         * Called when the user clicks an activity in an ActivityList. The activityInfo parameter indicates the package
         * information corresponding to the clicked activity, and can be used to inspect the activity, send it an
         * intent, or start the activity.
         *
         * @param activityInfo the package information corresponding to the clicked activity.
         */
        void onActivityClick(ActivityInfo activityInfo);
    }

    /**
     * Listener that is notified when the user clicks an activity in this list. May be <code>null</code>, indicating
     * that no notification should be sent. Initially <code>null</code>.
     */
    protected OnActivityClickListener onActivityClickListener;

    /**
     * Indicates the listener that is notified when the user clicks an activity in this list. Returns <code>null</code>
     * to indicate that no notification is sent.
     *
     * @return this list's activity click listener.
     */
    @SuppressWarnings("UnusedDeclaration")
    public OnActivityClickListener getOnActivityClickListener()
    {
        return onActivityClickListener;
    }

    /**
     * Specifies the listener that is notified when the user clicks an activity in this list.
     *
     * @param onActivityClickListener the new activity click listener, or null to disable activity click notifications.
     */
    public void setOnActivityClickListener(OnActivityClickListener onActivityClickListener)
    {
        this.onActivityClickListener = onActivityClickListener;
    }

    /**
     * Called when this fragment is initially created. This calls the superclass' functionality, then populates this
     * list with the list of registered activities by calling assembleActivities.
     *
     * @param savedInstanceState this fragment's previous saved state, or <code>null</code> if this fragment has no
     *                           saved state.
     */
    @Override
    public void onCreate(Bundle savedInstanceState)
    {
        super.onCreate(savedInstanceState);

        this.assembleActivities();
    }

    /**
     * Called when a list item is clicked. This method should not be overridden in order to capture activity click
     * events. Instead, register a listener by calling setOnActivityClickListener.
     * <p/>
     * This calls the superclass' functionality, then forwards the call to this list's OnActivityClickListener, if one
     * is registered. This does nothing if there is no currently registered OnActivityClickListener.
     *
     * @param l        the list view that received the click.
     * @param v        the view corresponding to the clicked list item.
     * @param position the position of the clicked list item.
     * @param id       the row id of the clicked list item.
     */
    @Override
    @SuppressWarnings("unchecked")
    public void onListItemClick(ListView l, View v, int position, long id)
    {
        super.onListItemClick(l, v, position, id);

        Object o = l.getItemAtPosition(position);
        if (o == null)
            return;

        if (this.onActivityClickListener == null)
            return;

        Map<String, Object> item = (Map<String, Object>) o;
        this.onActivityClickListener.onActivityClick((ActivityInfo) item.get("activityInfo"));
    }

    /**
     * Populates this fragment's list of activities. Each activity's intent filter must match the intent returned by
     * getQueryIntent. Each matching activity is represented by a map of key-value pairs returned by getActivityParams.
     */
    protected void assembleActivities()
    {
        // Get the list of World Wind activities to display. We get this list by querying the activities that are
        // registered and who's intent filter match the intent returned by getQueryIntent. We specify the GET_META_DATA
        // flag so that an activity's metadata properties are available when creating its list item.
        PackageManager pm = this.getActivity().getPackageManager();
        Intent queryIntent = this.getQueryIntent();
        List<ResolveInfo> activities = pm.queryIntentActivities(queryIntent, PackageManager.GET_META_DATA);

        if (activities == null)
            return;

        // Populate the list of activities from the returned list of matching package information. Each activity is
        // represented by a map of key-value pairs defining its icon, displayName, description, and activityInfo. These
        // key-value pairs are used to display the activity in the list item layout, and are used to notify the
        // application when an activity is clicked.
        List<Map<String, Object>> activityList = new ArrayList<Map<String, Object>>();

        for (ResolveInfo info : activities)
        {
            Map<String, Object> activityParams = this.getActivityParams(info);
            if (activityParams != null)
                activityList.add(activityParams);
        }

        // Create a list adapter using this fragment's activity as the context, and the layout activity_list_item as the
        // list item template. This adapter maps each list item's parameters to list item view's as follows:
        // - icon to activity_list_item/icon
        // - displayName to activity_list_item/displayName
        // - description to activity_list_item/description
        SimpleAdapter adapter = new SimpleAdapter(this.getActivity(), activityList, R.layout.activity_list_item,
            new String[] {"icon", "displayName", "description"},
            new int[] {R.id.icon, R.id.displayName, R.id.description});
        this.setListAdapter(adapter);
    }

    /**
     * Indicates an intent that can be used to query the activities that this list should display. Any activities who's
     * intent filter match the specified intent are displayed in this list. The returned intent provides the following
     * criteria:
     * <p/>
     * <ul> <li>Action must be MAIN</li> <li>At least one Category must be SAMPLE_CODE</li> <li>The package is the same
     * as this fragment's containing activity</li> </ul>
     * <p/>
     *
     * @return an intent used to query the activities this list should display.
     */
    protected Intent getQueryIntent()
    {
        Intent intent = new Intent(Intent.ACTION_MAIN);
        intent.addCategory(Intent.CATEGORY_SAMPLE_CODE);
        intent.setPackage(this.getActivity().getPackageName());

        return intent;
    }

    /**
     * Indicates a map of key-value pairs that represents an activity corresponding to the specified package
     * information. The map must contain values for the following keys:
     * <p/>
     * <ul> <li>icon - an ID indicating the activity's icon resource, or 0 to indicate the default icon resource</li>
     * <li>displayName - a short name that describes the activity</li> <li>description - one or two sentences that
     * describe the activity in greater detail, or <code>null</code> to indicate no description</li> <li>activityInfo -
     * a reference to the activity's ActivityInfo</li> </ul>
     *
     * @param resolveInfo the package information corresponding to the activity.
     *
     * @return a map containing the activity's key-value pairs.
     */
    protected Map<String, Object> getActivityParams(ResolveInfo resolveInfo)
    {
        PackageManager pm = this.getActivity().getPackageManager();

        int iconResource = resolveInfo.getIconResource();
        CharSequence cs = resolveInfo.loadLabel(pm);
        Bundle metadata = resolveInfo.activityInfo.metaData;

        Map<String, Object> params = new HashMap<String, Object>();
        params.put("icon", iconResource);
        params.put("displayName", cs != null ? cs.toString() : resolveInfo.activityInfo.name);
        params.put("description", metadata != null ? metadata.getString("description") : null);
        params.put("activityInfo", resolveInfo.activityInfo);

        return params;
    }
}
