TAIGA README file, $Id$

Acquiring and Installing the TAIGA Data
---------------------------------------

Data for TAIGA comes from many places. Some data is hosted by NASA World Wind sites. To have that data hosted elsewhere
requires the following steps:

1) Follow the instructions at the following URL to install the base imagery and elevations: http://goworldwind
.org/mapserver-and-data-installation/

2) Copy the following zip flie to your host site and unzip it into your web server's data directory:
http://worldwindserver.net/taiga/AllTAIGAData.zip. The zip file's top-level directory is "taiga". The data must be
located such that URLs of the following form are accurate:
    http://your-host-name-and-data-location/taiga/dafif/ARPT2_ALASKA.TXT.

-- Modify the TAIGA_DATA_HOST constant in the source file TAIGA/AppConstants.h to reflect the value you entered as
your-host-name-and-data-location in the example URL above. Then rebuild the TAIGA app.

3) To install the FAA sectional charts, follow the following instructions after performing step 1.
-- TBD