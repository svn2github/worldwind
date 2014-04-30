$Id$

This file explains the organization of the World Wind Subversion repository's directories, and briefly outlines their contents.

WorldWind
The 'WorldWind' folder contains the World Wind Java SDK project. Many resources are available at http://goworldwind.org to help you understand and use World Wind. Key files and folders in the World Wind Java SDK:
- src: Contains all Java source files for the World Wind Java SDK.
- build.xml: Apache ANT build file for the World Wind Java SDK.
- lib-external/gdal: Contains the GDAL native binary libraries that may optionally be distributed with World Wind.

WorldWindIOS
The 'WorldWindIOS' folder contains the World Wind iOS SDK project. Many resource are available at http://goworldwind.org/world-wind-ios to help you understand and use World Wind on iOS. Key files and folders in the World Wind iOS SDK:
- WorldWind/WorldWind: Contains all Objective-C source files for the World Wind iOS SDK.
- WorldWind/WorldWind.xcodeproj: Xcode project file for the World Wind iOS SDK.
- HelloWorldWind: Universal iOS app demonstrating basic usage of the World Wind iOS SDK.
- TAIGA: iPad app for the NASA TAIGA project.  

WWAndroid
the 'WWAndroid' folder contains the World Wind Android SDK project. Many resource are available at http://goworldwind.org/android to help you understand and use World Wind on Android. Key files and folders in the World Wind Android SDK:
- src: Contains all Java source files for the World Wind Android SDK.
- build.xml: Apache ANT build file for the World Wind Android SDK.
- examples: Example Android apps that use the World Wind Android SDK.


GDAL
The 'GDAL' folder contains the GDAL native library project. This project produces the GDAL native libraries used by the World Wind Java SDK (see WorldWind/lib-external/gdal). The GDAL native library project contains detailed instructions for building the GDAL native libraries on the three supported platforms: Linux, Mac OS X, and Windows.
