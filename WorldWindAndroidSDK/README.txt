#
# Copyright (C) 2012 United States Government as represented by the Administrator of the
# National Aeronautics and Space Administration.
# All Rights Reserved.
#
# $Id$

This document provides links on getting started with the World Wind Android SDK, and provides instructions for building
and running example World Wind Android applications.


Getting Started With the World Wind Android SDK
------------------------------------------------------------

Key files and folders:
- build.xml: Apache ANT build file for the World Wind Android SDK.
- WorldWindAndroid: Contains the project for the World Wind Android library.
- WorldWindAndroidExamples: Contains the project for the World Wind Android examples.

Important World Wind sites:
- World Wind Android Website: http://goworldwind.org/android
- World Wind Android Forum: http://forum.worldwindcentral.com/forumdisplay.php?f=50
- World Wind Android API Documentation: http://builds.worldwind.arc.nasa.gov/worldwindandroid-releases/daily/docs/api/index.html


Running an Example Application on Android
------------------------------------------------------------

Setup instructions:
    1) Set up an Android development environment by following the instructions at:
       http://goworldwind.org/android/android-development-environment/
    2) Set up your device for deployment by following the instructions at:
       http://developer.android.com/guide/developing/device.html#setting-up
    3) Connect your Android device to your development machine.

Using IntelliJ IDEA:
    1) Open the WWAndroid project in IntelliJ IDEA.
    2) In the toolbar, select the WorldWindExamples run configuration.
    3) Click the run button.

From the command line:
    1) On your computer, open a terminal.
    3) cd to WorldWindAndroid/WorldWindExamples.
    4) ant installr (if the app name ends with -release.apk)
       and installd (if the app name ends with -debug.apk)
    5) On the Android device, tab the World Wind Examples app.

Note: World Wind Android has been tested on the Samsung Galaxy Tab 10.1.
