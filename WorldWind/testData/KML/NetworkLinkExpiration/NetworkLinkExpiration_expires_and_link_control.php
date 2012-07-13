<?php 
 /**
  * Copyright (C) 2012 United States Government as represented by the Administrator of the
  * National Aeronautics and Space Administration.
  * All Rights Reserved.
  */

 /**
  * NetworkLink target that includes a Cache-Control header and a NetworkLinkControl block. The NetworkLinkControl
  * should take priority.
  *
  * $Id$
  */

$expire_in = 3600; // Expire in one hour

// Set Cache-Control header to one hour, and NetworkLinkControl to 5 seconds. NetworkLinkControl should take priority.
header("Content-Type: application/vnd.google-earth.kml+xml");
header("Cache-Control: max-age=$expire_in");

// Note that NetworkLinkControl uses a different date format than HTTP header. See kml:dateTime definition in KML Spec
$expire_in = 5; // Expire in 5 seconds
$expires = gmdate("c", time() + $expire_in);
?>
<kml xmlns="http://www.opengis.net/kml/2.2">
    <NetworkLinkControl>
        <expires><?php print $expires ?></expires>
    </NetworkLinkControl>
    <Document>
        <Placemark>
            <name><?php print date("H:i:s") ?></name>
            <description>Updates every <?php print $expire_in ?> seconds using NetworkLinkControl</description>
            <Point>
                <coordinates>-79.0015,35.7124,0</coordinates>
            </Point>
        </Placemark>
    </Document>
</kml>
