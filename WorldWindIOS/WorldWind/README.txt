/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.

 @version $Id:$
 */

INTRODUCTION

This is the source code for World Wind iOS. The code runs on both iPhone and iPad. To use,
open the WorldWindIOS.xcworkspace file with either XCode or AppCode. Build and run the WorldWindExamples application.

DOCUMENTATION GENERATION

The source files are set up for documentation generation by AppleDoc (http://gentlebytes.com/appledoc/). Use the
script MakeAPIDocs.sh to generate the documentation.

RELEASES

0.1 The Initial Release
-----------------------

Known Problems in This Release

- Running the Appledoc doc generation script on some systems causes the following message,
yet the documentation is correctly generated:

"Error loading /Library/ScriptingAdditions/Adobe Unit Types.osax/Contents/MacOS/Adobe Unit Types:
dlopen(/Library/ScriptingAdditions/Adobe Unit Types.osax/Contents/MacOS/Adobe Unit Types, 262): no suitable image found.
Did find: /Library/ScriptingAdditions/Adobe Unit Types.osax/Contents/MacOS/Adobe Unit Types: no matching architecture
in universal wrapper appledoc: OpenScripting.framework - scripting addition "/Library/ScriptingAdditions/Adobe Unit
Types.osax" declares no loadable handlers."