/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import "MetarIconGenerator.h"
#import "WWLog.h"

#define IMAGE_SIZE (128)

// See http://aviationweather.gov/adds/metars/description/page_no/2 for METAR graphic layout
// See http://weather.aero/assets/a3e10540/docs/symbols.pdf for METAR icon mapping from WX string

@implementation MetarIconGenerator

static NSMutableDictionary* skyCoverImageNames;
static NSMutableDictionary* weatherImageNames;
static UIColor* pinkColor;

+ (void) initialize
{
    pinkColor = [UIColor colorWithRed:1.0 green:0.5 blue:1.0 alpha:1.0];

    skyCoverImageNames = [[NSMutableDictionary alloc] init];
    [skyCoverImageNames setObject:@"CC_SKC_128.png" forKey:@"SKC"];
    [skyCoverImageNames setObject:@"CC_CLR_128.png" forKey:@"CLR"];
    [skyCoverImageNames setObject:@"CC_MIS_128.png" forKey:@"CAVOK"]; // TODO: Is this the correct image?
    [skyCoverImageNames setObject:@"CC_FEW_128.png" forKey:@"FEW"];
    [skyCoverImageNames setObject:@"CC_SCT_128.png" forKey:@"SCT"];
    [skyCoverImageNames setObject:@"CC_BKN_128.png" forKey:@"BKN"];
    [skyCoverImageNames setObject:@"CC_OVC_128.png" forKey:@"OVC"];
    [skyCoverImageNames setObject:@"CC_OVX_128.png" forKey:@"OVX"];

    weatherImageNames = [[NSMutableDictionary alloc] init]; // TODO: Complete the WX icon set
    [weatherImageNames setObject:@"WX_BR_128.png" forKey:@"BR"];
    [weatherImageNames setObject:@"WX_DRDU_128.png" forKey:@"DRDU"];
    [weatherImageNames setObject:@"WX_DU_128.png" forKey:@"DU"];
    [weatherImageNames setObject:@"WX_DZ_128.png" forKey:@"DZ"];
    [weatherImageNames setObject:@"WX_DZ_MIN_128.png" forKey:@"-DZ"];
    [weatherImageNames setObject:@"WX_DZ_PLUS_128.png" forKey:@"+DZ"];
    [weatherImageNames setObject:@"WX_FG_128.png" forKey:@"FG"];
    [weatherImageNames setObject:@"WX_NONE_128.png" forKey:@"NONE"];
    [weatherImageNames setObject:@"WX_RA_128.png" forKey:@"RA"];
    [weatherImageNames setObject:@"WX_RA_MIN_128.png" forKey:@"-RA"];
    [weatherImageNames setObject:@"WX_RA_PLUS_128.png" forKey:@"+RA"];
    [weatherImageNames setObject:@"WX_SA_128.png" forKey:@"SA"];
    [weatherImageNames setObject:@"WX_SN_128.png" forKey:@"SN"];
    [weatherImageNames setObject:@"WX_SN_MIN_128.png" forKey:@"-SN"];
    [weatherImageNames setObject:@"WX_SN_PLUS_128.png" forKey:@"+SN"];
    [weatherImageNames setObject:@"WX_SS_PLUS_128.png" forKey:@"+SS"];
    [weatherImageNames setObject:@"WX_TS_128.png" forKey:@"TS"];
}

+ (NSString*) createIconFile:(NSDictionary*)metarDict
{
    NSString* fileName = [[NSProcessInfo processInfo] globallyUniqueString];
    NSString* fileDir = NSTemporaryDirectory();
    NSString* filePath = [fileDir stringByAppendingPathComponent:fileName];

    NSError* error = nil;
    [[NSFileManager defaultManager] createDirectoryAtPath:fileDir
                              withIntermediateDirectories:YES attributes:nil error:&error];
    if (error != nil)
    {
        NSDictionary* userInfo = [error userInfo];
        NSString* errMsg = [[userInfo objectForKey:NSUnderlyingErrorKey] localizedDescription];
        WWLog(@"Error %@ create METAR icon file %@", errMsg, fileDir);
        return nil;
    }

//    UIImage* image = [UIImage imageNamed:@"weather32x32.png"];
    UIImage* image = [MetarIconGenerator createCompositeImage:metarDict];
    NSData* imageData = UIImagePNGRepresentation(image);
    [imageData writeToFile:filePath atomically:YES];

    return filePath;
}

