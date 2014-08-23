TAIGA README file, $Id$

Acquiring and Installing the TAIGA Data
---------------------------------------

Data for TAIGA comes from many places. Some data is hosted by NASA World Wind sites. To have that data hosted elsewhere
requires the following steps:

1) Follow the instructions at the following URL to install the base imagery and elevations: http://goworldwind
.org/mapserver-and-data-installation/

2) Obtain the FAA sectional charts from here: http://worldwind.arc.nasa.gov/faachart/FAAchartreprojectcombined.zip then
follow the instructions in the "Adding Your Own Imagery" section at the bottom of the web page referred to above. The
 MapServer layer definition should be as follows:

 LAYER
   PROCESSING "RESAMPLE=BILINEAR"
   NAME "FAAchart"
   METADATA
     "wms_title"          "FAA charts"
     "wms_abstract"       "FAA charts for Alaska"
     "wms_keywordlist"    "LastUpdate= 2014-3-24T16:26:00Z"
     "wms_opaque"         "1"
   END
   TYPE RASTER
   STATUS ON
   TILEINDEX "FAAchart-index.shp"
   TILEITEM "Location"
   TYPE RASTER
   PROJECTION
     "init=epsg:4326"
   END
   OFFSITE 255 255 255
 END

 But be sure to change the LastUpdate date and time to your current time.

3) Copy the following zip flie to your host site and unzip it into your web server's data directory:
http://worldwindserver.net/taiga/AllTAIGAData.zip. The zip file's top-level directory is "taiga". The data must be
located such that URLs of the following form are accurate:
    http://your-host-name-and-data-location/taiga/dafif/ARPT2_ALASKA.TXT.

-- Modify the TAIGA_DATA_HOST constant in the source file TAIGA/AppConstants.h to reflect the value you entered as
your-host-name-and-data-location in the example URL above. Then rebuild the TAIGA app.
