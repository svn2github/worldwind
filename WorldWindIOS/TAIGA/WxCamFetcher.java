package gov.nasa.taiga.wxcam;

import org.jsoup.Jsoup;
import org.jsoup.nodes.*;
import org.jsoup.parser.Parser;
import org.jsoup.select.Elements;

import javax.imageio.ImageIO;
import java.awt.image.*;
import java.io.*;
import java.net.*;
import java.text.SimpleDateFormat;

public class WxCamFetcher {

	/* Set these values as desired to operate on the server. */
	public static String WXCAM_HOME_DIR = "/Users/jlrios/side_projects/TAIGA/WeatherCam/wxcams/";
	public static final String TIMEFILE_NAME = "/time.txt";
	public static final String CURR_IMAGE_NAME = "/currentimage.jpg";
	public static final String REF_IMAGE_NAME  = "/referenceimage.jpg";

	/* These are set by the AK Wx cam folks. */
	public static final String URL_SITES   = "http://avcams.faa.gov/xml/sites.php?u=nasa&p=amesavsys";
	public static final String URL_CAMERAS = "http://avcams.faa.gov/xml/cameras.php?u=nasa&p=amesavsys";
	public static final String URL_IMAGE   = "http://avcams.faa.gov/wxdata/";

	public static final String ARG_DEST = "dest";
	public static final String ARG_TYPE = "fetch";
	public static final String ARG_TYPE_REF= "reference";
	public static final String ARG_TYPE_CUR= "current";

	/* This is the date format in the cameras xml file. */
	public static final SimpleDateFormat dateFormat = new SimpleDateFormat("MMM dd yyyy k:mmaa");


	public static void main(String[] args) {

		boolean getRefImages = false;
		boolean didSetDir    = false;

		for( String arg : args ) {
			if( arg.startsWith(ARG_DEST) && arg.contains("=")) {
				WXCAM_HOME_DIR = arg.split("=")[1];
				didSetDir = true;
			}
			else if( arg.startsWith(ARG_TYPE) && arg.contains("=") ) {
				String val = arg.split("=")[1];
				if( val.matches(ARG_TYPE_REF) ) getRefImages = true;
				else if( val.matches(ARG_TYPE_CUR) ) ;
			}
			else {
				System.out.println("Unrecognized/misformatted argument: "+arg);
				printUsage();
				return;
			}
		}

		if( !didSetDir ) {
			System.out.println("Didn't set a destination directory?");
			printUsage();
			return;
		}

		if( getRefImages ) {
			getReferenceImages();
			return;
		}

		/* Grab the camera XML file.  If there seems to be a problem, bail. */
		String input = fetchFromURL(URL_CAMERAS);
		if( input == null ) {
			System.err.println("Problem fetching the camera XML file.  Exiting.");
			return;
		}

		File imageFile;
		String cameraId, lastSuccessImage, lastSuccessFilename, camInMaintenance, siteInMaintenance;

		/* Use Jsoup to parse the XML file. */
		Document doc = Jsoup.parse(input, URL_CAMERAS, Parser.xmlParser());

		/* This flag gets set depending on if we should download the image or not. */
		boolean getImage = true;

		/* Get all the 'cameras' Elements. */
		Elements cameras = doc.select("cameras");

		/* Process each Element by grabbing its ID, checking if we have the most
		 * recent image, and downloading the image if necessary.
		 */
		for( Element e : cameras ) {
			/* Grab the necessary XML elements into Strings for later use. */
			cameraId = e.select("cameraId").text();
			lastSuccessImage = e.select("cameraLastSuccess").text();
			lastSuccessFilename = e.select("lastSuccessFilename").text();
			camInMaintenance = e.select("camInMaintenance").text();
			siteInMaintenance = e.select("siteInMaintenance").text();

			/* Make sure we have a directory for this camera ID. */
			File file = new File(WXCAM_HOME_DIR+cameraId);
			file.mkdirs();

//			/* Check the timestamp of the last image we retrieved. */
//			file = new File(file.getAbsoluteFile()+TIMEFILE_NAME);
//			if( file.exists() ) {
//				/* Time noted in the TIMEFILE stored on our server. */
//				Calendar prevTime = Calendar.getInstance();
//				/* Time noted in the current XML file. */
//				Calendar currTime = Calendar.getInstance();
//				String dateText = "";
//				try {
//					dateText = new Scanner(file).useDelimiter("\\Z").next();
//					prevTime.setTime(dateFormat.parse(dateText));
//					currTime.setTime(dateFormat.parse(lastSuccessImage));
//				} catch (FileNotFoundException e1) {
//					e1.printStackTrace();
//				} catch (ParseException e2) {
//					e2.printStackTrace();
//				}
//
//				/* Check difference in times and set getImage accordingly. */
//				getImage = prevTime.before(currTime);
//
//			}
//			else {
//				/* No time file?  We should probably get an image then.  This should
//				 * only occur on the first run or if the time file gets accidently
//				 * deleted.
//				 */
//				getImage = true;
//			}

			if( getImage ) {
                System.out.println("Downloading " +
             					cameraId+" "+lastSuccessImage+" "+lastSuccessFilename+" "+camInMaintenance+" "+siteInMaintenance);
				imageFile = new File(WXCAM_HOME_DIR+cameraId+CURR_IMAGE_NAME);
				BufferedImage image = null;
				try {
					//System.out.println();
					URL url = new URL(URL_IMAGE+lastSuccessFilename);
					//System.out.println("Fetching from "+url.toString());
					image = ImageIO.read(url);

					/* If the app doesn't want jpgs, this is where we could generate another 
					 * image file format.
					 */

					/* Save as "current image. */
					ImageIO.write(image, "jpg", imageFile); 
					/* Also save for historical reasons. Note we could create a symbolic link
					 * here instead of creating two copies of the file. */
					copyFileUsingFileStreams(imageFile, new File(WXCAM_HOME_DIR+cameraId+"/"+cameraId+"_"+lastSuccessImage+".jpg"));

					/* Update the time file. */
					File dateFile = new File(WXCAM_HOME_DIR+cameraId+TIMEFILE_NAME);	 
					if (!dateFile.exists()) {
						dateFile.createNewFile();
					}
					FileWriter fw = new FileWriter(dateFile.getAbsoluteFile());
					BufferedWriter bw = new BufferedWriter(fw);
					bw.write(lastSuccessImage);
					bw.close();


				} catch (IOException ioexcpetion) {
					ioexcpetion.printStackTrace();
				}
			}
            else
            {
                System.out.println("Skipping " +
             					cameraId+" "+lastSuccessImage+" "+lastSuccessFilename+" "+camInMaintenance+" "+siteInMaintenance);
            }
//
//			System.out.println(
//					cameraId+" "+lastSuccessImage+" "+lastSuccessFilename+" "+camInMaintenance+" "+siteInMaintenance);
		}

	}