+ (UIImage*) createCompositeImage:(NSDictionary*)metarDict
{
    CGSize size = CGSizeMake(IMAGE_SIZE, IMAGE_SIZE);

    CGRect rectWeather = CGRectMake(-13, 0, size.width, size.height);
    CGRect rectBarb = CGRectMake(13, 0, size.width, size.height);
    CGRect rectAirport = CGRectMake(87, 65, size.width, size.height);
    CGRect rectAltimeter = CGRectMake(87, 45, size.width, size.height);
    CGRect rectTemp = CGRectMake(47, 25, size.width, size.height);
    CGRect rectDew = CGRectMake(47, 85, size.width, size.height);
    CGRect rectVisibility = CGRectMake(17, 57, size.width, size.height);

    UIImage* skyCoverImage = [MetarIconGenerator createSkyCoverImage:metarDict];
    UIImage* barbImage = [MetarIconGenerator createWindBarbImage:metarDict];
    UIImage* weatherImage = [MetarIconGenerator createWeatherImage:metarDict];

    UIGraphicsBeginImageContextWithOptions(size, NO, 0.0);

//    CGContextRef context = UIGraphicsGetCurrentContext();
//    UIColor* backgroundColor = [[UIColor alloc] initWithRed:0.0 green:0.0 blue:0.0 alpha:0.1];
//    CGContextSetFillColorWithColor(context, [backgroundColor CGColor]);
//    CGContextFillRect(context, (CGRect) {{0, 0}, size});

    if (skyCoverImage != nil)
    {
        [skyCoverImage drawInRect:rectBarb];
    }

    if (barbImage != nil)
    {
        [barbImage drawInRect:rectBarb blendMode:kCGBlendModeNormal alpha:1.0];
    }

    if (weatherImage != nil)
    {
        [weatherImage drawInRect:rectWeather blendMode:kCGBlendModeNormal alpha:1.0];
    }

    NSMutableDictionary* airportFontAttrs = [[NSMutableDictionary alloc] init];
    [airportFontAttrs setObject:[UIFont fontWithName:@"HelveticaNeue" size:13] forKey:NSFontAttributeName];

    NSMutableDictionary* tempFontAttrs = [[NSMutableDictionary alloc] init];
    [tempFontAttrs setObject:[UIFont fontWithName:@"HelveticaNeue" size:15] forKey:NSFontAttributeName];

    NSString* station = [metarDict objectForKey:@"station_id"];
    if (station != nil)
    {
        [airportFontAttrs setObject:[UIColor whiteColor] forKey:NSForegroundColorAttributeName];
        [station drawInRect:rectAirport withAttributes:airportFontAttrs];
    }

    NSString* altimeter = [metarDict objectForKey:@"altim_in_hg"];
    if (altimeter != nil)
    {
        [airportFontAttrs setObject:[UIColor whiteColor] forKey:NSForegroundColorAttributeName];
        [altimeter drawInRect:rectAltimeter withAttributes:airportFontAttrs];
    }

    NSString* temperature = [metarDict objectForKey:@"temp_c"];
    if (temperature != nil)
    {
        [tempFontAttrs setObject:[UIColor yellowColor] forKey:NSForegroundColorAttributeName];
        [temperature drawInRect:rectTemp withAttributes:tempFontAttrs];
    }

    NSString* dewPoint = [metarDict objectForKey:@"dewpoint_c"];
    if (dewPoint != nil)
    {
        [tempFontAttrs setObject:[UIColor greenColor] forKey:NSForegroundColorAttributeName];
        [dewPoint drawInRect:rectDew withAttributes:tempFontAttrs];
    }

    NSString* visibility = [metarDict objectForKey:@"visibility_statute_mi"];
    if (visibility != nil)
    {
        [tempFontAttrs setObject:pinkColor forKey:NSForegroundColorAttributeName];
        [visibility drawInRect:rectVisibility withAttributes:tempFontAttrs];
    }

    UIImage* image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return image;
}

+ (UIImage*) createSkyCoverImage:(NSDictionary*)metarDict
{
    NSArray* skyConditions = [metarDict objectForKey:@"sky_conditions"];
    if (skyConditions == nil || [skyConditions count] == 0)
        return nil;

    NSDictionary* conditionDict = [skyConditions objectAtIndex:0]; // TODO: What if multiple sky conditions?
    NSString* cover = [[NSString alloc] initWithString:[conditionDict objectForKey:@"sky_cover"]];
    if (cover == nil)
        return nil;

    NSString* imageFileName = [skyCoverImageNames objectForKey:cover];
    if (imageFileName == nil)
        return nil;

    UIImage* image = [UIImage imageNamed:imageFileName];

    CGSize size = CGSizeMake(IMAGE_SIZE, IMAGE_SIZE);
    CGRect rect = CGRectMake(0, 0, size.width, size.height);

    UIGraphicsBeginImageContextWithOptions(size, NO, 0.0);
    CGContextRef context = UIGraphicsGetCurrentContext();
    [image drawInRect:rect blendMode:kCGBlendModeNormal alpha:0.0];
    [[self getConditionColor:metarDict] set];
    CGContextClipToMask(context, rect, [image CGImage]);
    CGContextFillRect(context, rect);
    image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return image;
}

+ (UIImage*) createWeatherImage:(NSDictionary*)metarDict
{
    NSString* wxString = [metarDict objectForKey:@"wx_string"];
    if (wxString == nil)
        return nil;

    NSString* imageFileName = [weatherImageNames objectForKey:wxString];
    if (imageFileName == nil)
        return nil;

    UIImage* image = [UIImage imageNamed:imageFileName];

    CGSize size = CGSizeMake(IMAGE_SIZE, IMAGE_SIZE);
    CGRect rect = CGRectMake(0, 0, size.width, size.height);

    UIGraphicsBeginImageContextWithOptions(size, NO, 0.0);
    CGContextRef context = UIGraphicsGetCurrentContext();
    [image drawInRect:rect blendMode:kCGBlendModeNormal alpha:0.0];
    [[self getConditionColor:metarDict] set];
    CGContextClipToMask(context, rect, [image CGImage]);
    CGContextFillRect(context, rect);
    image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return image;
}

+ (UIColor*) getConditionColor:(NSDictionary*)metarDict
{
    NSString* flightCategory = [metarDict objectForKey:@"flight_category"];
    if (flightCategory == nil)
        return [UIColor redColor]; // TODO: Is this the correct default?

    if ([flightCategory isEqualToString:@"VFR"])
        return [UIColor blueColor];
    else if ([flightCategory isEqualToString:@"MVFR"])
        return [UIColor greenColor];
    else if ([flightCategory isEqualToString:@"IFR |"])
        return [UIColor redColor];
    else if ([flightCategory isEqualToString:@"LIFR"])
        return pinkColor;

    return [UIColor redColor]; // TODO: Is this the correct default?
}

+ (UIImage*) createWindBarbImage:(NSDictionary*)metarDict
{
    NSString* windSpeedString = [metarDict objectForKey:@"wind_speed_kt"];
    if (windSpeedString == nil)
        return nil;

    NSString* windDirectionString = [metarDict objectForKey:@"wind_dir_degrees"];
    if (windDirectionString == nil)
        return nil;

    int windSpeed = [windSpeedString integerValue];
    int windDir = [windDirectionString integerValue];

    windSpeed = (windSpeed + 4) / 5 * 5;
    // TODO: Create the full set of wind barbs and eliminate this clamping.
    if (windSpeed > 95)
        windSpeed = 95;
    if (windSpeed < 5)
        windSpeed = 5;

    NSString* windBarbIconName = [[NSString alloc] initWithFormat:@"WB_%dkt_128.png", windSpeed];
    UIImage* barbImage = [UIImage imageNamed:windBarbIconName];

    CGSize size = CGSizeMake(IMAGE_SIZE, IMAGE_SIZE);
    CGRect rect = CGRectMake(0, 0, size.width, size.height);

    UIGraphicsBeginImageContextWithOptions(size, NO, 0.0);
    [barbImage drawInRect:rect blendMode:kCGBlendModeNormal alpha:1.0];
    barbImage = [MetarIconGenerator rotateImage:barbImage angle:windDir];
    UIGraphicsEndImageContext();

    return barbImage;
}

+ (UIImage*) rotateImage:(UIImage*)uiImage angle:(float)angle
{
    UIView* rotatedView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, uiImage.size.width, uiImage.size.height)];
    rotatedView.transform = CGAffineTransformMakeRotation((CGFloat) (angle * (M_PI / 180)));
    CGSize rotatedSize = rotatedView.frame.size;

    // Create context
    UIGraphicsBeginImageContext(rotatedSize);
    CGContextRef context = UIGraphicsGetCurrentContext();

    // Center the origin
    CGContextTranslateCTM(context, rotatedSize.width / 2, rotatedSize.height / 2);

    // Rotate
    CGContextRotateCTM(context, (CGFloat) (angle * (M_PI / 180)));

    // Draw into the context
    CGContextScaleCTM(context, 1.0, -1.0);
    CGContextDrawImage(context, CGRectMake(-uiImage.size.width / 2, -uiImage.size.height / 2,
            uiImage.size.width, uiImage.size.height), [uiImage CGImage]);

    return UIGraphicsGetImageFromCurrentImageContext();
}

@end