	private static void printUsage() {
		System.out.println("");
		System.out.println("+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++");
		System.out.println("Weather Cam Fetching jar");
		System.out.println("+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++");
		System.out.println("");
		System.out.println("Usage: ");
		System.out.println("  java -jar <name of this jar> [args]");
		System.out.println("");
		System.out.println("Arguments: ");
		System.out.println("");
		System.out.println("  "+ARG_DEST+"=<full path to destination directory>");
		System.out.println("       Mandatory argument. This directory will be created if it does not exist.");
		System.out.println("       If this is the same parent directory as where all of the current");
		System.out.println("       weather cam images are stored, then the reference images will live in");
		System.out.println("       those same directories with the name '"+REF_IMAGE_NAME+"'.");
		System.out.println("");
		System.out.println("  "+ARG_TYPE+"=["+ARG_TYPE_REF+"|"+ARG_TYPE_CUR+"]");
		System.out.println("       Optional argument. If omitted, '"+ARG_TYPE_CUR+"' is assumed.");
		System.out.println("");
		System.out.println("+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++");
	}

	private static void getReferenceImages() {
		/* Make sure the destination directory exists. */
//		try {
//			File dir = new File(WXCAM_HOME_DIR+ARG_TYPE_REF+"/");
//			dir.mkdirs();
//		} catch(Exception ex) {
//			ex.printStackTrace();
//			return;
//		}

		/* Get site/camera information. */
		System.out.println("Fetching camera info...");
		String input = fetchFromURL(URL_SITES);

		/* Use Jsoup to parse the XML file. */
		System.out.println("Parsing XML...");
		Document doc = Jsoup.parse(input, URL_SITES, Parser.xmlParser());

		/* Get all the 'cameras' Elements. */
		Elements cameraIDs = doc.select("cameraID");

		/* Process each Element by grabbing its ID, checking if we have the most
		 * recent image, and downloading the image if necessary.
		 */
		System.out.println("Entering for loop...");
		for( Element e : cameraIDs ) {
			String cameraId = e.select("cameraId").text();
			System.out.println(cameraId);

			URL url = null;
			try {
				url = new URL("http://avcams.faa.gov/images/clearday/"+cameraId+"-clearday.jpg");
				BufferedImage image = ImageIO.read(url);
				
				File dir = new File(WXCAM_HOME_DIR+cameraId+"/");
				dir.mkdirs();
				
				File imageFile = new File(WXCAM_HOME_DIR+cameraId+REF_IMAGE_NAME);

				/* Save as reference image. */
				ImageIO.write(image, "jpg", imageFile); 
			} catch (MalformedURLException e1) {
				e1.printStackTrace();
				System.err.println("URL:  http://avcams.faa.gov/images/clearday/"+cameraId+"-clearday.jpg");
				System.err.println("Problem with that URL?  I'm still going to try and fetch the remaining images.");
			} catch (IOException e2) {
				e2.printStackTrace();
				System.err.println("Problem writing to file.  Will try the next image.");
			}
		}
	}

	/* Utility method for pulling text-based file from URL. */
	private static String fetchFromURL(String url) {
		StringBuilder sb = new StringBuilder();

		URL site;
		try {
			site = new URL(url);
			BufferedReader in = new BufferedReader(
					new InputStreamReader(site.openStream()));

			String inputLine;
			while ((inputLine = in.readLine()) != null) {
				sb.append(inputLine);
			}
			in.close();
		} catch (MalformedURLException e) {
			e.printStackTrace();
			return null;
		} catch (IOException e) {
			e.printStackTrace();
			return null;
		}

		if( sb.length() <= 0 ) return null;
		return sb.toString();
	}

	/* Utility method for copying files. Seems inefficient. */
	private static void copyFileUsingFileStreams(File source, File dest)
	throws IOException {
		InputStream input = null;
		OutputStream output = null;
		try {
			input = new FileInputStream(source);
			output = new FileOutputStream(dest);
			byte[] buf = new byte[1024];
			int bytesRead;
			while ((bytesRead = input.read(buf)) > 0) {
				output.write(buf, 0, bytesRead);
			}
		} finally {
			input.close();
			output.close();
		}
	}
}
